import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_icon_source.dart';
import 'package:pedometer/common/config/app_metric_assets.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/feature/home/model/health_repository.dart';
import 'package:pedometer/feature/home/model/health_sync_models.dart';
import 'package:pedometer/feature/home/model/health_sync_source_policy.dart';
import 'package:pedometer/feature/home/model/sync_data_detail_model.dart';
import 'package:pedometer/feature/home/views/sync_history_detail_page.dart';
import 'package:pedometer/feature/home/views/sync_history_list_page.dart';
import 'package:pedometer/feature/home/views/sync_source_detail_page.dart';

/// Health 同步数据详情页 view model。
class SyncDataDetailViewModel extends GetxController implements IBaseViewModel {
  SyncDataDetailViewModel({TargetPlatform? platform})
    : platform = platform ?? defaultTargetPlatform,
      data = _emptyData().obs;

  final TargetPlatform platform;
  final Rx<SyncDataDetailData> data;

  /// 连接状态变更计数，用于驱动 [platformSources] 在保存设置后刷新展示。
  final _connectionRevision = 0.obs;

  List<SyncDataSource> get platformSources {
    // 读取以建立 Obx 依赖：连接状态变化时重新计算来源状态文案。
    _connectionRevision.value;
    final allowedTitles = HealthSyncSourcePolicy.sourcesFor(
      platform,
    ).map(HealthSyncSourcePolicy.titleFor).toSet();
    final filtered = data.value.sources
        .where((source) => allowedTitles.contains(source.title))
        .toList();
    final list = filtered.isEmpty ? data.value.sources : filtered;
    return [
      for (final source in list) source.copyWith(status: _statusFor(source)),
    ];
  }

  String _statusFor(SyncDataSource source) {
    final healthSource = HealthSyncSourcePolicy.sourceForTitle(source.title);
    if (healthSource == null) return source.status;
    return switch (HealthSyncRuntime.connectionStatusOf(healthSource)) {
      HealthAuthStatus.authorized => '已连接',
      HealthAuthStatus.denied => '未连接',
      HealthAuthStatus.unavailable => '设备不可用',
      HealthAuthStatus.unsupported => '不支持',
      HealthAuthStatus.unknown => '未连接',
    };
  }

  @override
  void onInit() {
    super.onInit();
    HealthSyncRuntime.revision.addListener(_onRuntimeDataChanged);
    HealthSyncRuntime.connectionRevision.addListener(_onConnectionChanged);
    HealthSyncHistory.revision.addListener(_onRuntimeDataChanged);
    init();
  }

  void _onRuntimeDataChanged() {
    data.value = _runtimeData();
  }

  void _onConnectionChanged() {
    _connectionRevision.value++;
    data.value = _runtimeData();
  }

  @override
  void init() {
    data.value = _runtimeData();
  }

  @override
  void unInit() {
    HealthSyncRuntime.revision.removeListener(_onRuntimeDataChanged);
    HealthSyncRuntime.connectionRevision.removeListener(_onConnectionChanged);
    HealthSyncHistory.revision.removeListener(_onRuntimeDataChanged);
  }

  @override
  void onClose() {
    unInit();
    super.onClose();
  }

  void openSource(SyncDataSource source) {
    Get.toNamed(SyncSourceDetailPage.routeName, arguments: source);
  }

  void openHistory(SyncHistoryRecord record) {
    Get.toNamed(SyncHistoryDetailPage.routeName, arguments: record);
  }

  void openAllHistory() {
    Get.toNamed(SyncHistoryListPage.routeName);
  }

  SyncDataDetailData _runtimeData() {
    final summary = HealthSyncRuntime.latestSummary;
    if (summary == null) return _emptyData();

    final updatedAt = DateTime.now();
    final recent7Summary = _recent7DaySummary(
      HealthSyncRuntime.activeSummaries,
      fallbackSource: summary.source,
    );
    final dataTypes = _dataTypesFor(recent7Summary);
    return SyncDataDetailData(
      statusTitle: summary.source == HealthSyncSource.motionSensor
          ? '运动数据已更新'
          : '同步成功',
      lastSyncText: '更新时间：${_timeText(updatedAt)}',
      sources: _sourcesForPlatform(),
      overviewMetrics: [
        SyncMetric(value: _formatInt(recent7Summary.steps), label: '近7天步数'),
        SyncMetric(
          value: _formatInt(recent7Summary.caloriesKcal.round()),
          label: '近7天卡路里（kcal）',
        ),
        SyncMetric(
          value: _formatInt(recent7Summary.activeMinutes),
          label: '近7天活动时间（min）',
        ),
      ],
      dataTypes: dataTypes,
      histories: _historyRecords(limit: 3),
      safetyText: '您的健康与运动数据仅在授权后读取，并用于本机运动统计展示。',
    );
  }

  static SyncDataDetailData _emptyData() {
    return SyncDataDetailData(
      statusTitle: '暂无同步数据',
      lastSyncText: '最后同步：暂无',
      sources: _baseSourcesFor(defaultTargetPlatform),
      overviewMetrics: const [
        SyncMetric(value: '0', label: '近7天步数'),
        SyncMetric(value: '0', label: '近7天卡路里（kcal）'),
        SyncMetric(value: '0', label: '近7天活动时间（min）'),
      ],
      dataTypes: _dataTypesFor(
        HealthDailySummary(
          date: DateTime(1970),
          steps: 0,
          distanceKm: 0,
          caloriesKcal: 0,
          activeMinutes: 0,
          source: HealthSyncSource.appleHealth,
        ),
      ),
      histories: _historyRecords(limit: 3),
      safetyText: '授权后会在这里展示你的健康与运动数据。',
    );
  }

  static List<SyncDataSource> _baseSourcesFor(TargetPlatform platform) {
    return [
      for (final source in HealthSyncSourcePolicy.sourcesFor(platform))
        SyncDataSource(
          title: HealthSyncSourcePolicy.titleFor(source),
          status: '未连接',
          icon: source == HealthSyncSource.appleHealth
              ? Icons.favorite_rounded
              : Icons.link_rounded,
          iconColor: source == HealthSyncSource.appleHealth
              ? const Color(0xFFFF2D55)
              : const Color(0xFF3D7CFF),
        ),
    ];
  }

  static HealthDailySummary _recent7DaySummary(
    List<HealthDailySummary> summaries, {
    required HealthSyncSource fallbackSource,
  }) {
    final today = _dateOnly(DateTime.now());
    final start = today.subtract(const Duration(days: 6));
    var steps = 0;
    var distanceKm = 0.0;
    var caloriesKcal = 0.0;
    var activeMinutes = 0;

    for (final summary in summaries) {
      final date = _dateOnly(summary.date);
      if (date.isBefore(start) || date.isAfter(today)) continue;
      steps += summary.steps;
      distanceKm += summary.distanceKm;
      caloriesKcal += summary.caloriesKcal;
      activeMinutes += summary.activeMinutes;
    }

    return HealthDailySummary(
      date: today,
      steps: steps,
      distanceKm: distanceKm,
      caloriesKcal: caloriesKcal,
      activeMinutes: activeMinutes,
      source: fallbackSource,
    );
  }

  List<SyncDataSource> _sourcesForPlatform() {
    return [
      for (final source in _baseSourcesFor(platform))
        source.copyWith(status: _statusFor(source)),
    ];
  }

  static List<SyncDataType> _dataTypesFor(HealthDailySummary summary) {
    return [
      SyncDataType(
        icon: const MaterialAppIcon(Icons.directions_walk_rounded),
        iconColor: const Color(0xFF24F04E),
        title: '步数',
        value: '${_formatInt(summary.steps)} 步',
      ),
      SyncDataType(
        icon: const AssetAppIcon(AppMetricAssets.calories),
        iconColor: const Color(0xFFFF9F12),
        title: '卡路里',
        value: '${_formatInt(summary.caloriesKcal.round())} kcal',
      ),
      SyncDataType(
        icon: const AssetAppIcon(AppMetricAssets.activeTime),
        iconColor: const Color(0xFF0CD9FF),
        title: '活动时间',
        value: '${_formatInt(summary.activeMinutes)} min',
      ),
      SyncDataType(
        icon: const AssetAppIcon(AppMetricAssets.distance),
        iconColor: const Color(0xFF43F56B),
        title: '距离',
        value: '${_formatDistance(summary.distanceKm)} km',
      ),
    ];
  }

  /// 从同步历史存储取记录并转为展示模型；[limit] 限制条数（null 为全部）。
  static List<SyncHistoryRecord> _historyRecords({int? limit}) {
    final entries = HealthSyncHistory.entries;
    final list = limit == null ? entries : entries.take(limit).toList();
    return [
      for (final entry in list)
        SyncHistoryRecord(
          id: entry.id,
          time: _timeText(entry.time),
          mode: entry.mode,
          result: '同步 ${entry.itemCount} 项数据',
        ),
    ];
  }

  static String _timeText(DateTime date) {
    final now = DateTime.now();
    final prefix =
        date.year == now.year && date.month == now.month && date.day == now.day
        ? '今天'
        : '${date.month}/${date.day}';
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$prefix $hour:$minute';
  }

  static String _formatDistance(double value) {
    final text = value.toStringAsFixed(2);
    if (text.endsWith('00')) return value.toStringAsFixed(0);
    if (text.endsWith('0')) return value.toStringAsFixed(1);
    return text;
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
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
