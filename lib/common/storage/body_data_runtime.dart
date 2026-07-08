import 'package:pedometer/common/config/prefs_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 身体数据的进程内运行时：冷启动从本地恢复一次，之后由「我的」编辑页保存时同步，
/// 运动等消费方直接同步读取，避免各处重复读 SharedPreferences。
class BodyDataRuntime {
  BodyDataRuntime._();

  /// 未填写过时的默认值，与「我的」页默认展示保持一致。
  static const double defaultWeightKg = 68.0;
  static const double defaultHeightCm = 175.0;

  /// 当前体重（千克）。
  static double weightKg = defaultWeightKg;

  /// 当前身高（厘米）。
  static double heightCm = defaultHeightCm;

  /// 冷启动时从本地持久化恢复。
  static Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    weightKg = prefs.getDouble(PrefsKeys.bodyWeight) ?? defaultWeightKg;
    heightCm = prefs.getDouble(PrefsKeys.bodyHeight) ?? defaultHeightCm;
  }
}
