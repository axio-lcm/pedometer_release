enum HealthSyncSource { appleHealth, healthConnect }

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
}
