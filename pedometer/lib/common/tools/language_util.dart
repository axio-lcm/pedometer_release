import 'package:get/get.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/common/storage/language_service.dart';

class LanguageUtil {
  LanguageUtil._();

  static Future<void> switchTo(String code) async {
    final service = Get.find<LanguageService>();
    await service.setLanguageCode(code);
    await ResourceLoader.setLanguageCode(service.resourceLanguageCode);
    Get.updateLocale(service.locale);
    service.markLocaleChanged();
  }

  static Future<void> applyStoredPreference() async {
    final service = Get.find<LanguageService>();
    await ResourceLoader.setLanguageCode(service.resourceLanguageCode);
    Get.updateLocale(service.locale);
    service.markLocaleChanged();
  }
}
