import 'package:flutter/material.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/storage/language_service.dart';
import 'package:pedometer/common/tools/language_util.dart';
import 'package:pedometer/products/init/app.dart';

/// 应用冷启动初始化（main 入口）。
class AppStartup {
  AppStartup._();

  static bool _bootstrapped = false;

  static Future<void> run() async {
    await bootstrap();
    runApp(const PedometerApp());
  }

  static Future<void> bootstrap() async {
    if (_bootstrapped) return;
    WidgetsFlutterBinding.ensureInitialized();
    final languageService = LanguageService();
    await languageService.init();
    Get.put(languageService);
    await ResourceLoader.init(
      languageCode: languageService.resourceLanguageCode,
    );
    await LanguageUtil.applyStoredPreference();
    _bootstrapped = true;
  }
}
