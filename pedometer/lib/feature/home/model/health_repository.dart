import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_icon_source.dart';
import 'package:pedometer/common/config/app_metric_assets.dart';
import 'package:pedometer/feature/home/model/home_model.dart';
import 'package:pedometer/feature/home/model/health_sync_models.dart';
import 'package:pedometer/feature/home/model/sport_detail_model.dart';

class HealthHomeSnapshot {
  final StepData step;
  final List<KpiItem> kpis;
  final List<TrendPoint> trend;
  final List<AnalysisData> analyses;

  const HealthHomeSnapshot({
    required this.step,
    required this.kpis,
    required this.trend,
    required this.analyses,
  });
}

abstract class MembershipService {
  bool get isActive;
}

class FixedMembershipService implements MembershipService {
  @override
  final bool isActive;

  const FixedMembershipService(this.isActive);
}

abstract class HealthDataSource {
  HealthHomeSnapshot homeSnapshot();
  SportPeriodData sportPeriodData(SportPeriod period);
}

class HealthRepository {
  final MembershipService membershipService;
  final HealthDataSource mockDataSource;
  final HealthDataSource realDataSource;

  const HealthRepository({
    required this.membershipService,
    required this.mockDataSource,
    required this.realDataSource,
  });

  factory HealthRepository.defaultRepository() {
    return HealthRepository(
      membershipService: const FixedMembershipService(true),
      mockDataSource: const MockHealthDataSource(),
      realDataSource: RuntimeHealthDataSource(
        fallback: const MockHealthDataSource(),
      ),
    );
  }

  HealthDataSource get _activeDataSource =>
      membershipService.isActive ? realDataSource : mockDataSource;

  HealthHomeSnapshot homeSnapshot() => _activeDataSource.homeSnapshot();

  SportPeriodData sportPeriodData(SportPeriod period) {
    return _activeDataSource.sportPeriodData(period);
  }
}

class HealthSyncRuntime {
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// 各来源的连接（授权）状态变更通知，供来源列表/详情页同步显示。
  static final ValueNotifier<int> connectionRevision = ValueNotifier<int>(0);

  static HealthDataSource? _realDataSource;
  static HealthDataSource? _motionSensorDataSource;
  static int? _motionSensorSteps;
  static final Map<HealthSyncSource, HealthAuthStatus> _connectionStatus = {};

  HealthSyncRuntime._();

  static HealthDataSource dataSourceOr(HealthDataSource fallback) {
    return _realDataSource ?? _motionSensorDataSource ?? fallback;
  }

  static bool get hasRealDataSource => _realDataSource != null;

  static void replaceRealDataSource(HealthDataSource dataSource) {
    _realDataSource = dataSource;
    _motionSensorDataSource = null;
    _motionSensorSteps = null;
    revision.value++;
  }

  static void replaceMotionSensorDataSource(
    HealthDataSource dataSource, {
    required int steps,
  }) {
    if (_realDataSource != null || _motionSensorSteps == steps) return;
    _motionSensorDataSource = dataSource;
    _motionSensorSteps = steps;
    revision.value++;
  }

  /// 读取某来源最近一次确认的连接状态，默认 [HealthAuthStatus.unknown]。
  static HealthAuthStatus connectionStatusOf(HealthSyncSource source) {
    return _connectionStatus[source] ?? HealthAuthStatus.unknown;
  }

  /// 记录某来源的连接状态并通知监听者。
  static void setConnectionStatus(
    HealthSyncSource source,
    HealthAuthStatus status,
  ) {
    if (_connectionStatus[source] == status) return;
    _connectionStatus[source] = status;
    connectionRevision.value++;
  }

  static void resetForTest() {
    _realDataSource = null;
    _motionSensorDataSource = null;
    _motionSensorSteps = null;
    _connectionStatus.clear();
    revision.value++;
    connectionRevision.value++;
  }
}

class RuntimeHealthDataSource implements HealthDataSource {
  final HealthDataSource fallback;

  const RuntimeHealthDataSource({required this.fallback});

  HealthDataSource get _current => HealthSyncRuntime.dataSourceOr(fallback);

  @override
  HealthHomeSnapshot homeSnapshot() => _current.homeSnapshot();

  @override
  SportPeriodData sportPeriodData(SportPeriod period) {
    return _current.sportPeriodData(period);
  }
}

class MockHealthDataSource implements HealthDataSource {
  const MockHealthDataSource();

  @override
  HealthHomeSnapshot homeSnapshot() {
    return HealthHomeSnapshot(
      step: const StepData(steps: 5276, goal: 6000),
      kpis: const [
        KpiItem(
          assetIcon: AppMetricAssets.distance,
          title: '距离',
          value: '1.6',
          unit: 'km',
        ),
        KpiItem(
          assetIcon: AppMetricAssets.calories,
          title: '卡路里',
          value: '293',
          unit: 'kcal',
        ),
        KpiItem(
          assetIcon: AppMetricAssets.activeTime,
          title: '活动时间',
          value: '28',
          unit: 'min',
        ),
      ],
      trend: _mockHomeTrend(),
      analyses: [
        AnalysisData(
          title: '卡路里分析',
          assetIcon: AppMetricAssets.calories,
          value: '293',
          unit: 'kcal',
          delta: '较昨日 +12%',
          color: AppColors.accentOrange,
          samples: const [0.30, 0.45, 0.38, 0.60, 0.55, 0.78, 0.92],
        ),
        AnalysisData(
          title: '活动时间分析',
          assetIcon: AppMetricAssets.activeTime,
          value: '28',
          unit: 'min',
          delta: '较昨日 +8%',
          color: AppColors.accentCyan,
          samples: const [0.40, 0.35, 0.55, 0.50, 0.70, 0.66, 0.88],
        ),
      ],
    );
  }

  @override
  SportPeriodData sportPeriodData(SportPeriod period) {
    final data = SportDetailFixtures.byPeriod(period);
    if (period != SportPeriod.week) return data;
    return data.copyWith(
      weekly: _weeklyTrendForCurrentWeek(_mockDailySummariesEndingToday()),
    );
  }
}

class HealthPluginSyncService {
  final Health health;

  HealthPluginSyncService({Health? health}) : health = health ?? Health();

  Future<bool> isAvailable({required HealthSyncSource source}) async {
    if (!_sourceMatchesPlatform(source)) return false;
    await health.configure();
    if (source == HealthSyncSource.healthConnect) {
      final status = await health.getHealthConnectSdkStatus();
      return status == HealthConnectSdkStatus.sdkAvailable;
    }
    return true;
  }

  Future<bool> requestAuthorization({
    required HealthSyncSource source,
    List<HealthSyncDataType> types = const [
      HealthSyncDataType.steps,
      HealthSyncDataType.distance,
      HealthSyncDataType.calories,
      HealthSyncDataType.activeMinutes,
    ],
  }) async {
    if (!await isAvailable(source: source)) return false;
    final healthTypes = _healthTypesFor(source: source, types: types);
    if (healthTypes.isEmpty) return false;
    return health.requestAuthorization(
      healthTypes,
      permissions: List<HealthDataAccess>.filled(
        healthTypes.length,
        HealthDataAccess.READ,
      ),
    );
  }

  Future<SyncedHealthDataSource> sync({
    required HealthSyncSource source,
    required DateTime startDate,
    required DateTime endDate,
    List<HealthSyncDataType> types = const [
      HealthSyncDataType.steps,
      HealthSyncDataType.distance,
      HealthSyncDataType.calories,
      HealthSyncDataType.activeMinutes,
    ],
    // 调用方若已单独申请过权限，可置为 false 避免重复弹窗。
    bool ensureAuthorized = true,
    // iOS 刚授权后首次读取可能因权限未生效返回空，空结果时按此重试。
    int readRetries = 2,
    Duration retryDelay = const Duration(milliseconds: 600),
  }) async {
    if (ensureAuthorized &&
        !await requestAuthorization(source: source, types: types)) {
      return const SyncedHealthDataSource(summaries: []);
    }
    final healthTypes = _healthTypesFor(source: source, types: types);

    var points = <HealthDataPoint>[];
    for (var attempt = 0; attempt <= readRetries; attempt++) {
      points = await health.getHealthDataFromTypes(
        types: healthTypes,
        startTime: startDate,
        endTime: endDate,
      );
      if (points.isNotEmpty) break;
      if (attempt < readRetries) {
        await Future<void>.delayed(retryDelay);
      }
    }

    return SyncedHealthDataSource(
      summaries: _dailySummariesFromPoints(
        points,
        source: source,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  bool _sourceMatchesPlatform(HealthSyncSource source) {
    return switch (health.platformType) {
      HealthPlatformType.appleHealth => source == HealthSyncSource.appleHealth,
      HealthPlatformType.googleHealthConnect =>
        source == HealthSyncSource.healthConnect,
    };
  }

  List<HealthDataType> _healthTypesFor({
    required HealthSyncSource source,
    required List<HealthSyncDataType> types,
  }) {
    final healthTypes = <HealthDataType>[];
    for (final type in types) {
      final mapped = _healthTypeFor(source: source, type: type);
      if (mapped != null && !healthTypes.contains(mapped)) {
        healthTypes.add(mapped);
      }
    }
    return healthTypes;
  }

  HealthDataType? _healthTypeFor({
    required HealthSyncSource source,
    required HealthSyncDataType type,
  }) {
    return switch (type) {
      HealthSyncDataType.steps => HealthDataType.STEPS,
      HealthSyncDataType.distance =>
        source == HealthSyncSource.appleHealth
            ? HealthDataType.DISTANCE_WALKING_RUNNING
            : HealthDataType.DISTANCE_DELTA,
      HealthSyncDataType.calories =>
        source == HealthSyncSource.appleHealth
            ? HealthDataType.ACTIVE_ENERGY_BURNED
            : HealthDataType.TOTAL_CALORIES_BURNED,
      HealthSyncDataType.activeMinutes =>
        source == HealthSyncSource.appleHealth
            ? HealthDataType.EXERCISE_TIME
            : HealthDataType.ACTIVITY_INTENSITY,
    };
  }

  List<HealthDailySummary> _dailySummariesFromPoints(
    List<HealthDataPoint> points, {
    required HealthSyncSource source,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final byDay = <DateTime, _DailyHealthAccumulator>{};
    for (final point in points) {
      final day = _dateOnly(point.dateFrom.toLocal());
      if (day.isBefore(_dateOnly(startDate)) ||
          day.isAfter(_dateOnly(endDate))) {
        continue;
      }
      final summary = byDay.putIfAbsent(day, _DailyHealthAccumulator.new);
      final value = _numericHealthValue(point);
      switch (point.type) {
        case HealthDataType.STEPS:
          summary.steps += value.round();
        case HealthDataType.DISTANCE_WALKING_RUNNING:
        case HealthDataType.DISTANCE_DELTA:
          summary.distanceKm += value / 1000;
        case HealthDataType.ACTIVE_ENERGY_BURNED:
        case HealthDataType.TOTAL_CALORIES_BURNED:
          summary.caloriesKcal += value;
        case HealthDataType.EXERCISE_TIME:
        case HealthDataType.ACTIVITY_INTENSITY:
          summary.activeMinutes += value.round();
        default:
          break;
      }
    }

    final summaries = [
      for (final entry in byDay.entries)
        HealthDailySummary(
          date: entry.key,
          steps: entry.value.steps,
          distanceKm: entry.value.distanceKm,
          caloriesKcal: entry.value.caloriesKcal,
          activeMinutes: entry.value.activeMinutes,
          source: source,
        ),
    ];
    summaries.sort((a, b) => a.date.compareTo(b.date));
    return summaries;
  }
}

class _DailyHealthAccumulator {
  int steps = 0;
  double distanceKm = 0;
  double caloriesKcal = 0;
  int activeMinutes = 0;
}

class SyncedHealthDataSource implements HealthDataSource {
  final List<HealthDailySummary> summaries;

  const SyncedHealthDataSource({required this.summaries});

  /// 是否读到任何有效健康数据（非空且至少一天有非零指标）。
  /// 用于区分“同步成功但全为 0”（如模拟器无数据/未授权读取）的情况。
  bool get hasData => summaries.any(
    (s) =>
        s.steps > 0 ||
        s.distanceKm > 0 ||
        s.caloriesKcal > 0 ||
        s.activeMinutes > 0,
  );

  List<HealthDailySummary> get _sorted {
    final sorted = [...summaries];
    sorted.sort((a, b) => a.date.compareTo(b.date));
    return sorted;
  }

  HealthDailySummary get _latest {
    final sorted = _sorted;
    if (sorted.isEmpty) {
      return HealthDailySummary(
        date: DateTime.now(),
        steps: 0,
        distanceKm: 0,
        caloriesKcal: 0,
        activeMinutes: 0,
        source: HealthSyncSource.appleHealth,
      );
    }
    return sorted.last;
  }

  @override
  HealthHomeSnapshot homeSnapshot() {
    final latest = _latest;
    final recent = _sorted.length <= 7
        ? _sorted
        : _sorted.sublist(_sorted.length - 7);

    return HealthHomeSnapshot(
      step: StepData(steps: latest.steps, goal: 6000),
      kpis: [
        KpiItem(
          assetIcon: AppMetricAssets.distance,
          title: '距离',
          value: _formatDecimal(latest.distanceKm),
          unit: 'km',
        ),
        KpiItem(
          assetIcon: AppMetricAssets.calories,
          title: '卡路里',
          value: _formatInt(latest.caloriesKcal.round()),
          unit: 'kcal',
        ),
        KpiItem(
          assetIcon: AppMetricAssets.activeTime,
          title: '活动时间',
          value: _formatInt(latest.activeMinutes),
          unit: 'min',
        ),
      ],
      trend: _homeTrendEndingToday(_sorted),
      analyses: [
        AnalysisData(
          title: '卡路里分析',
          assetIcon: AppMetricAssets.calories,
          value: _formatInt(latest.caloriesKcal.round()),
          unit: 'kcal',
          delta: '来自健康同步',
          color: AppColors.accentOrange,
          samples: _normalizedSamples(recent.map((item) => item.caloriesKcal)),
        ),
        AnalysisData(
          title: '活动时间分析',
          assetIcon: AppMetricAssets.activeTime,
          value: _formatInt(latest.activeMinutes),
          unit: 'min',
          delta: '来自健康同步',
          color: AppColors.accentCyan,
          samples: _normalizedSamples(
            recent.map((item) => item.activeMinutes.toDouble()),
          ),
        ),
      ],
    );
  }

  @override
  SportPeriodData sportPeriodData(SportPeriod period) {
    return switch (period) {
      SportPeriod.day => _dayData(),
      SportPeriod.week => _weekData(),
      SportPeriod.month => _monthData(),
    };
  }

  SportPeriodData _dayData() {
    final latest = _latest;
    return SportPeriodData(
      period: SportPeriod.day,
      dateTitle: _dateTitle(latest.date),
      progress: SportProgressData(
        title: '今日步数',
        value: latest.steps,
        goal: 6000,
        goalUnit: '步',
        badgePrefix: '达成',
      ),
      metrics: _metricsFor(
        distanceKm: latest.distanceKm,
        caloriesKcal: latest.caloriesKcal,
        activeMinutes: latest.activeMinutes,
      ),
      hourly: [HourlyStepData(_hourlyLabelFor(latest.date), latest.steps)],
      segments: const [],
      analyses: _dayAnalyses(),
      summary: SportSummaryData(
        icon: const MaterialAppIcon(Icons.verified_rounded),
        color: AppColors.brandGreen,
        title: '同步总结',
        primary: '数据来源：',
        highlight: _sourceTitle(latest.source),
        secondary: '已同步今日步数、距离、卡路里和活动时间',
        assetName: 'synced health data',
      ),
    );
  }

  SportPeriodData _weekData() {
    final sorted = _sorted;
    final today = _dateOnly(DateTime.now());
    final weekStart = _weekMonday(today);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final elapsedDays = today.difference(weekStart).inDays + 1;
    final currentWeekItems = sorted.where((item) {
      final date = _dateOnly(item.date);
      return !date.isBefore(weekStart) && !date.isAfter(today);
    }).toList();
    final weeklyTrend = _weeklyTrendForCurrentWeek(sorted, today: today);
    final steps = _sumInt(weeklyTrend.map((item) => item.steps));
    final activeDays = weeklyTrend.where((item) => item.steps > 0).length;
    final goalDays = weeklyTrend.where((item) => item.steps >= 6000).length;

    return SportPeriodData(
      period: SportPeriod.week,
      dateTitle: '${_shortDate(weekStart)} - ${_shortDate(weekEnd)}',
      progress: SportProgressData(
        title: '本周步数',
        value: steps,
        goal: 42000,
        goalUnit: '目标',
        badgePrefix: '完成',
      ),
      metrics: [
        SportMetricData(
          iconAsset: AppMetricAssets.dayAverage,
          color: AppColors.accentCyan,
          title: '日均',
          value: _formatInt(
            elapsedDays <= 0 ? 0 : (steps / elapsedDays).round(),
          ),
          unit: '步',
        ),
        SportMetricData(
          iconAsset: AppMetricAssets.activeDays,
          color: AppColors.accentOrange,
          title: '活跃天数',
          value: '$activeDays / 7',
          unit: '天',
        ),
        SportMetricData(
          iconAsset: AppMetricAssets.targetMet,
          color: AppColors.accentPurple,
          title: '达标天数',
          value: '$goalDays',
          unit: '天',
        ),
      ],
      weekly: weeklyTrend,
      analyses: _periodAnalyses(currentWeekItems, '来自健康同步'),
      summary: SportSummaryData(
        icon: const AssetAppIcon(AppMetricAssets.weekSummary),
        color: AppColors.brandGreen,
        title: '周总结',
        primary: '最高步数：',
        highlight: _bestDayText(currentWeekItems),
        secondary: '本周同步 $activeDays 天健康数据',
        assetName: 'synced weekly health data',
      ),
    );
  }

  SportPeriodData _monthData() {
    final sorted = _sorted;
    final latest = _latest;
    final monthItems = sorted
        .where(
          (item) =>
              item.date.year == latest.date.year &&
              item.date.month == latest.date.month,
        )
        .toList();
    final steps = _sumInt(monthItems.map((item) => item.steps));
    final goalDays = monthItems.where((item) => item.steps >= 6000).length;

    return SportPeriodData(
      period: SportPeriod.month,
      dateTitle: '${latest.date.year}年${latest.date.month}月',
      progress: SportProgressData(
        title: '本月步数',
        value: steps,
        goal: 180000,
        goalUnit: '目标',
        badgePrefix: '完成',
      ),
      metrics: [
        SportMetricData(
          iconAsset: AppMetricAssets.monthDailyAverage,
          color: AppColors.brandGreen,
          title: '日均',
          value: _formatInt(
            monthItems.isEmpty ? 0 : (steps / monthItems.length).round(),
          ),
          unit: '步',
        ),
        SportMetricData(
          iconAsset: AppMetricAssets.monthTargetMet,
          color: AppColors.accentCyan,
          title: '达标天数',
          value: '$goalDays',
          unit: '天',
        ),
        SportMetricData(
          iconAsset: AppMetricAssets.monthTotalDistance,
          color: AppColors.accentPurple,
          title: '总距离',
          value: _formatDecimal(
            monthItems.fold<double>(0, (sum, item) => sum + item.distanceKm),
          ),
          unit: 'km',
        ),
      ],
      monthly: [
        for (final item in monthItems)
          MonthlyDayData(item.date.day, item.steps),
      ],
      analyses: _periodAnalyses(monthItems, '来自健康同步'),
      summary: SportSummaryData(
        icon: const AssetAppIcon(AppMetricAssets.monthSummary),
        color: AppColors.brandGreen,
        title: '月度总结',
        primary: '最佳单日：',
        highlight: _bestDayText(monthItems),
        secondary: '本月已同步 ${monthItems.length} 天健康数据',
        assetName: 'synced monthly health data',
      ),
    );
  }

  List<SportMetricData> _metricsFor({
    required double distanceKm,
    required double caloriesKcal,
    required int activeMinutes,
  }) {
    return [
      SportMetricData(
        iconAsset: AppMetricAssets.distance,
        color: AppColors.accentPurple,
        title: '距离',
        value: _formatDecimal(distanceKm),
        unit: 'km',
      ),
      SportMetricData(
        iconAsset: AppMetricAssets.calories,
        color: AppColors.accentOrange,
        title: '卡路里',
        value: _formatInt(caloriesKcal.round()),
        unit: 'kcal',
      ),
      SportMetricData(
        iconAsset: AppMetricAssets.activeTime,
        color: AppColors.accentCyan,
        title: '活动时间',
        value: _formatInt(activeMinutes),
        unit: 'min',
      ),
    ];
  }

  /// 日维度分析：当日卡路里 / 活动时间，并与前一日对比（较昨日）。
  List<SportAnalysisData> _dayAnalyses() {
    final sorted = _sorted;
    final latest = _latest;
    HealthDailySummary? previous;
    for (var i = sorted.length - 1; i >= 0; i--) {
      if (sorted[i].date.isBefore(_dateOnly(latest.date))) {
        previous = sorted[i];
        break;
      }
    }
    final recent = sorted.length <= 7
        ? sorted
        : sorted.sublist(sorted.length - 7);
    return [
      SportAnalysisData(
        assetIcon: AppMetricAssets.calories,
        color: AppColors.accentOrange,
        title: '卡路里分析',
        value: _formatInt(latest.caloriesKcal.round()),
        unit: 'kcal',
        delta: _deltaVsYesterday(latest.caloriesKcal, previous?.caloriesKcal),
        samples: _normalizedSamples(recent.map((item) => item.caloriesKcal)),
      ),
      SportAnalysisData(
        assetIcon: AppMetricAssets.activeTime,
        color: AppColors.accentCyan,
        title: '活动时间分析',
        value: _formatInt(latest.activeMinutes),
        unit: 'min',
        delta: _deltaVsYesterday(
          latest.activeMinutes.toDouble(),
          previous?.activeMinutes.toDouble(),
        ),
        samples: _normalizedSamples(
          recent.map((item) => item.activeMinutes.toDouble()),
        ),
      ),
    ];
  }

  List<SportAnalysisData> _periodAnalyses(
    List<HealthDailySummary> items,
    String delta,
  ) {
    final calories = items.fold<double>(
      0,
      (sum, item) => sum + item.caloriesKcal,
    );
    final minutes = items.fold<int>(0, (sum, item) => sum + item.activeMinutes);
    return [
      SportAnalysisData(
        assetIcon: AppMetricAssets.calories,
        color: AppColors.accentOrange,
        title: '卡路里分析',
        value: _formatInt(calories.round()),
        unit: 'kcal',
        delta: delta,
        samples: _normalizedSamples(items.map((item) => item.caloriesKcal)),
      ),
      SportAnalysisData(
        assetIcon: AppMetricAssets.activeTime,
        color: AppColors.accentCyan,
        title: '活动时间分析',
        value: _formatInt(minutes),
        unit: 'min',
        delta: delta,
        samples: _normalizedSamples(
          items.map((item) => item.activeMinutes.toDouble()),
        ),
      ),
    ];
  }
}

int _sumInt(Iterable<int> values) {
  return values.fold<int>(0, (sum, value) => sum + value);
}

String _sourceTitle(HealthSyncSource source) {
  return switch (source) {
    HealthSyncSource.appleHealth => 'Apple Health',
    HealthSyncSource.healthConnect => 'Health Connect',
    HealthSyncSource.motionSensor => '运动传感器',
  };
}

List<TrendPoint> _mockHomeTrend() {
  return _homeTrendEndingToday(_mockDailySummariesEndingToday());
}

List<HealthDailySummary> _mockDailySummariesEndingToday() {
  const values = [4500, 6600, 4200, 8000, 6500, 4100, 7200];
  final today = _dateOnly(DateTime.now());
  return [
    for (var i = 0; i < values.length; i++)
      HealthDailySummary(
        date: today.subtract(Duration(days: values.length - 1 - i)),
        steps: values[i],
        distanceKm: 0,
        caloriesKcal: 0,
        activeMinutes: 0,
        source: HealthSyncSource.appleHealth,
      ),
  ];
}

List<TrendPoint> _homeTrendEndingToday(List<HealthDailySummary> summaries) {
  final byDate = {
    for (final summary in summaries) _dateOnly(summary.date): summary.steps,
  };
  final today = _dateOnly(DateTime.now());
  return [
    for (var i = 0; i < 7; i++)
      () {
        final date = today.subtract(Duration(days: 6 - i));
        return TrendPoint(
          label: _weekdayLabel(date),
          value: (byDate[date] ?? 0).toDouble(),
          highlight: i == 6,
        );
      }(),
  ];
}

List<WeeklyStepData> _weeklyTrendForCurrentWeek(
  List<HealthDailySummary> summaries, {
  DateTime? today,
}) {
  final currentDay = _dateOnly(today ?? DateTime.now());
  final weekStart = _weekMonday(currentDay);
  final stepsByDate = <DateTime, int>{};
  for (final summary in summaries) {
    final date = _dateOnly(summary.date);
    if (date.isBefore(weekStart) || date.isAfter(currentDay)) continue;
    stepsByDate.update(
      date,
      (steps) => steps + summary.steps,
      ifAbsent: () => summary.steps,
    );
  }
  return [
    for (var i = 0; i < 7; i++)
      () {
        final date = weekStart.add(Duration(days: i));
        return WeeklyStepData(
          _weekdayLabel(date),
          date.isAfter(currentDay) ? 0 : stepsByDate[date] ?? 0,
        );
      }(),
  ];
}

String _formatDecimal(double value) {
  final rounded = value.toStringAsFixed(1);
  return rounded.endsWith('.0')
      ? rounded.substring(0, rounded.length - 2)
      : rounded;
}

/// 生成「较昨日 ±X%」文案；昨日无数据时返回「较昨日 --」。
String _deltaVsYesterday(double today, double? yesterday) {
  if (yesterday == null || yesterday <= 0) return '较昨日 --';
  final percent = ((today - yesterday) / yesterday * 100).round();
  final sign = percent >= 0 ? '+' : '';
  return '较昨日 $sign$percent%';
}

String _formatInt(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

String _weekdayLabel(DateTime date) {
  const labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  return labels[date.weekday - 1];
}

String _dateTitle(DateTime date) {
  const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  return '${date.month}月${date.day}日 ${labels[date.weekday - 1]}';
}

String _shortDate(DateTime date) => '${date.month}月${date.day}日';

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String _hourlyLabelFor(DateTime date) {
  final today = _dateOnly(DateTime.now());
  final day = _dateOnly(date);
  if (day.isBefore(today)) return '24:00';
  final now = DateTime.now();
  final hour = now.hour.toString().padLeft(2, '0');
  final minute = now.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

DateTime _weekMonday(DateTime date) =>
    _dateOnly(date).subtract(Duration(days: date.weekday - 1));

double _numericHealthValue(HealthDataPoint point) {
  final value = point.value;
  if (value is NumericHealthValue) {
    return value.numericValue.toDouble();
  }
  return 0;
}

String _bestDayText(List<HealthDailySummary> items) {
  if (items.isEmpty) return '暂无数据';
  final best = items.reduce((a, b) => a.steps >= b.steps ? a : b);
  return '${_shortDate(best.date)} · ${_formatInt(best.steps)} 步';
}

List<double> _normalizedSamples(Iterable<double> values) {
  final list = values.toList();
  if (list.isEmpty) return const [0];
  final maxValue = list.reduce((a, b) => a > b ? a : b);
  if (maxValue <= 0) return List<double>.filled(list.length, 0);
  return [for (final value in list) (value / maxValue).clamp(0.0, 1.0)];
}
