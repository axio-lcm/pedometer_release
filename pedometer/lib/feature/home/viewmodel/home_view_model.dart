import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/common/service/motion_fitness_permission_service.dart';
import 'package:pedometer/common/storage/language_service.dart';
import 'package:pedometer/feature/home/model/health_repository.dart';
import 'package:pedometer/feature/home/model/health_sync_models.dart';
import 'package:pedometer/feature/home/model/home_model.dart';
import 'package:pedometer/feature/home/model/sport_detail_model.dart';
import 'package:pedometer/feature/subscription/service/subscription_service.dart';

/// 首页 view model
class HomeViewModel extends GetxController implements IBaseViewModel {
  final HomeVo vo = HomeVo();
  final HealthRepository repository;
  StreamSubscription<int>? _motionStepSubscription;
  int? _motionSensorSteps;
  List<int>? _motionHourlySteps;
  Worker? _languageWorker;
  Worker? _subscriptionWorker;

  HomeViewModel({HealthRepository? repository})
    : repository = repository ?? HealthRepository.defaultRepository();

  RxList<TrendPoint> get trend => vo.trend;
  RxList<AnalysisData> get analyses => vo.analyses;
  Rx<SportPeriodData> get dayOverview => vo.dayOverview;

  @override
  void onInit() {
    super.onInit();
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
        if (isVip) unawaited(_startMotionFitnessTracking());
      });
    }
    init();
  }

  @override
  void init() {
    _loadHealthData();
    unawaited(_startMotionFitnessTracking());
  }

  @override
  void unInit() {
    unawaited(_motionStepSubscription?.cancel());
    _motionStepSubscription = null;
  }

  @override
  void onClose() {
    HealthSyncRuntime.revision.removeListener(_loadHealthData);
    _languageWorker?.dispose();
    _subscriptionWorker?.dispose();
    unInit();
    super.onClose();
  }

  void _loadHealthData() {
    final snapshot = repository.homeSnapshot();
    vo.trend.assignAll(snapshot.trend);
    vo.analyses.assignAll(snapshot.analyses);
    vo.dayOverview.value = repository.sportPeriodData(SportPeriod.day);
    if (!_hasVipAccess) return;
    _applyMotionSensorDataIfNeeded();
  }

  Future<void> _startMotionFitnessTracking() async {
    if (!_hasVipAccess) return;
    if (!_shouldUseMotionFitnessOnThisPlatform) return;
    if (HealthSyncRuntime.hasRealDataSource ||
        _motionStepSubscription != null) {
      return;
    }

    final available =
        await MotionFitnessPermissionService.isStepCountingAvailable();
    if (!available || HealthSyncRuntime.hasRealDataSource) return;

    final status = await MotionFitnessPermissionService.requestAuthorization();
    if (status != MotionFitnessAuthorizationStatus.authorized ||
        HealthSyncRuntime.hasRealDataSource) {
      return;
    }

    final todaySteps = await MotionFitnessPermissionService.todaySteps();
    if (todaySteps != null) {
      _motionSensorSteps = todaySteps;
      _applyMotionSensorDataIfNeeded();
      unawaited(_loadMotionHourlySteps());
    }

    _motionStepSubscription = MotionFitnessPermissionService.todayStepStream()
        .listen((steps) {
          _updateCurrentMotionHour(steps);
          _motionSensorSteps = steps;
          _applyMotionSensorDataIfNeeded();
        });
  }

  void _applyMotionSensorDataIfNeeded() {
    if (!_hasVipAccess) return;
    if (HealthSyncRuntime.hasRealDataSource) return;
    final steps = _motionSensorSteps;
    if (steps == null) return;

    final dataSource = SyncedHealthDataSource(
      summaries: [_motionSummaryFor(steps)],
      hourlyStepsByDay: _motionHourlyStepsByDay(),
    );
    HealthSyncRuntime.replaceMotionSensorDataSource(dataSource, steps: steps);
    final snapshot = dataSource.homeSnapshot();
    vo.trend.assignAll(snapshot.trend);
    vo.analyses.assignAll(snapshot.analyses);
    vo.dayOverview.value = dataSource.sportPeriodData(SportPeriod.day);
  }

  Future<void> _loadMotionHourlySteps() async {
    if (HealthSyncRuntime.hasRealDataSource) return;
    final values = await MotionFitnessPermissionService.todayHourlySteps();
    if (values.isEmpty || HealthSyncRuntime.hasRealDataSource) return;
    _motionHourlySteps = _normalizeHourlySteps(values);
    _applyMotionSensorDataIfNeeded();
  }

  void _updateCurrentMotionHour(int latestTotalSteps) {
    final hourly = _motionHourlySteps;
    final previousTotalSteps = _motionSensorSteps;
    if (hourly == null || previousTotalSteps == null) return;
    final delta = latestTotalSteps - previousTotalSteps;
    if (delta <= 0) return;
    final hour = DateTime.now().hour.clamp(0, 23);
    hourly[hour] += delta;
  }

  Map<DateTime, List<HourlyStepData>> _motionHourlyStepsByDay() {
    final values = _motionHourlySteps;
    if (values == null || values.isEmpty) return const {};
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    return {
      day: [
        for (var hour = 0; hour < 24; hour++)
          HourlyStepData(
            '${hour.toString().padLeft(2, '0')}:00',
            hour < values.length ? values[hour] : 0,
          ),
      ],
    };
  }

  List<int> _normalizeHourlySteps(List<int> values) {
    return [
      for (var hour = 0; hour < 24; hour++)
        hour < values.length ? values[hour].clamp(0, 1 << 31) : 0,
    ];
  }

  HealthDailySummary _motionSummaryFor(int steps) {
    final now = DateTime.now();
    final safeSteps = steps < 0 ? 0 : steps;
    final distanceKm = safeSteps * 0.0007;
    return HealthDailySummary(
      date: DateTime(now.year, now.month, now.day),
      steps: safeSteps,
      distanceKm: distanceKm,
      caloriesKcal: safeSteps * 0.04,
      activeMinutes: (safeSteps / 100).round(),
      source: HealthSyncSource.motionSensor,
    );
  }

  bool get _shouldUseMotionFitnessOnThisPlatform {
    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool get _hasVipAccess {
    if (!Get.isRegistered<SubscriptionService>()) return true;
    return Get.find<SubscriptionService>().isVip.value;
  }
}

/// 首页状态对象
class HomeVo {
  final RxList<TrendPoint> trend = <TrendPoint>[].obs;
  final RxList<AnalysisData> analyses = <AnalysisData>[].obs;
  final Rx<SportPeriodData> dayOverview = SportDetailFixtures.day.obs;
}
