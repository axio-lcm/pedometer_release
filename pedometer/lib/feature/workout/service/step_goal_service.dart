import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pedometer/common/config/prefs_keys.dart';
import 'package:pedometer/feature/home/model/health_repository.dart';

/// 每日步数目标的持久化真相源。
///
/// 编辑目标页写入；首页圆环与日/周/月目标统一读取（通过镜像到
/// [HealthSyncRuntime.dailyStepGoal]，周 = ×7、月 = ×当月天数）。
class StepGoalService extends GetxService {
  static const int defaultDailyGoal = HealthSyncRuntime.defaultDailyStepGoal;
  static const int minDailyGoal = 1000;
  static const int maxDailyGoal = 50000;
  static const int stepDelta = 500;

  /// 供编辑页响应式展示当前每日目标。
  final RxInt dailyGoal = defaultDailyGoal.obs;

  Future<StepGoalService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(PrefsKeys.dailyStepGoal) ?? defaultDailyGoal;
    _apply(saved);
    return this;
  }

  /// 设置每日步数目标：钳制到 [minDailyGoal, maxDailyGoal]、持久化、
  /// 镜像到运行时并触发首页 / 详情刷新。
  Future<void> setDailyGoal(int value) async {
    final clamped = _apply(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrefsKeys.dailyStepGoal, clamped);
  }

  int _apply(int value) {
    final clamped = value.clamp(minDailyGoal, maxDailyGoal);
    dailyGoal.value = clamped;
    HealthSyncRuntime.dailyStepGoal = clamped;
    // 复用健康数据 revision，让监听它的首页 / 运动详情重新读取新目标。
    HealthSyncRuntime.revision.value++;
    return clamped;
  }
}
