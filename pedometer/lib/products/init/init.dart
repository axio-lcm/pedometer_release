import 'dart:async';

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
    await ResourceLoader.init(
      languageCode: languageService.resourceLanguageCode,
    );
    await LanguageUtil.applyStoredPreference();
    await HeaderManager.instance.initialize();
    final subscriptionService = SubscriptionService();
    await subscriptionService.init();
    Get.put(subscriptionService, permanent: true);
    final stepGoalService = StepGoalService();
    await stepGoalService.init();
    Get.put(stepGoalService, permanent: true);
    await AchievementStatsStore.load();
    await WorkoutRouteHistoryStore.load();
    await _hydrateHealthData();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    if (subscriptionService.isVip.value) {
      unawaited(_backgroundResyncAppleHealth());
    }
    _bootstrapped = true;
  }

  /// 冷启动用本地持久化历史 hydrate 运行时，使首屏即展示历史而非 mock。
  static Future<void> _hydrateHealthData() async {
    try {
      final summaries = await HealthDataStore.instance.loadSummaries();
      HealthSyncRuntime.hydrateBase(summaries);
      final history = await HealthDataStore.instance.loadSyncHistory();
      HealthSyncHistory.hydrate(history);
    } catch (_) {
      // 持久化读取失败不应阻塞启动；首屏退回空/ mock 状态。
    }
  }

  /// 后台静默重同步 Apple Health：仅在此前已授权（不再弹权限）时刷新到最新。
  static Future<void> _backgroundResyncAppleHealth() async {
    try {
      final lastSync = await HealthDataStore.instance.lastSyncTime();
      if (lastSync == null) return; // 从未同步过 → 不在启动时主动拉起。
      final service = HealthPluginSyncService();
      const source = HealthSyncSource.appleHealth;
      if (!await service.isAvailable(source: source)) return;

      final start = DateTime(2014, 1, 1);
      final now = DateTime.now();
      final result = await service
          .sync(
            source: source,
            startDate: start,
            endDate: now,
            ensureAuthorized: false,
          )
          .timeout(const Duration(minutes: 2));
      if (!result.source.hasData) return;

      HealthSyncRuntime.replaceRealDataSource(result.source);
      HealthSyncRuntime.setConnectionStatus(source, HealthAuthStatus.authorized);
      await HealthDataStore.instance.upsertSummaries(result.source.summaries);
      await HealthDataStore.instance.setLastSyncTime(now);

      final refined = await service.refineStepDetails(
        points: result.points,
        source: source,
        startDate: start,
        endDate: now,
      );
      if (refined.hasData) {
        HealthSyncRuntime.replaceRealDataSource(refined);
        await HealthDataStore.instance.upsertSummaries(refined.summaries);
      }
    } catch (_) {
      // 后台刷新失败不影响已 hydrate 的本地历史。
    }
  }
}
