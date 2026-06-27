import 'dart:async';

import 'package:get/get.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/common/storage/language_service.dart';
import 'package:pedometer/feature/home/model/health_repository.dart';
import 'package:pedometer/feature/home/model/home_model.dart';
import 'package:pedometer/feature/home/service/health_auto_sync_service.dart';
import 'package:pedometer/feature/home/model/sport_detail_model.dart';
import 'package:pedometer/feature/subscription/service/subscription_service.dart';
import 'package:pedometer/products/phone/viewmodel/main_view_model.dart';

/// 首页 view model。
///
/// 数据全部来自「健康同步」(HealthKit / HealthSyncRuntime 底座)，不再使用
/// 运动与健身(CMPedometer)采集任何步数 / 距离 / 卡路里。
class HomeViewModel extends GetxController implements IBaseViewModel {
  final HomeVo vo = HomeVo();
  final HealthRepository repository;
  Worker? _languageWorker;
  Worker? _subscriptionWorker;
  Worker? _homeTabWorker;

  HomeViewModel({HealthRepository? repository})
    : repository = repository ?? HealthRepository.defaultRepository();

  RxList<TrendPoint> get trend => vo.trend;
  RxList<AnalysisData> get analyses => vo.analyses;
  Rx<SportPeriodData> get dayOverview => vo.dayOverview;

  @override
  void onInit() {
    super.onInit();
    // 健康同步数据变更（启动 hydrate / 后台重同步 / 手动同步）时刷新首页。
    HealthSyncRuntime.revision.addListener(_loadHealthData);
    if (Get.isRegistered<LanguageService>()) {
      _languageWorker = ever<int>(
        Get.find<LanguageService>().localeRevision,
        (_) => _loadHealthData(),
      );
    }
    if (Get.isRegistered<SubscriptionService>()) {
      _subscriptionWorker = ever<bool>(Get.find<SubscriptionService>().isVip, (
        isVip,
      ) {
        _loadHealthData();
        if (isVip) _autoSyncHealthData();
      });
    }
    if (Get.isRegistered<MainViewModel>()) {
      _homeTabWorker = ever<int>(
        Get.find<MainViewModel>().homeRevealTick,
        (_) => _autoSyncHealthData(),
      );
    }
    init();
  }

  @override
  void onReady() {
    super.onReady();
    _autoSyncHealthData();
  }

  @override
  void init() {
    _loadHealthData();
  }

  @override
  void unInit() {}

  @override
  void onClose() {
    HealthSyncRuntime.revision.removeListener(_loadHealthData);
    _languageWorker?.dispose();
    _subscriptionWorker?.dispose();
    _homeTabWorker?.dispose();
    unInit();
    super.onClose();
  }

  void _loadHealthData() {
    final snapshot = repository.homeSnapshot();
    vo.trend.assignAll(snapshot.trend);
    vo.analyses.assignAll(snapshot.analyses);
    vo.dayOverview.value = repository.sportPeriodData(SportPeriod.day);
  }

  void _autoSyncHealthData() {
    if (!Get.isRegistered<SubscriptionService>() ||
        !Get.find<SubscriptionService>().isVip.value ||
        !Get.isRegistered<HealthAutoSyncService>()) {
      return;
    }
    unawaited(Get.find<HealthAutoSyncService>().syncMemberHealthData());
  }
}

/// 首页状态对象
class HomeVo {
  final RxList<TrendPoint> trend = <TrendPoint>[].obs;
  final RxList<AnalysisData> analyses = <AnalysisData>[].obs;
  final Rx<SportPeriodData> dayOverview = SportDetailFixtures.day.obs;
}
