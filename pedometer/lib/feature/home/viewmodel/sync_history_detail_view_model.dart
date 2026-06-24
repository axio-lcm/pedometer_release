import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_icon_source.dart';
import 'package:pedometer/common/config/localized_text.dart';
import 'package:pedometer/common/config/app_metric_assets.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/common/storage/language_service.dart';
import 'package:pedometer/feature/home/model/health_repository.dart';
import 'package:pedometer/feature/home/model/health_sync_models.dart';
import 'package:pedometer/feature/home/model/sync_data_detail_model.dart';

/// 单条同步历史详情页 view model。
class SyncHistoryDetailViewModel extends GetxController
    implements IBaseViewModel {
  SyncHistoryDetailViewModel() : data = _emptyData().obs;

  final Rx<SyncHistoryDetailData> data;
  Worker? _languageWorker;

  @override
  void onInit() {
    super.onInit();
    HealthSyncRuntime.revision.addListener(_load);
    if (Get.isRegistered<LanguageService>()) {
      _languageWorker = ever<int>(
        Get.find<LanguageService>().localeRevision,
        (_) => _load(),
      );
    }
    init();
  }

  @override
  void init() {
    _load();
  }

  @override
  void unInit() {
    HealthSyncRuntime.revision.removeListener(_load);
    _languageWorker?.dispose();
  }

  @override
  void onClose() {
    unInit();
    super.onClose();
  }

  void _load() {
    final argument = Get.arguments;
    final record = argument is SyncHistoryRecord ? argument : null;
    final entry = record?.id == null
        ? null
        : HealthSyncHistory.entryById(record!.id!);
    if (entry == null) {
      data.value = _emptyData();
      return;
    }

    // 用本条记录自己的数据快照渲染，而非永远展示最新一天的数据。
    final summary = entry.snapshot;
    final syncedItems = _dataTypesFor(summary);
    data.value = SyncHistoryDetailData(
      statusTitle: lt('Sync Successful', '同步成功'),
      time: _timeText(entry.time),
      mode: _localizedMode(entry.mode),
      result: lt(
        'Synced ${entry.itemCount} items',
        '同步 ${entry.itemCount} 项数据',
      ),
      syncedItems: syncedItems,
      sources: [_sourceFor(entry.source)],
      methodItems: [
        SyncInfoItem(
          title: lt('Sync Mode', '同步方式'),
          value: _localizedMode(entry.mode),
        ),
        SyncInfoItem(
          title: lt('Data Items', '数据项'),
          value: lt('${entry.itemCount} items', '${entry.itemCount} 项'),
        ),
        SyncInfoItem(
          title: lt('Elapsed', '耗时'),
          value: _elapsedText(entry.elapsed),
        ),
      ],
      infoItems: [
        SyncInfoItem(
          icon: const AssetAppIcon(AppMetricAssets.syncId),
          title: lt('Sync ID', '同步编号'),
          value: _syncId(entry.time),
        ),
        SyncInfoItem(
          icon: const AssetAppIcon(AppMetricAssets.syncDevice),
          title: lt('Device', '发起设备'),
          value: lt('This device', '本机'),
        ),
        SyncInfoItem(
          icon: const AssetAppIcon(AppMetricAssets.syncStatus),
          title: lt('Status', '记录状态'),
          value: lt('Success', '成功'),
          highlight: true,
        ),
      ],
      safetyText: lt(
        'Your health and activity data is read only after authorization and used for local stats.',
        '您的健康与运动数据仅在授权后读取，并用于本机运动统计展示。',
      ),
    );
  }

  static SyncHistoryDetailData _emptyData() {
    return SyncHistoryDetailData(
      statusTitle: lt('No Sync Record', '暂无同步记录'),
      time: lt('None', '暂无'),
      mode: lt('None', '暂无'),
      result: lt('No sync data', '暂无同步数据'),
      syncedItems: const [],
      sources: const [],
      methodItems: const [],
      infoItems: const [],
      safetyText: lt(
        'Sync details will appear here after a sync is completed.',
        '完成同步后会在这里展示本次同步详情。',
      ),
    );
  }

  static SyncDataSource _sourceFor(HealthSyncSource source) {
    return switch (source) {
      HealthSyncSource.appleHealth => SyncDataSource(
        title: 'Apple Health',
        status: lt('Connected', '已连接'),
        icon: Icons.favorite_rounded,
        iconColor: const Color(0xFFFF2D55),
      ),
      HealthSyncSource.healthConnect => SyncDataSource(
        title: 'Health Connect',
        status: lt('Connected', '已连接'),
        icon: Icons.link_rounded,
        iconColor: const Color(0xFF3D7CFF),
      ),
      HealthSyncSource.motionSensor => SyncDataSource(
        title: lt('Motion & Fitness', '运动与健身'),
        status: lt('Updated', '已更新'),
        icon: Icons.directions_walk_rounded,
        iconColor: const Color(0xFF24F04E),
      ),
    };
  }

  static List<SyncDataType> _dataTypesFor(HealthDailySummary summary) {
    return [
      SyncDataType(
        icon: const MaterialAppIcon(Icons.directions_walk_rounded),
        iconColor: const Color(0xFF24F04E),
        title: lt('Steps', '步数'),
        value: lt(
          '${_formatInt(summary.steps)} steps',
          '${_formatInt(summary.steps)} 步',
        ),
      ),
      SyncDataType(
        icon: const AssetAppIcon(AppMetricAssets.calories),
        iconColor: const Color(0xFFFF9F12),
        title: lt('Calories', '卡路里'),
        value: '${_formatInt(summary.caloriesKcal.round())} kcal',
      ),
      SyncDataType(
        icon: const AssetAppIcon(AppMetricAssets.activeTime),
        iconColor: const Color(0xFF0CD9FF),
        title: lt('Active Time', '活动时间'),
        value: '${_formatInt(summary.activeMinutes)} min',
      ),
      SyncDataType(
        icon: const AssetAppIcon(AppMetricAssets.distance),
        iconColor: const Color(0xFF43F56B),
        title: lt('Distance', '距离'),
        value: '${_formatDistance(summary.distanceKm)} km',
      ),
    ];
  }

  static String _elapsedText(Duration elapsed) {
    final seconds = elapsed.inMilliseconds / 1000;
    return '${seconds.toStringAsFixed(1)} s';
  }

  static String _timeText(DateTime date) {
    final now = DateTime.now();
    final prefix =
        date.year == now.year && date.month == now.month && date.day == now.day
        ? lt('Today', '今天')
        : '${date.month}/${date.day}';
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$prefix $hour:$minute';
  }

  static String _localizedMode(String mode) {
    if (mode == '手动同步' || mode == 'Manual Sync') {
      return lt('Manual Sync', '手动同步');
    }
    if (mode == '自动同步' || mode == 'Auto Sync') {
      return lt('Auto Sync', '自动同步');
    }
    return mode;
  }

  static String _syncId(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return 'SYNC-$y$m$d-$hh$mm';
  }

  static String _formatDistance(double value) {
    final text = value.toStringAsFixed(2);
    if (text.endsWith('00')) return value.toStringAsFixed(0);
    if (text.endsWith('0')) return value.toStringAsFixed(1);
    return text;
  }

  static String _formatInt(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final remaining = text.length - i;
      buffer.write(text[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }
}
