import 'package:flutter/material.dart';
import 'package:pedometer/common/config/app_icon_source.dart';
import 'package:pedometer/common/config/localized_text.dart';
import 'package:pedometer/common/config/app_metric_assets.dart';
import 'package:pedometer/feature/home/model/health_sync_models.dart';

/// Health 同步详情页本地展示数据。
class SyncDataDetailData {
  final String statusTitle;
  final String lastSyncText;
  final List<SyncDataSource> sources;
  final List<SyncMetric> overviewMetrics;
  final List<SyncDataType> dataTypes;
  final List<SyncHistoryRecord> histories;
  final String safetyText;

  const SyncDataDetailData({
    required this.statusTitle,
    required this.lastSyncText,
    required this.sources,
    required this.overviewMetrics,
    required this.dataTypes,
    required this.histories,
    required this.safetyText,
  });

  static SyncDataDetailData get mock => SyncDataDetailData(
    statusTitle: lt('Sync Successful', '同步成功'),
    lastSyncText: lt('Last sync: Today 09:41', '最后同步：今天 09:41'),
    sources: [
      SyncDataSource(
        title: 'Apple Health',
        status: lt('Connected', '已连接'),
        icon: Icons.favorite_rounded,
        iconColor: const Color(0xFFFF2D55),
      ),
      SyncDataSource(
        title: 'Health Connect',
        status: lt('Connected', '已连接'),
        icon: Icons.link_rounded,
        iconColor: const Color(0xFF3D7CFF),
      ),
    ],
    overviewMetrics: [
      SyncMetric(value: '12,856', label: lt('Total Steps', '总步数')),
      SyncMetric(
        value: '1,256',
        label: lt('Total Calories (kcal)', '总卡路里（kcal）'),
      ),
      SyncMetric(value: '98', label: lt('Total Time (min)', '总时间（min）')),
    ],
    dataTypes: [
      SyncDataType(
        icon: const MaterialAppIcon(Icons.directions_walk_rounded),
        iconColor: const Color(0xFF24F04E),
        title: lt('Steps', '步数'),
        value: lt('12,856 steps', '12,856 步'),
      ),
      SyncDataType(
        icon: const AssetAppIcon(AppMetricAssets.calories),
        iconColor: const Color(0xFFFF9F12),
        title: lt('Calories', '卡路里'),
        value: '1,256 kcal',
      ),
      SyncDataType(
        icon: const AssetAppIcon(AppMetricAssets.activeTime),
        iconColor: const Color(0xFF0CD9FF),
        title: lt('Time', '时间'),
        value: '98 min',
      ),
      SyncDataType(
        icon: const AssetAppIcon(AppMetricAssets.distance),
        iconColor: const Color(0xFF43F56B),
        title: lt('Distance', '距离'),
        value: '8.34 km',
      ),
    ],
    histories: [
      SyncHistoryRecord(
        time: lt('Today 09:41', '今天 09:41'),
        mode: lt('Manual Sync', '手动同步'),
        result: lt('Synced 4 items', '成功同步 4 项数据'),
      ),
      SyncHistoryRecord(
        time: lt('Yesterday 20:30', '昨天 20:30'),
        mode: lt('Auto Sync', '自动同步'),
        result: lt('Synced 4 items', '成功同步 4 项数据'),
      ),
      SyncHistoryRecord(
        time: '05/13 08:15',
        mode: lt('Auto Sync', '自动同步'),
        result: lt('Synced 4 items', '成功同步 4 项数据'),
      ),
    ],
    safetyText: lt(
      'Your data is protected and all synced data is encrypted in transit.',
      '您的数据安全受保护，所有数据均已加密传输。',
    ),
  );
}

class SyncDataSource {
  final String title;
  final String status;
  final IconData icon;
  final Color iconColor;

  const SyncDataSource({
    required this.title,
    required this.status,
    required this.icon,
    required this.iconColor,
  });

  SyncDataSource copyWith({String? status}) {
    return SyncDataSource(
      title: title,
      status: status ?? this.status,
      icon: icon,
      iconColor: iconColor,
    );
  }
}

class SyncMetric {
  final String value;
  final String label;

  const SyncMetric({required this.value, required this.label});
}

class SyncDataType {
  final AppIconSource icon;
  final Color iconColor;
  final String title;
  final String value;

  const SyncDataType({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });
}

class SyncHistoryRecord {
  /// 对应 [SyncHistoryEntry.id]，供详情页回查本条记录的数据快照；mock 数据可为空。
  final String? id;
  final String time;
  final String mode;
  final String result;

  const SyncHistoryRecord({
    this.id,
    required this.time,
    required this.mode,
    required this.result,
  });
}

/// 同步历史「查看全部」列表页展示数据。
class SyncHistoryListData {
  final List<SyncHistoryRecord> records;

  const SyncHistoryListData({required this.records});

  static SyncHistoryListData get mock => SyncHistoryListData(
    records: [
      SyncHistoryRecord(
        time: lt('Today 09:41', '今天 09:41'),
        mode: lt('Manual Sync', '手动同步'),
        result: lt('Synced 4 items', '成功同步 4 项数据'),
      ),
      SyncHistoryRecord(
        time: lt('Yesterday 20:30', '昨天 20:30'),
        mode: lt('Auto Sync', '自动同步'),
        result: lt('Synced 4 items', '成功同步 4 项数据'),
      ),
      SyncHistoryRecord(
        time: lt('Yesterday 08:05', '昨天 08:05'),
        mode: lt('Auto Sync', '自动同步'),
        result: lt('Synced 4 items', '成功同步 4 项数据'),
      ),
      SyncHistoryRecord(
        time: '05/13 08:15',
        mode: lt('Auto Sync', '自动同步'),
        result: lt('Synced 4 items', '成功同步 4 项数据'),
      ),
      SyncHistoryRecord(
        time: '05/12 21:48',
        mode: lt('Manual Sync', '手动同步'),
        result: lt('Synced 3 items', '成功同步 3 项数据'),
      ),
      SyncHistoryRecord(
        time: '05/12 07:30',
        mode: lt('Auto Sync', '自动同步'),
        result: lt('Synced 4 items', '成功同步 4 项数据'),
      ),
      SyncHistoryRecord(
        time: '05/11 19:02',
        mode: lt('Auto Sync', '自动同步'),
        result: lt('Synced 4 items', '成功同步 4 项数据'),
      ),
      SyncHistoryRecord(
        time: '05/11 08:20',
        mode: lt('Manual Sync', '手动同步'),
        result: lt('Synced 4 items', '成功同步 4 项数据'),
      ),
    ],
  );
}

/// 单次同步历史详情页展示数据。
class SyncHistoryDetailData {
  final String statusTitle;
  final String time;
  final String mode;
  final String result;
  final List<SyncDataType> syncedItems;
  final List<SyncDataSource> sources;
  final List<SyncInfoItem> methodItems;
  final List<SyncInfoItem> infoItems;
  final String safetyText;

  const SyncHistoryDetailData({
    required this.statusTitle,
    required this.time,
    required this.mode,
    required this.result,
    required this.syncedItems,
    required this.sources,
    required this.methodItems,
    required this.infoItems,
    required this.safetyText,
  });

  static SyncHistoryDetailData get mock => SyncHistoryDetailData(
    statusTitle: lt('Sync Successful', '同步成功'),
    time: lt('Today 09:41', '今天 09:41'),
    mode: lt('Manual Sync', '手动同步'),
    result: lt('Synced 4 items', '成功同步 4 项数据'),
    syncedItems: [
      SyncDataType(
        icon: const MaterialAppIcon(Icons.directions_walk_rounded),
        iconColor: const Color(0xFF24F04E),
        title: lt('Steps', '步数'),
        value: lt('5,276 steps', '5,276 步'),
      ),
      SyncDataType(
        icon: const AssetAppIcon(AppMetricAssets.calories),
        iconColor: const Color(0xFFFF9F12),
        title: lt('Calories', '卡路里'),
        value: '293 kcal',
      ),
      SyncDataType(
        icon: const AssetAppIcon(AppMetricAssets.activeTime),
        iconColor: const Color(0xFF0CD9FF),
        title: lt('Time', '时间'),
        value: '28 min',
      ),
      SyncDataType(
        icon: const AssetAppIcon(AppMetricAssets.distance),
        iconColor: const Color(0xFF43F56B),
        title: lt('Distance', '距离'),
        value: '1.6 km',
      ),
    ],
    sources: [
      SyncDataSource(
        title: 'Apple Health',
        status: lt('Connected', '已连接'),
        icon: Icons.favorite_rounded,
        iconColor: const Color(0xFFFF2D55),
      ),
      SyncDataSource(
        title: 'Health Connect',
        status: lt('Connected', '已连接'),
        icon: Icons.link_rounded,
        iconColor: const Color(0xFF3D7CFF),
      ),
    ],
    methodItems: [
      SyncInfoItem(title: lt('Sync Mode', '同步方式'), value: lt('Manual', '手动')),
      SyncInfoItem(title: lt('Data Items', '数据项'), value: lt('4 items', '4 项')),
      SyncInfoItem(title: lt('Elapsed', '耗时'), value: '2.1 s'),
    ],
    infoItems: [
      SyncInfoItem(
        icon: const AssetAppIcon(AppMetricAssets.syncId),
        title: lt('Sync ID', '同步编号'),
        value: 'SYNC-2026-0513-0941',
      ),
      SyncInfoItem(
        icon: const AssetAppIcon(AppMetricAssets.syncDevice),
        title: lt('Device', '发起设备'),
        value: 'iPhone',
      ),
      SyncInfoItem(
        icon: const AssetAppIcon(AppMetricAssets.syncStatus),
        title: lt('Status', '记录状态'),
        value: lt('Success', '成功'),
        highlight: true,
      ),
    ],
    safetyText: lt(
      'Your data is protected and all synced data is encrypted in transit.',
      '您的数据安全受保护，所有数据均已加密传输。',
    ),
  );
}

class SyncInfoItem {
  final AppIconSource? icon;
  final String title;
  final String value;
  final bool highlight;

  const SyncInfoItem({
    this.icon,
    required this.title,
    required this.value,
    this.highlight = false,
  });
}

class SyncSourceDetailData {
  final SyncDataSource source;
  final List<SyncSourcePermission> permissions;
  final List<SyncModeOption> modeOptions;
  final List<ManualSyncSelectionItem> manualItems;
  final String safetyText;

  const SyncSourceDetailData({
    required this.source,
    required this.permissions,
    required this.modeOptions,
    required this.manualItems,
    required this.safetyText,
  });

  factory SyncSourceDetailData.forSource(SyncDataSource source) {
    return SyncSourceDetailData(
      source: source,
      permissions: [
        SyncSourcePermission(
          icon: const AssetAppIcon(AppMetricAssets.syncSteps),
          iconColor: const Color(0xFF24F04E),
          title: lt('Steps', '步数'),
        ),
        SyncSourcePermission(
          icon: const AssetAppIcon(AppMetricAssets.syncDistance),
          iconColor: const Color(0xFF43F56B),
          title: lt('Distance', '距离'),
        ),
        SyncSourcePermission(
          icon: const AssetAppIcon(AppMetricAssets.syncCalories),
          iconColor: const Color(0xFFFF9F12),
          title: lt('Calories', '卡路里'),
        ),
        SyncSourcePermission(
          icon: const AssetAppIcon(AppMetricAssets.syncActiveTime),
          iconColor: const Color(0xFF0CD9FF),
          title: lt('Time', '时间'),
        ),
      ],
      modeOptions: [
        SyncModeOption(
          title: lt('Auto Sync', '自动同步'),
          subtitle: lt(
            'Automatically sync latest health data after connecting',
            '在连接后自动同步最新健康数据',
          ),
          selected: true,
        ),
        SyncModeOption(
          title: lt('Manual Sync', '手动同步'),
          subtitle: lt(
            'Only sync selected data when triggered manually',
            '仅在手动触发时同步所选数据',
          ),
        ),
      ],
      manualItems: [
        ManualSyncSelectionItem(
          type: HealthSyncDataType.steps,
          title: lt('Steps', '步数'),
          selected: true,
        ),
        ManualSyncSelectionItem(
          type: HealthSyncDataType.distance,
          title: lt('Distance', '距离'),
          selected: true,
        ),
        ManualSyncSelectionItem(
          type: HealthSyncDataType.calories,
          title: lt('Calories', '卡路里'),
          selected: true,
        ),
        ManualSyncSelectionItem(
          type: HealthSyncDataType.activeMinutes,
          title: lt('Time', '时间'),
        ),
      ],
      safetyText: lt(
        'Your health data is read only after authorization and is encrypted in transit.',
        '您的健康数据仅在授权后读取，且会加密传输。',
      ),
    );
  }
}

class SyncSourcePermission {
  final AppIconSource icon;
  final Color iconColor;
  final String title;

  const SyncSourcePermission({
    required this.icon,
    required this.iconColor,
    required this.title,
  });
}

class SyncModeOption {
  final String title;
  final String subtitle;
  final bool selected;

  const SyncModeOption({
    required this.title,
    required this.subtitle,
    this.selected = false,
  });
}

class ManualSyncSelectionItem {
  final HealthSyncDataType type;
  final String title;
  final bool selected;

  const ManualSyncSelectionItem({
    required this.type,
    required this.title,
    this.selected = false,
  });
}
