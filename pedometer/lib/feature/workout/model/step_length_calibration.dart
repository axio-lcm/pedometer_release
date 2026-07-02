import 'package:pedometer/common/config/prefs_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 户外 GPS 自校准步长（米）：安卓室内运动把步数换算成距离时优先使用。
///
/// 冷启动恢复一次；每次户外会话结束用「GPS 距离 ÷ 会话步数」做滚动平均更新，
/// 越跑越贴近该用户的真实步长。从未校准过时为 null，消费方回退到身高步频估算。
class StepLengthCalibration {
  StepLengthCalibration._();

  /// 单步长度的合理范围（米），样本超出视为脏数据不采纳。
  static const double minStepMeters = 0.3;
  static const double maxStepMeters = 1.5;

  /// 新会话样本在滚动平均中的权重。
  static const double _sampleWeight = 0.3;

  /// 当前校准值（米）；null 表示尚未校准。
  static double? stepLengthMeters;

  /// 冷启动时从本地持久化恢复。
  static Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getDouble(PrefsKeys.calibratedStepLength);
    stepLengthMeters =
        (stored != null && stored >= minStepMeters && stored <= maxStepMeters)
        ? stored
        : null;
  }

  /// 用一次户外会话的实测步长（GPS 距离 ÷ 会话步数）更新校准值并持久化。
  static Future<void> updateFromSession({
    required double sessionStepMeters,
  }) async {
    if (sessionStepMeters < minStepMeters || sessionStepMeters > maxStepMeters) {
      return;
    }
    final current = stepLengthMeters;
    final updated = current == null
        ? sessionStepMeters
        : current * (1 - _sampleWeight) + sessionStepMeters * _sampleWeight;
    stepLengthMeters = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(PrefsKeys.calibratedStepLength, updated);
  }
}
