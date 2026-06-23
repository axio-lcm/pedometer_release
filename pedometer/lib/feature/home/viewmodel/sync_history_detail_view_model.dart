import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_icon_source.dart';
import 'package:pedometer/common/config/app_metric_assets.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/feature/home/model/health_repository.dart';
import 'package:pedometer/feature/home/model/health_sync_models.dart';
import 'package:pedometer/feature/home/model/sync_data_detail_model.dart';

/// 单条同步历史详情页 view model。
class SyncHistoryDetailViewModel extends GetxController
    implements IBaseViewModel {
  SyncHistoryDetailViewModel() : data = _emptyData().obs;

  final Rx<SyncHistoryDetailData> data;

  @override
  void onInit() {
    super.onInit();
    HealthSyncRuntime.revision.addListener(_load);
    init();
  }

  @override
  void init() {
    _load();
  }

  @override
  void unInit() {
    HealthSyncRuntime.revision.removeListener(_load);
  }

  @override
  void onClose() {
    unInit();
    super.onClose();
  }

  void _load() {
    final argument = Get.arguments;
    final record = argument is SyncHistoryRecord ? argument : null;
    final summary = HealthSyncRuntime.latestSummary;
    if (summary == null || summary.source == HealthSyncSource.motionSensor) {
      data.value = _emptyData();
      return;
    }

    final syncedItems = _dataTypesFor(summary);
    final sourceTitle = _sourceTitle(summary.source);
    final timeText = record?.time ?? _timeText(DateTime.now());
    final modeText = record?.mode ?? sourceTitle;
    final resultText = record?.result ?? '同步 ${syncedItems.length} 项数据';
    data.value = SyncHistoryDetailData(
      statusTitle: '同步成功',
      time: timeText,
      mode: modeText,
      result: resultText,
      syncedItems: syncedItems,
      sources: [_sourceFor(summary.source)],
      methodItems: [
        SyncInfoItem(title: '同步方式', value: modeText),
        SyncInfoItem(title: '数据项', value: '${syncedItems.length} 项'),
        const SyncInfoItem(title: '耗时', value: '--'),
      ],
      infoItems: [
        SyncInfoItem(
          icon: Icons.sell_outlined,
          title: '同步编号',
          value: _syncId(summary.date),
        ),
        const SyncInfoItem(
          icon: Icons.phone_iphone_rounded,
          title: '发起设备',
          value: '本机',
        ),
        const SyncInfoItem(
          icon: Icons.verified_user_outlined,
          title: '记录状态',
          value: '成功',
          highlight: true,
        ),
      ],
      safetyText: '您的健康与运动数据仅在授权后读取，并用于本机运动统计展示。',
    );
  }

  static SyncHistoryDetailData _emptyData() {
    return const SyncHistoryDetailData(
      statusTitle: '暂无同步记录',
      time: '暂无',
      mode: '暂无',
      result: '暂无同步数据',
      syncedItems: [],
      sources: [],
      methodItems: [],
      infoItems: [],
      safetyText: '完成同步后会在这里展示本次同步详情。',
    );
  }

  static SyncDataSource _sourceFor(HealthSyncSource source) {
    return switch (source) {
      HealthSyncSource.appleHealth => const SyncDataSource(
        title: 'Apple Health',
        status: '已连接',
        icon: Icons.favorite_rounded,
        iconColor: Color(0xFFFF2D55),
      ),
      HealthSyncSource.healthConnect => const SyncDataSource(
        title: 'Health Connect',
        status: '已连接',
        icon: Icons.link_rounded,
        iconColor: Color(0xFF3D7CFF),
      ),
      HealthSyncSource.motionSensor => const SyncDataSource(
        title: '运动与健身',
        status: '已更新',
        icon: Icons.directions_walk_rounded,
        iconColor: Color(0xFF24F04E),
      ),
    };
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

  static String _sourceTitle(HealthSyncSource source) {
    return switch (source) {
      HealthSyncSource.appleHealth => 'Apple Health',
      HealthSyncSource.healthConnect => 'Health Connect',
      HealthSyncSource.motionSensor => '运动与健身',
    };
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

  static String _syncId(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return 'SYNC-$y$m$d';
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
