import 'package:flutter/material.dart';

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

  static const mock = SyncDataDetailData(
    statusTitle: '同步成功',
    lastSyncText: '最后同步： 今天 09:41',
    sources: [
      SyncDataSource(
        title: 'Apple Health',
        status: '已连接',
        icon: Icons.favorite_rounded,
        iconColor: Color(0xFFFF2D55),
      ),
      SyncDataSource(
        title: 'Health Connect',
        status: '已连接',
        icon: Icons.link_rounded,
        iconColor: Color(0xFF3D7CFF),
      ),
    ],
    overviewMetrics: [
      SyncMetric(value: '12,856', label: '总步数'),
      SyncMetric(value: '1,256', label: '总卡路里（kcal）'),
      SyncMetric(value: '98', label: '总活动时长（min）'),
    ],
    dataTypes: [
      SyncDataType(
        icon: Icons.directions_walk_rounded,
        iconColor: Color(0xFF24F04E),
        title: '步数',
        value: '12,856 步',
      ),
      SyncDataType(
        icon: Icons.local_fire_department_rounded,
        iconColor: Color(0xFFFF9F12),
        title: '卡路里',
        value: '1,256 kcal',
      ),
      SyncDataType(
        icon: Icons.timer_outlined,
        iconColor: Color(0xFF0CD9FF),
        title: '活动时间',
        value: '98 min',
      ),
      SyncDataType(
        icon: Icons.location_on_rounded,
        iconColor: Color(0xFF43F56B),
        title: '距离',
        value: '8.34 km',
      ),
    ],
    histories: [
      SyncHistoryRecord(time: '今天 09:41', mode: '手动同步', result: '成功同步 4 项数据'),
      SyncHistoryRecord(time: '昨天 20:30', mode: '自动同步', result: '成功同步 4 项数据'),
      SyncHistoryRecord(
        time: '05/13 08:15',
        mode: '自动同步',
        result: '成功同步 4 项数据',
      ),
    ],
    safetyText: '您的数据安全受保护，所有数据均已加密传输。',
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
}

class SyncMetric {
  final String value;
  final String label;

  const SyncMetric({required this.value, required this.label});
}

class SyncDataType {
  final IconData icon;
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
  final String time;
  final String mode;
  final String result;

  const SyncHistoryRecord({
    required this.time,
    required this.mode,
    required this.result,
  });
}
