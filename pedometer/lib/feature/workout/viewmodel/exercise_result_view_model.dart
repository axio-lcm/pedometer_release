import 'package:get/get.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';

/// 运动结果页 view model：持有结果展示数据。
///
/// 运动结束跳转时通过 `Get.arguments` 传入真实聚合结果，优先于默认 mock。
class ExerciseResultViewModel extends GetxController
    implements IBaseViewModel {
  late ExerciseResultData data;

  @override
  void onInit() {
    super.onInit();
    init();
  }

  @override
  void init() {
    final args = Get.arguments;
    data = args is ExerciseResultData ? args : ExerciseResultData.mock;
  }

  @override
  void unInit() {}

  @override
  void onClose() {
    unInit();
    super.onClose();
  }
}
