import 'package:get/get.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';

/// 运动 / 训练主页 view model：运动类型选择 + 目标与成就展示数据。
class WorkoutViewModel extends GetxController implements IBaseViewModel {
  final WorkoutVo vo = WorkoutVo();

  RxInt get selectedType => vo.selectedType;
  Rx<WorkoutPageData> get data => vo.data;

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
}

/// 运动主页状态对象。
class WorkoutVo {
  final RxInt selectedType = 0.obs;
  final Rx<WorkoutPageData> data = WorkoutPageData.mock.obs;
}
