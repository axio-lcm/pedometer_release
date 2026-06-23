import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/service/motion_fitness_permission_service.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/feature/home/model/health_repository.dart';
import 'package:pedometer/feature/home/model/health_sync_models.dart';
import 'package:pedometer/feature/home/model/home_model.dart';
import 'package:pedometer/feature/home/model/sport_detail_model.dart';

/// 首页 view model
class HomeViewModel extends GetxController implements IBaseViewModel {
  final HomeVo vo = HomeVo();
  final HealthRepository repository;
  StreamSubscription<int>? _motionStepSubscription;
  int? _motionSensorSteps;

  HomeViewModel({HealthRepository? repository})
    : repository = repository ?? HealthRepository.defaultRepository();

  RxList<TrendPoint> get trend => vo.trend;
  RxList<AnalysisData> get analyses => vo.analyses;
  Rx<SportPeriodData> get dayOverview => vo.dayOverview;

  @override
  void onInit() {
    super.onInit();
    HealthSyncRuntime.revision.addListener(_loadHealthData);
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
    unInit();
    super.onClose();
  }

  void _loadHealthData() {
    final snapshot = repository.homeSnapshot();
    vo.trend.assignAll(snapshot.trend);
    vo.analyses.assignAll(snapshot.analyses);
    vo.dayOverview.value = repository.sportPeriodData(SportPeriod.day);
    _applyMotionSensorDataIfNeeded();
  }

  Future<void> _startMotionFitnessTracking() async {
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
    }

    _motionStepSubscription = MotionFitnessPermissionService.todayStepStream()
        .listen((steps) {
          _motionSensorSteps = steps;
          _applyMotionSensorDataIfNeeded();
        });
  }

  void _applyMotionSensorDataIfNeeded() {
    if (HealthSyncRuntime.hasRealDataSource) return;
    final steps = _motionSensorSteps;
    if (steps == null) return;

    final dataSource = SyncedHealthDataSource(
      summaries: [_motionSummaryFor(steps)],
    );
    HealthSyncRuntime.replaceMotionSensorDataSource(dataSource, steps: steps);
    final snapshot = dataSource.homeSnapshot();
    vo.trend.assignAll(snapshot.trend);
    vo.analyses.assignAll(snapshot.analyses);
    vo.dayOverview.value = dataSource.sportPeriodData(SportPeriod.day);
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
}

/// 首页状态对象
class HomeVo {
  final RxList<TrendPoint> trend = <TrendPoint>[].obs;
  final RxList<AnalysisData> analyses = <AnalysisData>[].obs;
  final Rx<SportPeriodData> dayOverview = SportDetailFixtures.day.obs;
}
