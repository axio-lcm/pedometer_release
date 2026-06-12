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

/// 同步历史「查看全部」列表页展示数据。
class SyncHistoryListData {
  final List<SyncHistoryRecord> records;

  const SyncHistoryListData({required this.records});

  static const mock = SyncHistoryListData(
    records: [
      SyncHistoryRecord(time: '今天 09:41', mode: '手动同步', result: '成功同步 4 项数据'),
      SyncHistoryRecord(time: '昨天 20:30', mode: '自动同步', result: '成功同步 4 项数据'),
      SyncHistoryRecord(time: '昨天 08:05', mode: '自动同步', result: '成功同步 4 项数据'),
      SyncHistoryRecord(
        time: '05/13 08:15',
        mode: '自动同步',
        result: '成功同步 4 项数据',
      ),
      SyncHistoryRecord(
        time: '05/12 21:48',
        mode: '手动同步',
        result: '成功同步 3 项数据',
      ),
      SyncHistoryRecord(
        time: '05/12 07:30',
        mode: '自动同步',
        result: '成功同步 4 项数据',
      ),
      SyncHistoryRecord(
        time: '05/11 19:02',
        mode: '自动同步',
        result: '成功同步 4 项数据',
      ),
      SyncHistoryRecord(
        time: '05/11 08:20',
        mode: '手动同步',
        result: '成功同步 4 项数据',
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

  static const mock = SyncHistoryDetailData(
    statusTitle: '同步成功',
    time: '今天 09:41',
    mode: '手动同步',
    result: '成功同步 4 项数据',
    syncedItems: [
      SyncDataType(
        icon: Icons.directions_walk_rounded,
        iconColor: Color(0xFF24F04E),
        title: '步数',
        value: '5,276 步',
      ),
      SyncDataType(
        icon: Icons.local_fire_department_rounded,
        iconColor: Color(0xFFFF9F12),
        title: '卡路里',
        value: '293 kcal',
      ),
      SyncDataType(
        icon: Icons.timer_outlined,
        iconColor: Color(0xFF0CD9FF),
        title: '活动时间',
        value: '28 min',
      ),
      SyncDataType(
        icon: Icons.location_on_rounded,
        iconColor: Color(0xFF43F56B),
        title: '距离',
        value: '1.6 km',
      ),
    ],
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
    methodItems: [
      SyncInfoItem(title: '同步方式', value: '手动'),
      SyncInfoItem(title: '数据项', value: '4 项'),
      SyncInfoItem(title: '耗时', value: '2.1 s'),
    ],
    infoItems: [
      SyncInfoItem(
        icon: Icons.sell_outlined,
        title: '同步编号',
        value: 'SYNC-2026-0513-0941',
      ),
      SyncInfoItem(
        icon: Icons.phone_iphone_rounded,
        title: '发起设备',
        value: 'iPhone',
      ),
      SyncInfoItem(
        icon: Icons.verified_user_outlined,
        title: '记录状态',
        value: '成功',
        highlight: true,
      ),
    ],
    safetyText: '您的数据安全受保护，所有数据均已加密传输。',
  );
}

class SyncInfoItem {
  final IconData? icon;
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
