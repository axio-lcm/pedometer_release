import 'package:get/get.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';

/// 运动 / 训练主页 view model：运动类型选择 + 目标与成就展示数据。
class WorkoutViewModel extends GetxController implements IBaseViewModel {
  final WorkoutVo vo = WorkoutVo();

  RxInt get selectedType => vo.selectedType;
  Rx<WorkoutPageData> get data => vo.data;

  // 当前运动目标（与编辑运动目标页双向同步），默认值对齐 [WorkoutPageData.mock]。
  double goalDistance = 8.0;
  int goalDuration = 60;
  int goalCalories = 500;
  bool goalFreeTraining = false;

  WorkoutType get selectedWorkoutType {
    final types = vo.data.value.workoutTypes;
    if (types.isEmpty) return WorkoutPageData.mock.workoutTypes.first;
    final index = vo.selectedType.value.clamp(0, types.length - 1).toInt();
    return types[index];
  }

  @override
  void onInit() {
    super.onInit();
    init();
  }

  @override
  void init() {
    vo.data.value = WorkoutPageData.mock;
  }

  @override
  void unInit() {}

  @override
  void onClose() {
    unInit();
    super.onClose();
  }

  /// 选择运动类型。
  void selectType(int index) {
    final types = vo.data.value.workoutTypes;
    if (types.isEmpty) return;
    vo.selectedType.value = index.clamp(0, types.length - 1).toInt();
  }

  /// 应用编辑运动目标页保存的目标，刷新「目标与成就」中的目标指标展示。
  void applyGoal({
    required double distance,
    required int duration,
    required int calories,
    required bool freeTraining,
  }) {
    goalDistance = distance;
    goalDuration = duration;
    goalCalories = calories;
    goalFreeTraining = freeTraining;
    vo.data.value = vo.data.value.copyWith(goalMetrics: _buildGoalMetrics());
  }

  /// 依据当前目标构建目标指标列表，沿用 mock 的图标 / 颜色 / 标题。
  List<GoalMetric> _buildGoalMetrics() {
    final template = WorkoutPageData.mock.goalMetrics;
    final free = goalFreeTraining;
    // 进度起点为 0：展示「当前 / 目标」。
    String pair(String start, String target) => '$start / $target';

    GoalMetric build(int index, {required String value, String unit = ''}) {
      final base = template[index];
      return GoalMetric(
        title: base.title,
        value: value,
        unit: unit,
        icon: base.icon,
        color: base.color,
      );
    }

    return [
      build(
        0,
        value: free
            ? WorkoutText.noGoal
            : pair('0.00', goalDistance.toStringAsFixed(2)),
        unit: free ? '' : WorkoutText.distanceUnit,
      ),
      build(
        1,
        value: free ? WorkoutText.noGoal : pair('0', '$goalDuration'),
        unit: free ? '' : WorkoutText.durationUnit,
      ),
      build(
        2,
        value: free ? WorkoutText.noGoal : pair('0', '$goalCalories'),
        unit: free ? '' : 'kcal',
      ),
      build(
        3,
        value: free ? WorkoutText.freeTrainingOn : WorkoutText.noGoal,
      ),
    ];
  }
}

/// 运动主页状态对象。
class WorkoutVo {
  final RxInt selectedType = 0.obs;
  final Rx<WorkoutPageData> data = WorkoutPageData.mock.obs;
}
