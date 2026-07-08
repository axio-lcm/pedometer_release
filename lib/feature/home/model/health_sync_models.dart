enum HealthSyncSource { appleHealth, healthConnect, motionSensor }

enum HealthSyncDataType { steps, distance, calories, activeMinutes }

/// 健康数据来源的授权/连接状态。
///
/// iOS（Apple Health）出于隐私不会透露读权限是否授予，只能通过能否读到数据
/// 间接判断；读不到数据时无法区分「被拒绝」与「确实无数据」，因此用 [unknown]
/// 表示「未确认」，避免误显示为已连接。
enum HealthAuthStatus {
  /// 未确认（iOS 上请求后读不到数据，无法判定）。
  unknown,

  /// 已确认授权（Android 明确授予，或 iOS 读到了数据）。
  authorized,

  /// 明确被拒绝（仅 Android 可可靠判断）。
  denied,

  /// 当前设备不可用（如未安装 Health Connect）。
  unavailable,

  /// 当前平台不支持该来源。
  unsupported,
}

class HealthDailySummary {
  final DateTime date;
  final int steps;
  final double distanceKm;
  final double caloriesKcal;
  final int activeMinutes;
  final HealthSyncSource source;

  const HealthDailySummary({
    required this.date,
    required this.steps,
    required this.distanceKm,
    required this.caloriesKcal,
    required this.activeMinutes,
    required this.source,
  });

  /// 去除时分秒，仅保留自然日（去重 / 主键以此为准）。
  DateTime get dateOnly => DateTime(date.year, date.month, date.day);

  /// 'yyyy-MM-dd' 形式的日期键，用作持久化主键。
  String get dateKey {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  HealthDailySummary copyWith({
    DateTime? date,
    int? steps,
    double? distanceKm,
    double? caloriesKcal,
    int? activeMinutes,
    HealthSyncSource? source,
  }) {
    return HealthDailySummary(
      date: date ?? this.date,
      steps: steps ?? this.steps,
      distanceKm: distanceKm ?? this.distanceKm,
      caloriesKcal: caloriesKcal ?? this.caloriesKcal,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      source: source ?? this.source,
    );
  }

  Map<String, Object?> toRow() {
    return {
      'date': dateKey,
      'steps': steps,
      'distance_km': distanceKm,
      'calories_kcal': caloriesKcal,
      'active_minutes': activeMinutes,
      'source': source.name,
    };
  }

  static HealthDailySummary fromRow(Map<String, Object?> row) {
    return HealthDailySummary(
      date: DateTime.parse(row['date'] as String),
      steps: (row['steps'] as num?)?.toInt() ?? 0,
      distanceKm: (row['distance_km'] as num?)?.toDouble() ?? 0,
      caloriesKcal: (row['calories_kcal'] as num?)?.toDouble() ?? 0,
      activeMinutes: (row['active_minutes'] as num?)?.toInt() ?? 0,
      source: _sourceFromName(row['source'] as String?),
    );
  }

  static HealthSyncSource _sourceFromName(String? name) {
    return HealthSyncSource.values.firstWhere(
      (s) => s.name == name,
      orElse: () => HealthSyncSource.appleHealth,
    );
  }
}
