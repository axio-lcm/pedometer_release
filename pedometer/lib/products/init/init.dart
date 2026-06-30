import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/common/network/utils/headers_manager.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/storage/language_service.dart';
import 'package:pedometer/common/tools/language_util.dart';
import 'package:pedometer/feature/home/model/health_data_store.dart';
import 'package:pedometer/feature/home/model/health_repository.dart';
import 'package:pedometer/feature/home/model/health_sync_models.dart';
import 'package:pedometer/feature/home/service/health_auto_sync_service.dart';
import 'package:pedometer/feature/subscription/service/subscription_service.dart';
import 'package:pedometer/feature/workout/model/achievement_stats_store.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';
import 'package:pedometer/feature/workout/service/step_goal_service.dart';
import 'package:pedometer/products/init/app.dart';

import '../phone/viewmodel/firebase_options.dart';

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

    final subscriptionService = SubscriptionService();
    final healthAutoSyncService = HealthAutoSyncService();
    Get.put(healthAutoSyncService, permanent: true);
    final stepGoalService = StepGoalService();

    await Future.wait([
      ResourceLoader.init(
        languageCode: languageService.resourceLanguageCode,
      ).then((_) => LanguageUtil.applyStoredPreference()),
      HeaderManager.instance.initialize(),
      subscriptionService.init().then(
        (service) => Get.put(service, permanent: true),
      ),
      stepGoalService.init().then(
        (service) => Get.put(service, permanent: true),
      ),
      AchievementStatsStore.load(),
      WorkoutRouteHistoryStore.load(),
      _hydrateHealthData(),
      if (Platform.isIOS)
        Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    ]);
    _bootstrapped = true;
  }

  /// 冷启动用本地持久化历史 hydrate 运行时，使首屏即展示历史而非 mock。
  ///
  /// 首页数据只来自「健康同步」来源；Android 走 Health Connect，iOS 走 Apple Health。
  /// 历史上由运动与健身(CMPedometer / Step Counter)写入的 motionSensor 记录不再进入首页底座。
  static Future<void> _hydrateHealthData() async {
    try {
      final summaries = await HealthDataStore.instance.loadSummaries();
      final preferredSource = Platform.isAndroid
          ? HealthSyncSource.healthConnect
          : HealthSyncSource.appleHealth;
      final preferredSummaries = [
        for (final summary in summaries)
          if (summary.source == preferredSource) summary,
      ];
      HealthSyncRuntime.hydrateBase(preferredSummaries);
      final history = await HealthDataStore.instance.loadSyncHistory();
      HealthSyncHistory.hydrate(history);
    } catch (_) {
      // 持久化读取失败不应阻塞启动；首屏退回空/ mock 状态。
    }
  }
}
