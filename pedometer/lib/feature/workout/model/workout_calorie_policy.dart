/// 卡路里估算：体重 + GPS 速度 -> ACSM 平地行走/跑步耗氧公式 -> kcal。
///
/// 比固定 MET 档位更细：速度连续变化时，消耗也连续变化；静止和 GPS 抖动不累计
/// 运动消耗。没有心率、坡度、风阻等数据时，这是当前可用输入里更稳妥的估算方式。
class WorkoutCaloriePolicy {
  const WorkoutCaloriePolicy({
    this.weightKg = 68,
    this.minActiveSpeedKmh = 0.5,
  });

  /// 估算用体重（千克）。项目暂无真实用户资料存储，默认值与「我的」页展示保持一致。
  final double weightKg;

  /// 低于该速度认为没有有效运动，避免站立时 GPS 漂移产生卡路里。
  final double minActiveSpeedKmh;

  static const double _restingVo2 = 3.5; // ml/kg/min，约 1 MET
  static const double _kcalPerLiterOxygen = 5.0;
  static const double _walkRunBlendStartKmh = 6.5;
  static const double _walkRunBlendEndKmh = 8.0;

  /// 按 ACSM 平地公式估算总耗氧量（ml/kg/min）。
  ///
  /// walking: VO2 = 0.1 * speed(m/min) + 3.5
  /// running: VO2 = 0.2 * speed(m/min) + 3.5
  /// 6.5-8.0 km/h 之间做平滑过渡，避免走跑切换点数值跳变。
  static double grossVo2ForSpeedKmh(double speedKmh) {
    if (!speedKmh.isFinite || speedKmh <= 0) return _restingVo2;

    final metersPerMinute = speedKmh * 1000 / 60;
    final walkingVo2 = 0.1 * metersPerMinute + _restingVo2;
    final runningVo2 = 0.2 * metersPerMinute + _restingVo2;

    if (speedKmh <= _walkRunBlendStartKmh) return walkingVo2;
    if (speedKmh >= _walkRunBlendEndKmh) return runningVo2;

    final blend =
        (speedKmh - _walkRunBlendStartKmh) /
        (_walkRunBlendEndKmh - _walkRunBlendStartKmh);
    return walkingVo2 + (runningVo2 - walkingVo2) * blend;
  }

  /// 本次 tick 的运动卡路里增量（active kcal）。
  /// [speedKmh] 当前速度，[seconds] tick 时长（秒）。
  double kcalForTick({required double speedKmh, required double seconds}) {
    if (seconds <= 0 ||
        weightKg <= 0 ||
        !speedKmh.isFinite ||
        speedKmh < minActiveSpeedKmh) {
      return 0;
    }

    final activeVo2 = grossVo2ForSpeedKmh(speedKmh) - _restingVo2;
    final litersPerMinute = activeVo2 * weightKg / 1000;
    return litersPerMinute * _kcalPerLiterOxygen * (seconds / 60);
  }
}
