import 'package:get/get.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/common/storage/language_service.dart';
import 'package:pedometer/common/tools/language_util.dart';

class LanguageViewModel extends GetxController implements IBaseViewModel {
  final selectedCode = 'en'.obs;

  LanguageService get _languageService => Get.find<LanguageService>();

  @override
  void onInit() {
    super.onInit();
    init();
  }

  @override
  void init() {
    selectedCode.value = _languageService.languageCode.value;
  }

  @override
  void unInit() {}

  @override
  void onClose() {
    unInit();
    super.onClose();
  }

  Future<void> select(String code) async {
    if (selectedCode.value == code) return;
    await LanguageUtil.switchTo(code);
    selectedCode.value = _languageService.languageCode.value;
  }
}
