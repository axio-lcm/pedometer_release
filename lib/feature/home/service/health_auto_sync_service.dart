import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:health/health.dart';

import 'package:pedometer/common/config/localized_text.dart';
import 'package:pedometer/feature/home/model/health_data_store.dart';
import 'package:pedometer/feature/home/model/health_repository.dart';
import 'package:pedometer/feature/home/model/health_sync_models.dart';

/// 会员健康数据自动同步协调器。
///
/// 用于订阅成功后、会员进入首页后自动申请 Health 权限并同步数据。
/// iOS 无法可靠查询 HealthKit 读权限，项目约定为：能读到有效数据即视为已授权；
/// 未读到数据则不记授权，下一次触发时继续请求授权并尝试同步。
class HealthAutoSyncService extends GetxService {
  HealthAutoSyncService({HealthPluginSyncService? syncService})
    : _syncService = syncService ?? HealthPluginSyncService();

  static const _syncTypes = [
    HealthSyncDataType.steps,
    HealthSyncDataType.distance,
    HealthSyncDataType.calories,
    HealthSyncDataType.activeMinutes,
  ];

  /// 尽量覆盖用户历史健康数据，而不只同步最近几天。
  static final DateTime _historyStartDate = DateTime(2014, 1, 1);

  final HealthPluginSyncService _syncService;
  Future<bool>? _running;
  int _syncToken = 0;

  Future<bool> syncMemberHealthData() {
    final running = _running;
    if (running != null) return running;

    final task = _syncMemberHealthData().whenComplete(() => _running = null);
    _running = task;
    return task;
  }

  Future<bool> _syncMemberHealthData() async {
    final source = _preferredSource;
    if (source == null) return false;

    try {
      final available = await _syncService.isAvailable(source: source);
      if (!available) {
        HealthSyncRuntime.setConnectionStatus(
          source,
          HealthAuthStatus.unavailable,
        );
        return false;
      }

      final authorized = await _syncService.requestAuthorization(
        source: source,
        types: _syncTypes,
      );
      if (!authorized) {
        HealthSyncRuntime.setConnectionStatus(source, HealthAuthStatus.denied);
        return false;
      }

      final now = DateTime.now();
      final token = ++_syncToken;
      final stopwatch = Stopwatch()..start();
      final result = await _syncService
          .sync(
            source: source,
            startDate: _historyStartDate,
            endDate: now,
            types: _syncTypes,
            ensureAuthorized: false,
          )
          .timeout(const Duration(minutes: 2));

      if (!result.source.hasData) {
        HealthSyncRuntime.setConnectionStatus(source, HealthAuthStatus.denied);
        return false;
      }

      HealthSyncRuntime.setConnectionStatus(
        source,
        HealthAuthStatus.authorized,
      );
      HealthSyncRuntime.replaceRealDataSource(result.source);
      await HealthDataStore.instance.upsertSummaries(result.source.summaries);
      await HealthDataStore.instance.setLastSyncTime(now);
      stopwatch.stop();
      await _recordHistory(
        source: source,
        itemCount: _syncTypes.length,
        elapsed: stopwatch.elapsed,
      );

      _refineStepDetailsInBackground(
        points: result.points,
        source: source,
        startDate: _historyStartDate,
        endDate: now,
        token: token,
      );
      return true;
    } on TimeoutException {
      HealthSyncRuntime.setConnectionStatus(source, HealthAuthStatus.unknown);
      return false;
    } catch (error, stackTrace) {
      debugPrint('[HealthAutoSyncService] sync failed: $error\n$stackTrace');
      HealthSyncRuntime.setConnectionStatus(source, HealthAuthStatus.unknown);
      return false;
    }
  }

  HealthSyncSource? get _preferredSource {
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => HealthSyncSource.appleHealth,
      TargetPlatform.android => HealthSyncSource.healthConnect,
      _ => null,
    };
  }

  Future<void> _recordHistory({
    required HealthSyncSource source,
    required int itemCount,
    required Duration elapsed,
  }) async {
    final now = DateTime.now();
    final snapshot =
        HealthSyncRuntime.latestSummary ??
        HealthDailySummary(
          date: now,
          steps: 0,
          distanceKm: 0,
          caloriesKcal: 0,
          activeMinutes: 0,
          source: source,
        );
    final entry = SyncHistoryEntry(
      id: '${source.name}-${now.microsecondsSinceEpoch}',
      time: now,
      source: source,
      mode: lt('Auto Sync', '自动同步'),
      itemCount: itemCount,
      snapshot: snapshot,
      elapsed: elapsed,
    );
    HealthSyncHistory.record(entry);
    await HealthDataStore.instance.recordSyncHistory(entry);
  }

  void _refineStepDetailsInBackground({
    required List<HealthDataPoint> points,
    required HealthSyncSource source,
    required DateTime startDate,
    required DateTime endDate,
    required int token,
  }) {
    unawaited(() async {
      try {
        final refined = await _syncService.refineStepDetails(
          points: points,
          source: source,
          startDate: startDate,
          endDate: endDate,
        );
        if (token != _syncToken || !refined.hasData) return;
        HealthSyncRuntime.replaceRealDataSource(refined);
        await HealthDataStore.instance.upsertSummaries(refined.summaries);
      } catch (_) {
        // 后台精修失败不影响已展示的快速同步结果。
      }
    }());
  }
}
