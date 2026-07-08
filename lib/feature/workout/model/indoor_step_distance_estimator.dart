/// 安卓室内距离估算器：步数增量 × 步长。
///
/// 安卓的 TYPE_STEP_COUNTER 只给步数不给距离（iOS 的 CMPedometer 距离由系统
/// 步态模型提供，安卓没有对等服务），距离只能估算。步长优先取户外 GPS
/// 自校准值；未校准过时按身高 × 步频系数估算，步频在走（≤130 步/分）与
/// 跑（≥150 步/分）之间线性过渡，避免走跑切换时距离增速跳变。
class IndoorStepDistanceEstimator {
  IndoorStepDistanceEstimator({
    required this.heightCm,
    this.calibratedStepLengthMeters,
  });

  final double heightCm;

  /// 户外 GPS 自校准步长（米）；非空且合法时直接使用，不再按身高估算。
  final double? calibratedStepLengthMeters;

  static const double _walkStepCoeff = 0.415;
  static const double _runStepCoeff = 0.60;
  static const double _walkCadenceSpm = 130;
  static const double _runCadenceSpm = 150;

  /// 相邻样本间隔超过该值视为中断（暂停后恢复等），不用于估算步频。
  static const Duration _maxSampleGap = Duration(seconds: 30);

  double _cadenceSpm = 0;
  DateTime? _lastAt;

  /// 记录一次步数增量并返回估算的距离增量（米）。
  double distanceForSteps({required int deltaSteps, required DateTime at}) {
    final last = _lastAt;
    _lastAt = at;
    if (deltaSteps <= 0) return 0;
    if (last != null) {
      final gap = at.difference(last);
      if (gap > Duration.zero && gap <= _maxSampleGap) {
        final instantSpm = deltaSteps * 60000 / gap.inMilliseconds;
        // EMA 平滑，吸收传感器批量上报造成的瞬时步频尖峰。
        _cadenceSpm = _cadenceSpm <= 0
            ? instantSpm
            : _cadenceSpm * 0.7 + instantSpm * 0.3;
      }
    }
    return deltaSteps * stepLengthMeters;
  }

  /// 当前步长（米）。
  double get stepLengthMeters {
    final calibrated = calibratedStepLengthMeters;
    if (calibrated != null && calibrated > 0) return calibrated;
    final heightMeters = heightCm / 100;
    if (_cadenceSpm <= _walkCadenceSpm) return heightMeters * _walkStepCoeff;
    if (_cadenceSpm >= _runCadenceSpm) return heightMeters * _runStepCoeff;
    final blend =
        (_cadenceSpm - _walkCadenceSpm) / (_runCadenceSpm - _walkCadenceSpm);
    return heightMeters * (_walkStepCoeff + (_runStepCoeff - _walkStepCoeff) * blend);
  }
}
