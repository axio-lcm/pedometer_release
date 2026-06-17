import 'package:get/get.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/feature/mine/model/mine_model.dart';

/// 我的页 view model：个人数据与入口点击意图。
class MineViewModel extends GetxController implements IBaseViewModel {
  MineViewModel({MinePageData initialData = MinePageData.mock})
    : data = initialData.obs;

  final Rx<MinePageData> data;

  @override
  void init() {}

  @override
  void unInit() {}

  @override
  void onClose() {
    unInit();
    super.onClose();
  }

  void useData(MinePageData nextData) {
    if (identical(data.value, nextData)) return;
    data.value = nextData;
  }

  // TODO: 接入各入口真实跳转（主题 / 语言 / 协议等）。
  void openEntry(MineEntry entry) {}
}
