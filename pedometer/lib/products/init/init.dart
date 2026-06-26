import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/common/network/utils/headers_manager.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/storage/language_service.dart';
import 'package:pedometer/common/tools/language_util.dart';
import 'package:pedometer/feature/subscription/service/subscription_service.dart';
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
    await initializeDateFormatting();
    final languageService = LanguageService();
    await languageService.init();
    Get.put(languageService);
    await ResourceLoader.init(
      languageCode: languageService.resourceLanguageCode,
    );
    await LanguageUtil.applyStoredPreference();
    await HeaderManager.instance.initialize();
    final subscriptionService = SubscriptionService();
    await subscriptionService.init();
    Get.put(subscriptionService, permanent: true);
    // 原启动加载页的工作改为后台静默执行，不阻塞首屏；
    // 首屏路由依据本地会员状态（已在 init 中加载）直接决定。
    unawaited(subscriptionService.runStartupTasks());
    _bootstrapped = true;
  }
}
