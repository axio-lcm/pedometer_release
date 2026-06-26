import 'dart:async';

import 'package:get/get.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';
import 'package:pedometer/feature/workout/service/step_goal_service.dart';
import 'package:pedometer/feature/workout/viewmodel/workout_view_model.dart';

/// 编辑运动目标页 view model：距离 / 时长 / 消耗调节与自由训练开关。
class EditSportGoalViewModel extends GetxController implements IBaseViewModel {
  // 默认值
  static const double defaultDistance = 3.0;
  static const int defaultDuration = 60;
  static const int defaultCalories = 100;
  static const int defaultSteps = StepGoalService.defaultDailyGoal;

  // 取值范围与步长
  static const double distanceMin = 1.0;
  static const double distanceMax = 20.0;
  static const double distanceStep = 0.5;
  static const int durationMin = 10;
  static const int durationMax = 300;
  static const int durationStep = 5;
  static const int caloriesMin = 100;
  static const int caloriesMax = 2000;
  static const int caloriesStep = 50;
  // 每日步数目标：范围与步长复用 StepGoalService（最少 1000 步）。
  static const int stepsMin = StepGoalService.minDailyGoal;
  static const int stepsMax = StepGoalService.maxDailyGoal;
  static const int stepsStep = StepGoalService.stepDelta;

  /// 运行时本地化建议文案：随语言切换读取对应译文。
  /// 不可声明为 const，否则只会取到 [WorkoutText] 的英文兜底常量。
  static List<String> get suggestions => [
    WorkoutResource.suggestionDistance,
    WorkoutResource.suggestionDuration,
    WorkoutResource.suggestionCalorie,
  ];

  final RxDouble distance = defaultDistance.obs;
  final RxInt duration = defaultDuration.obs;
  final RxInt calories = defaultCalories.obs;
  final RxInt steps = defaultSteps.obs;
  final RxBool freeTraining = false.obs;

  /// 每日步数目标按周/月汇总（展示用）。
  int get weeklyStepGoal => steps.value * 7;
  int get monthlyStepGoal {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    return steps.value * daysInMonth;
  }

  /// 自由训练开启时，三项目标不可调。
  bool get adjustEnabled => !freeTraining.value;

  @override
  void onInit() {
    super.onInit();
    init();
  }

  @override
  void init() {
    // 进入编辑页时，回填运动栏当前的目标设置。
    if (Get.isRegistered<WorkoutViewModel>()) {
      final workout = Get.find<WorkoutViewModel>();
      distance.value = workout.goalDistance;
      duration.value = workout.goalDuration;
      calories.value = workout.goalCalories;
      freeTraining.value = workout.goalFreeTraining;
    }
    // 回填当前每日步数目标（持久化的真相源）。
    if (Get.isRegistered<StepGoalService>()) {
      steps.value = Get.find<StepGoalService>().dailyGoal.value;
    }
  }

  @override
  void unInit() {}

  @override
  void onClose() {
    unInit();
    super.onClose();
  }

  void changeDistance(double delta) {
    distance.value = (distance.value + delta).clamp(distanceMin, distanceMax);
  }

  void changeDuration(int delta) {
    duration.value = (duration.value + delta).clamp(durationMin, durationMax);
  }

  void changeCalories(int delta) {
    calories.value = (calories.value + delta).clamp(caloriesMin, caloriesMax);
  }

  void changeSteps(int delta) {
    steps.value = (steps.value + delta).clamp(stepsMin, stepsMax);
  }

  void setFreeTraining(bool value) => freeTraining.value = value;

  void restoreDefaults() {
    distance.value = defaultDistance;
    duration.value = defaultDuration;
    calories.value = defaultCalories;
    steps.value = defaultSteps;
    freeTraining.value = false;
  }

  /// 汇总当前目标设置。
  SportGoalResult buildResult() {
    return SportGoalResult(
      distance: distance.value,
      duration: duration.value,
      calories: calories.value,
      steps: steps.value,
      freeTraining: freeTraining.value,
    );
  }

  /// 保存目标，并同步到运动栏的「目标与成就」模块展示，
  /// 同时把每日步数目标写入持久化真相源（联动首页圆环与日/周/月目标）。
  SportGoalResult save() {
    final result = buildResult();
    if (Get.isRegistered<WorkoutViewModel>()) {
      Get.find<WorkoutViewModel>().applyGoal(
        distance: result.distance,
        duration: result.duration,
        calories: result.calories,
        freeTraining: result.freeTraining,
      );
    }
    if (Get.isRegistered<StepGoalService>()) {
      unawaited(Get.find<StepGoalService>().setDailyGoal(result.steps));
    }
    return result;
  }
}

/// 保存目标返回结果。
class SportGoalResult {
  final double distance;
  final int duration;
  final int calories;
  final int steps;
  final bool freeTraining;

  const SportGoalResult({
    required this.distance,
    required this.duration,
    required this.calories,
    required this.steps,
    required this.freeTraining,
  });
}
