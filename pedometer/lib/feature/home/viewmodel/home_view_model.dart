import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/common/service/motion_fitness_permission_service.dart';
import 'package:pedometer/common/storage/language_service.dart';
import 'package:pedometer/feature/home/model/health_data_store.dart';
import 'package:pedometer/feature/home/model/health_repository.dart';
import 'package:pedometer/feature/home/model/health_sync_models.dart';
import 'package:pedometer/feature/home/model/home_model.dart';
import 'package:pedometer/feature/home/model/sport_detail_model.dart';
import 'package:pedometer/feature/subscription/service/subscription_service.dart';

/// 首页 view model
class HomeViewModel extends GetxController implements IBaseViewModel {
  final HomeVo vo = HomeVo();
  final HealthRepository repository;
  StreamSubscription<MotionFitnessSample>? _motionStepSubscription;
  int? _motionSensorSteps;
  double? _motionSensorDistanceMeters;
  List<int>? _motionHourlySteps;
  int _lastPersistedTodaySteps = -1;
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
  }

  Future<void> _startMotionFitnessTracking() async {
    if (!_hasVipAccess) return;
    if (!_shouldUseMotionFitnessOnThisPlatform) return;
    if (_motionStepSubscription != null) return;

    final available =
        await MotionFitnessPermissionService.isStepCountingAvailable();
    if (!available) return;

    final status = await MotionFitnessPermissionService.requestAuthorization();
    if (status != MotionFitnessAuthorizationStatus.authorized) return;
    HealthSyncRuntime.motionAuthorized = true;

    // 回填最近 7 天（CMPedometer 本地保留上限）的真实步数 + 距离并入库。
    unawaited(_backfillMotionHistory());

    final today = await MotionFitnessPermissionService.todayActivity();
    if (today != null) {
      _motionSensorSteps = today.steps;
      if (today.distanceMeters > 0) {
        _motionSensorDistanceMeters = today.distanceMeters;
      }
      _pushMotionToday();
      unawaited(_loadMotionHourlySteps());
    }

    _motionStepSubscription = MotionFitnessPermissionService.todayStepStream()
        .listen((sample) {
          _updateCurrentMotionHour(sample.steps);
          _motionSensorSteps = sample.steps;
          if (sample.distanceMeters > 0) {
            _motionSensorDistanceMeters = sample.distanceMeters;
          }
          _pushMotionToday();
        });
  }

  /// 把今日运动汇总叠加到运行时（触发 revision → 重新渲染），并节流持久化。
  void _pushMotionToday() {
    if (!_hasVipAccess) return;
    final steps = _motionSensorSteps;
    if (steps == null) return;

    final summary = _motionSummaryFor(steps);
    HealthSyncRuntime.updateMotionToday(
      summary,
      hourly: _motionHourlyStepsByDay(),
    );

    // 节流：步数变化达到阈值才落盘，避免每步一次 DB 写。掉出会话也会被
    // 下次启动的 7 天回填修正，故无需逐步精确持久化。
    if (_lastPersistedTodaySteps < 0 ||
        (steps - _lastPersistedTodaySteps).abs() >= 25) {
      _lastPersistedTodaySteps = steps;
      unawaited(HealthDataStore.instance.upsertSummaries([summary]));
    }
  }

  /// 回查并持久化最近 7 天运动数据，再用合并后的库内历史 hydrate 底座供趋势展示。
  Future<void> _backfillMotionHistory() async {
    final samples = await MotionFitnessPermissionService.historyDailyData(7);
    if (samples.isEmpty) return;
    final summaries = [
      for (final sample in samples) _motionDailySummaryFrom(sample),
    ];
    await HealthDataStore.instance.upsertSummaries(summaries);
    HealthSyncRuntime.hydrateBase(await HealthDataStore.instance.loadSummaries());
  }

  Future<void> _loadMotionHourlySteps() async {
    final values = await MotionFitnessPermissionService.todayHourlySteps();
    if (values.isEmpty) return;
    _motionHourlySteps = _normalizeHourlySteps(values);
    _pushMotionToday();
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
    final distanceMeters = _motionSensorDistanceMeters;
    // 真实距离优先（CMPedometer.distance，与「健康」App 同源）；
    // 设备不支持距离统计时回退到按步数估算。
    final distanceKm = distanceMeters != null && distanceMeters > 0
        ? distanceMeters / 1000
        : safeSteps * 0.0007;
    return HealthDailySummary(
      date: DateTime(now.year, now.month, now.day),
      steps: safeSteps,
      distanceKm: distanceKm,
      caloriesKcal: safeSteps * 0.04,
      activeMinutes: (safeSteps / 100).round(),
      source: HealthSyncSource.motionSensor,
    );
  }

  /// 把回填的某一天运动样本转为日汇总；真实距离优先、按步数估算兜底。
  HealthDailySummary _motionDailySummaryFrom(MotionFitnessDailySample sample) {
    final safeSteps = sample.steps < 0 ? 0 : sample.steps;
    final distanceKm = sample.distanceMeters > 0
        ? sample.distanceMeters / 1000
        : safeSteps * 0.0007;
    return HealthDailySummary(
      date: DateTime(sample.date.year, sample.date.month, sample.date.day),
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
