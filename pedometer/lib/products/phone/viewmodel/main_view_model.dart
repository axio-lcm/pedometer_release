import 'package:get/get.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';

/// 手机主容器 view model：底部导航选中态。
class MainViewModel extends GetxController implements IBaseViewModel {
  final currentIndex = 0.obs;

  @override
  void init() {}

  @override
  void unInit() {}

  @override
  void onClose() {
    unInit();
    super.onClose();
  }

  void selectTab(int index) => currentIndex.value = index;
}
