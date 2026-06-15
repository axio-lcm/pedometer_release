/// 卡路里估算：固定默认体重 + 按速度查 MET 表。
/// MET（代谢当量）数值取自常见运动能耗表，按速度分档近似。
class WorkoutCaloriePolicy {
  const WorkoutCaloriePolicy({this.weightKg = 60});

  /// 估算用体重（千克）。项目暂无用户体重，使用固定默认值。
  final double weightKg;

  /// 按速度（km/h）返回 MET 值。
  static double metForSpeedKmh(double speedKmh) {
    if (speedKmh < 4) return 2.5;
    if (speedKmh < 6) return 3.5;
    if (speedKmh < 8) return 6.0;
    if (speedKmh < 10) return 8.3;
    if (speedKmh < 12) return 9.8;
    return 11.0;
  }

  /// 本次 tick 消耗的卡路里增量。
  /// [speedKmh] 当前速度，[seconds] tick 时长（秒）。
  double kcalForTick({required double speedKmh, required double seconds}) {
    final met = metForSpeedKmh(speedKmh);
    return met * weightKg * (seconds / 3600);
  }
}
