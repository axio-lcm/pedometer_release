import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_icon_source.dart';
import 'package:pedometer/common/config/app_metric_assets.dart';
import 'package:pedometer/common/config/localized_text.dart';
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

  /// [weekOffset]：0 = 本周，-1 = 上周，依此类推（周视图用）。
  /// [monthOffset]：0 = 本月，-1 = 上月，依此类推（月视图用）。
  SportPeriodData sportPeriodData(
    SportPeriod period, {
    int weekOffset = 0,
    int monthOffset = 0,
  });
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

  SportPeriodData sportPeriodData(
    SportPeriod period, {
    int weekOffset = 0,
    int monthOffset = 0,
  }) {
    return _activeDataSource.sportPeriodData(
      period,
      weekOffset: weekOffset,
      monthOffset: monthOffset,
    );
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

  static HealthDataSource? get activeDataSource =>
      _realDataSource ?? _motionSensorDataSource;

  static bool get hasActiveDataSource => activeDataSource != null;

  static bool get hasRealDataSource => _realDataSource != null;

  static HealthDailySummary? get latestSummary {
    final source = activeDataSource;
    if (source is SyncedHealthDataSource) return source.latestSummary;
    return null;
  }

  static List<HealthDailySummary> get activeSummaries {
    final source = activeDataSource;
    if (source is SyncedHealthDataSource) return source.sortedSummaries;
    return const [];
  }

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

/// 单次同步事件的快照：列表与详情页都基于它渲染，确保每条历史展示自己的数据。
class SyncHistoryEntry {
  final String id;
  final DateTime time;
  final HealthSyncSource source;
  final String mode; // '手动同步' / '自动同步'
  final int itemCount; // 本次实际同步的数据项数量
  final HealthDailySummary snapshot; // 本次同步的当日数据快照
  final Duration elapsed; // 本次同步耗时

  const SyncHistoryEntry({
    required this.id,
    required this.time,
    required this.source,
    required this.mode,
    required this.itemCount,
    required this.snapshot,
    required this.elapsed,
  });
}

/// 同步历史存储：每次成功同步追加一条记录，供同步详情/历史列表/历史详情读取。
///
/// 进程内内存存储（重启后清空）；变更通过 [revision] 通知监听的 view model 刷新。
class HealthSyncHistory {
  HealthSyncHistory._();

  static final ValueNotifier<int> revision = ValueNotifier<int>(0);
  static final List<SyncHistoryEntry> _entries = <SyncHistoryEntry>[];

  /// 全部记录，按时间倒序（最新在前）。
  static List<SyncHistoryEntry> get entries =>
      List<SyncHistoryEntry>.unmodifiable(_entries.reversed);

  static bool get isEmpty => _entries.isEmpty;

  /// 按 id 回查某条记录；找不到返回 null。
  static SyncHistoryEntry? entryById(String id) {
    for (final entry in _entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  static void record(SyncHistoryEntry entry) {
    _entries.add(entry);
    revision.value++;
  }

  static void resetForTest() {
    _entries.clear();
    revision.value++;
  }
}

class RuntimeHealthDataSource implements HealthDataSource {
  final HealthDataSource fallback;

  const RuntimeHealthDataSource({required this.fallback});

  HealthDataSource get _current => HealthSyncRuntime.dataSourceOr(fallback);

  @override
  HealthHomeSnapshot homeSnapshot() => _current.homeSnapshot();

  @override
  SportPeriodData sportPeriodData(
    SportPeriod period, {
    int weekOffset = 0,
    int monthOffset = 0,
  }) {
    return _current.sportPeriodData(
      period,
      weekOffset: weekOffset,
      monthOffset: monthOffset,
    );
  }
}

class MockHealthDataSource implements HealthDataSource {
  const MockHealthDataSource();

  @override
  HealthHomeSnapshot homeSnapshot() {
    return HealthHomeSnapshot(
      step: const StepData(steps: 5276, goal: 6000),
      kpis: [
        KpiItem(
          assetIcon: AppMetricAssets.distance,
          title: lt('Distance', '距离'),
          value: '1.6',
          unit: 'km',
        ),
        KpiItem(
          assetIcon: AppMetricAssets.calories,
          title: lt('Calories', '卡路里'),
          value: '293',
          unit: 'kcal',
        ),
        KpiItem(
          assetIcon: AppMetricAssets.activeTime,
          title: lt('Time', '时间'),
          value: '28',
          unit: 'min',
        ),
      ],
      trend: _mockHomeTrend(),
      analyses: [
        AnalysisData(
          title: lt('Calories', '卡路里'),
          assetIcon: AppMetricAssets.calories,
          value: '293',
          unit: 'kcal',
          delta: lt('vs yesterday +12%', '较昨日 +12%'),
          color: AppColors.accentOrange,
          samples: const [0.30, 0.45, 0.38, 0.60, 0.55, 0.78, 0.92],
        ),
        AnalysisData(
          title: lt('Time', '时间'),
          assetIcon: AppMetricAssets.activeTime,
          value: '28',
          unit: 'min',
          delta: lt('vs yesterday +8%', '较昨日 +8%'),
          color: AppColors.accentCyan,
          samples: const [0.40, 0.35, 0.55, 0.50, 0.70, 0.66, 0.88],
        ),
      ],
    );
  }

  @override
  SportPeriodData sportPeriodData(
    SportPeriod period, {
    int weekOffset = 0,
    int monthOffset = 0,
  }) {
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

  /// 快速同步（第一阶段）：读取原始样本并按天聚合后立即返回，供界面秒级展示。
  ///
  /// 此处步数为多源样本「求和」，可能偏大；精确去重交给后台的 [refineSteps]，
  /// 避免逐天去重的耗时把界面长时间卡在「同步中」。返回值同时带回原始样本，
  /// 供后台精修复用，免去二次读取。
  Future<({SyncedHealthDataSource source, List<HealthDataPoint> points})> sync({
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
      return (
        source: const SyncedHealthDataSource(summaries: []),
        points: const <HealthDataPoint>[],
      );
    }
    final healthTypes = _healthTypesFor(source: source, types: types);

    var points = <HealthDataPoint>[];
    for (var attempt = 0; attempt <= readRetries; attempt++) {
      points = await health
          .getHealthDataFromTypes(
            types: healthTypes,
            startTime: startDate,
            endTime: endDate,
          )
          // 读取挂起时不再无限等待：超时按空结果处理，触发重试后再决定成败。
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () => <HealthDataPoint>[],
          );
      if (points.isNotEmpty) break;
      if (attempt < readRetries) {
        await Future<void>.delayed(retryDelay);
      }
    }

    return (
      source: SyncedHealthDataSource(
        summaries: _dailySummariesFromPoints(
          points,
          source: source,
          startDate: startDate,
          endDate: endDate,
        ),
      ),
      points: points,
    );
  }

  /// 后台精修（第二阶段）：对 [points] 逐天去重步数，返回步数校正后的数据源。
  ///
  /// iOS 的原始步数样本会因 iPhone / Apple Watch / 第三方 App 多来源记录而重叠，
  /// 直接求和会重复计数（「健康」App 显示 2750，求和却得 5449）。这里对每个有步数
  /// 的自然日改用 getTotalStepsInInterval（原生 HKStatisticsQuery 累计求和，
  /// 与「健康」App 同一套去重逻辑）得到真实步数。耗时较长，应在后台调用。
  Future<SyncedHealthDataSource> refineSteps({
    required List<HealthDataPoint> points,
    required HealthSyncSource source,
    required DateTime startDate,
    required DateTime endDate,
    Duration budget = const Duration(minutes: 5),
  }) async {
    final stepsOverride = await _accurateDailySteps(
      points,
      startDate: startDate,
      endDate: endDate,
      budget: budget,
    );
    return SyncedHealthDataSource(
      summaries: _dailySummariesFromPoints(
        points,
        source: source,
        startDate: startDate,
        endDate: endDate,
        stepsOverride: stepsOverride,
      ),
    );
  }

  /// 对 [points] 中出现过步数样本的每个自然日，调用原生去重步数统计，
  /// 返回「自然日 → 去重后步数」。失败的日期不写入（回退到求和值）。
  ///
  /// 仅遍历真正有步数的日期，避免对无数据的空日做无谓的原生调用；
  /// 为缩短全量历史的同步时长，按小批量并发查询。
  Future<Map<DateTime, int>> _accurateDailySteps(
    List<HealthDataPoint> points, {
    required DateTime startDate,
    required DateTime endDate,
    Duration budget = const Duration(seconds: 45),
  }) async {
    final lower = _dateOnly(startDate);
    final upper = _dateOnly(endDate);
    final days = <DateTime>{};
    for (final point in points) {
      if (point.type != HealthDataType.STEPS) continue;
      final day = _dateOnly(point.dateFrom.toLocal());
      if (day.isBefore(lower) || day.isAfter(upper)) continue;
      days.add(day);
    }

    final result = <DateTime, int>{};
    const batchSize = 12;
    // 最近的日期最常被查看，优先去重；超出时间预算后剩余日期回退到求和值。
    final dayList = days.toList()..sort((a, b) => b.compareTo(a));
    // 全量历史可能有成百上千个活跃日，逐天原生查询既慢又可能因 method channel
    // 高并发丢应答而永远挂起。给整体一个时间预算 + 给每次调用一个超时，
    // 确保本方法一定在有限时间内返回，杜绝同步永远卡在「同步中」。
    final deadline = DateTime.now().add(budget);
    for (var i = 0; i < dayList.length; i += batchSize) {
      if (DateTime.now().isAfter(deadline)) break;
      final batch = dayList.sublist(i, math.min(i + batchSize, dayList.length));
      await Future.wait([
        for (final day in batch)
          () async {
            try {
              final total = await health
                  .getTotalStepsInInterval(
                    day,
                    day.add(const Duration(days: 1)),
                  )
                  .timeout(const Duration(seconds: 6));
              if (total != null) result[day] = total;
            } catch (_) {
              // 单日失败 / 超时则跳过，回退到原始求和值。
            }
          }(),
      ]);
    }
    return result;
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
    // 「自然日 → 去重后步数」。非空时步数用此覆盖，不再累加原始样本。
    Map<DateTime, int>? stepsOverride,
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
          // 仍累加原始样本作为兜底；若 stepsOverride 有当天去重值则优先用之，
          // 仅当个别日期去重查询失败时才回退到这个（可能偏大的）求和值。
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
          steps: stepsOverride?[entry.key] ?? entry.value.steps,
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

  HealthDailySummary get latestSummary => _latest;

  List<HealthDailySummary> get sortedSummaries => _sorted;

  @override
  HealthHomeSnapshot homeSnapshot() {
    final latest = _latest;
    final sorted = _sorted;
    final recent = sorted.length <= 7
        ? sorted
        : sorted.sublist(sorted.length - 7);
    // 最近一天之前、有数据的上一天，用于「较昨日」对比。
    HealthDailySummary? previous;
    for (var i = sorted.length - 1; i >= 0; i--) {
      if (sorted[i].date.isBefore(_dateOnly(latest.date))) {
        previous = sorted[i];
        break;
      }
    }

    return HealthHomeSnapshot(
      step: StepData(steps: latest.steps, goal: 6000),
      kpis: [
        KpiItem(
          assetIcon: AppMetricAssets.distance,
          title: lt('Distance', '距离'),
          value: _formatDecimal(latest.distanceKm),
          unit: 'km',
        ),
        KpiItem(
          assetIcon: AppMetricAssets.calories,
          title: lt('Calories', '卡路里'),
          value: _formatInt(latest.caloriesKcal.round()),
          unit: 'kcal',
        ),
        KpiItem(
          assetIcon: AppMetricAssets.activeTime,
          title: lt('Time', '时间'),
          value: _formatInt(latest.activeMinutes),
          unit: 'min',
        ),
      ],
      trend: _homeTrendEndingToday(_sorted),
      analyses: [
        AnalysisData(
          title: lt('Calories', '卡路里'),
          assetIcon: AppMetricAssets.calories,
          value: _formatInt(latest.caloriesKcal.round()),
          unit: 'kcal',
          delta: _deltaVsYesterday(latest.caloriesKcal, previous?.caloriesKcal),
          color: AppColors.accentOrange,
          samples: _normalizedSamples(recent.map((item) => item.caloriesKcal)),
        ),
        AnalysisData(
          title: lt('Time', '时间'),
          assetIcon: AppMetricAssets.activeTime,
          value: _formatInt(latest.activeMinutes),
          unit: 'min',
          delta: _deltaVsYesterday(
            latest.activeMinutes.toDouble(),
            previous?.activeMinutes.toDouble(),
          ),
          color: AppColors.accentCyan,
          samples: _normalizedSamples(
            recent.map((item) => item.activeMinutes.toDouble()),
          ),
        ),
      ],
    );
  }

  @override
  SportPeriodData sportPeriodData(
    SportPeriod period, {
    int weekOffset = 0,
    int monthOffset = 0,
  }) {
    return switch (period) {
      SportPeriod.day => _dayData(),
      SportPeriod.week => _weekData(weekOffset),
      SportPeriod.month => _monthData(monthOffset),
    };
  }

  SportPeriodData _dayData() {
    final latest = _latest;
    return SportPeriodData(
      period: SportPeriod.day,
      dateTitle: _dateTitle(latest.date),
      progress: SportProgressData(
        title: lt('Today', '今日'),
        value: latest.steps,
        goal: 6000,
        goalUnit: lt('steps', '步'),
        badgePrefix: lt('Achieved', '达成'),
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
        icon: const AssetAppIcon(AppMetricAssets.todaySummary),
        color: AppColors.brandGreen,
        title: lt('Today\'s Summary', '今日总结'),
        primary: lt('Today:', '今日：'),
        highlight: lt(
          '${_formatInt(latest.steps)} steps',
          '${_formatInt(latest.steps)} 步',
        ),
        secondary: lt(
          'Distance, calories, and active time have been updated',
          '距离、卡路里和活动时长已更新',
        ),
        assetName: lt('synced health data', '已同步健康数据'),
      ),
    );
  }

  SportPeriodData _weekData(int weekOffset) {
    final sorted = _sorted;
    final today = _dateOnly(DateTime.now());
    final weekStart = _weekMonday(today).add(Duration(days: weekOffset * 7));
    final weekEnd = weekStart.add(const Duration(days: 6));
    // 本周只统计到今天；过去的周整周都已结束，统计到周日。
    final referenceDay = weekOffset >= 0 ? today : weekEnd;
    final elapsedDays = referenceDay.difference(weekStart).inDays + 1;
    final currentWeekItems = sorted.where((item) {
      final date = _dateOnly(item.date);
      return !date.isBefore(weekStart) && !date.isAfter(referenceDay);
    }).toList();
    // 上一周同区间（相同已过天数），用于「较上周」对比。
    final prevWeekStart = weekStart.subtract(const Duration(days: 7));
    final prevWeekEnd = referenceDay.subtract(const Duration(days: 7));
    final previousWeekItems = sorted.where((item) {
      final date = _dateOnly(item.date);
      return !date.isBefore(prevWeekStart) && !date.isAfter(prevWeekEnd);
    }).toList();
    final weeklyTrend = _weeklyTrendForCurrentWeek(sorted, today: referenceDay);
    final steps = _sumInt(weeklyTrend.map((item) => item.steps));
    final activeDays = weeklyTrend.where((item) => item.steps > 0).length;
    final goalDays = weeklyTrend.where((item) => item.steps >= 6000).length;

    return SportPeriodData(
      period: SportPeriod.week,
      dateTitle: '${_shortDate(weekStart)} - ${_shortDate(weekEnd)}',
      progress: SportProgressData(
        title: lt('This Week', '本周'),
        value: steps,
        goal: 42000,
        goalUnit: lt('Goal', '目标'),
        badgePrefix: lt('Completed', '完成'),
      ),
      metrics: [
        SportMetricData(
          iconAsset: AppMetricAssets.dayAverage,
          color: AppColors.accentCyan,
          title: lt('Daily Avg', '日均步数'),
          value: _formatInt(
            elapsedDays <= 0 ? 0 : (steps / elapsedDays).round(),
          ),
          unit: lt('steps', '步'),
        ),
        SportMetricData(
          iconAsset: AppMetricAssets.activeDays,
          color: AppColors.accentOrange,
          title: lt('Active Days', '活跃天数'),
          value: '$activeDays / 7',
          unit: lt('days', '天'),
        ),
        SportMetricData(
          iconAsset: AppMetricAssets.targetMet,
          color: AppColors.accentPurple,
          title: lt('Goal Days', '达标天数'),
          value: '$goalDays',
          unit: lt('days', '天'),
        ),
      ],
      weekly: weeklyTrend,
      analyses: _periodAnalyses(
        currentWeekItems,
        previousWeekItems,
        lt('vs last week', '较上周'),
      ),
      summary: SportSummaryData(
        icon: const AssetAppIcon(AppMetricAssets.weekSummary),
        color: AppColors.brandGreen,
        title: lt('Weekly Summary', '本周总结'),
        primary: lt('Highest steps:', '最高步数：'),
        highlight: _bestDayText(currentWeekItems),
        secondary: lt(
          'Synced $activeDays days of health data this week',
          '本周已同步 $activeDays 天健康数据',
        ),
        assetName: lt('synced weekly health data', '已同步周健康数据'),
      ),
    );
  }

  SportPeriodData _monthData(int monthOffset) {
    final sorted = _sorted;
    final now = DateTime.now();
    final anchor = DateTime(now.year, now.month + monthOffset, 1);
    final monthItems = sorted
        .where(
          (item) =>
              item.date.year == anchor.year && item.date.month == anchor.month,
        )
        .toList();
    final steps = _sumInt(monthItems.map((item) => item.steps));
    final goalDays = monthItems.where((item) => item.steps >= 6000).length;
    // 上一月同区间（本月只到今天，过去月为整月），用于「较上月」对比。
    final isCurrentMonth = anchor.year == now.year && anchor.month == now.month;
    final dayBound = isCurrentMonth ? now.day : 31;
    final prevAnchor = DateTime(anchor.year, anchor.month - 1, 1);
    final previousMonthItems = sorted
        .where(
          (item) =>
              item.date.year == prevAnchor.year &&
              item.date.month == prevAnchor.month &&
              item.date.day <= dayBound,
        )
        .toList();

    return SportPeriodData(
      period: SportPeriod.month,
      dateTitle: localizedMonthTitle(anchor),
      progress: SportProgressData(
        title: lt('This Month', '本月'),
        value: steps,
        goal: 180000,
        goalUnit: lt('Goal', '目标'),
        badgePrefix: lt('Completed', '完成'),
      ),
      metrics: [
        SportMetricData(
          iconAsset: AppMetricAssets.monthDailyAverage,
          color: AppColors.brandGreen,
          title: lt('Daily Avg', '日均步数'),
          value: _formatInt(
            monthItems.isEmpty ? 0 : (steps / monthItems.length).round(),
          ),
          unit: lt('steps', '步'),
        ),
        SportMetricData(
          iconAsset: AppMetricAssets.monthTargetMet,
          color: AppColors.accentCyan,
          title: lt('Goal Days', '达标天数'),
          value: '$goalDays',
          unit: lt('days', '天'),
        ),
        SportMetricData(
          iconAsset: AppMetricAssets.monthTotalDistance,
          color: AppColors.accentPurple,
          title: lt('Total Distance', '总距离'),
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
      analyses: _periodAnalyses(
        monthItems,
        previousMonthItems,
        lt('vs last month', '较上月'),
      ),
      summary: SportSummaryData(
        icon: const AssetAppIcon(AppMetricAssets.monthSummary),
        color: AppColors.brandGreen,
        title: lt('Monthly Summary', '本月总结'),
        primary: lt('Best Day:', '最佳单日：'),
        highlight: _bestDayText(monthItems),
        secondary: lt(
          'Synced ${monthItems.length} days of health data this month',
          '本月已同步 ${monthItems.length} 天健康数据',
        ),
        assetName: lt('synced monthly health data', '已同步月健康数据'),
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
        title: lt('Distance', '距离'),
        value: _formatDecimal(distanceKm),
        unit: 'km',
      ),
      SportMetricData(
        iconAsset: AppMetricAssets.calories,
        color: AppColors.accentOrange,
        title: lt('Calories', '卡路里'),
        value: _formatInt(caloriesKcal.round()),
        unit: 'kcal',
      ),
      SportMetricData(
        iconAsset: AppMetricAssets.activeTime,
        color: AppColors.accentCyan,
        title: lt('Time', '时间'),
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
        title: lt('Calories', '卡路里'),
        value: _formatInt(latest.caloriesKcal.round()),
        unit: 'kcal',
        delta: _deltaVsYesterday(latest.caloriesKcal, previous?.caloriesKcal),
        samples: _normalizedSamples(recent.map((item) => item.caloriesKcal)),
      ),
      SportAnalysisData(
        assetIcon: AppMetricAssets.activeTime,
        color: AppColors.accentCyan,
        title: lt('Time', '时间'),
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

  /// 周 / 月维度分析：卡路里与活动时间合计，并与上一周期同区间对比。
  /// [compareLabel] 取「较上周」或「较上月」。
  List<SportAnalysisData> _periodAnalyses(
    List<HealthDailySummary> items,
    List<HealthDailySummary> previousItems,
    String compareLabel,
  ) {
    final calories = items.fold<double>(
      0,
      (sum, item) => sum + item.caloriesKcal,
    );
    final minutes = items.fold<int>(0, (sum, item) => sum + item.activeMinutes);
    final prevCalories = previousItems.fold<double>(
      0,
      (sum, item) => sum + item.caloriesKcal,
    );
    final prevMinutes = previousItems.fold<int>(
      0,
      (sum, item) => sum + item.activeMinutes,
    );
    return [
      SportAnalysisData(
        assetIcon: AppMetricAssets.calories,
        color: AppColors.accentOrange,
        title: lt('Calories', '卡路里'),
        value: _formatInt(calories.round()),
        unit: 'kcal',
        delta: _deltaVsPrevious(compareLabel, calories, prevCalories),
        samples: _normalizedSamples(items.map((item) => item.caloriesKcal)),
      ),
      SportAnalysisData(
        assetIcon: AppMetricAssets.activeTime,
        color: AppColors.accentCyan,
        title: lt('Time', '时间'),
        value: _formatInt(minutes),
        unit: 'min',
        delta: _deltaVsPrevious(
          compareLabel,
          minutes.toDouble(),
          prevMinutes.toDouble(),
        ),
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
  final label = lt('vs yesterday', '较昨日');
  if (yesterday == null || yesterday <= 0) return '$label --';
  final percent = ((today - yesterday) / yesterday * 100).round();
  final sign = percent >= 0 ? '+' : '';
  return '$label $sign$percent%';
}

/// 生成「较上周/较上月 ±X%」文案；上一周期无数据时返回「$label --」。
String _deltaVsPrevious(String label, double current, double? previous) {
  if (previous == null || previous <= 0) return '$label --';
  final percent = ((current - previous) / previous * 100).round();
  final sign = percent >= 0 ? '+' : '';
  return '$label $sign$percent%';
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
  const enLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  const zhLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  return (isZhLocale ? zhLabels : enLabels)[date.weekday - 1];
}

String _dateTitle(DateTime date) {
  return localizedDayTitle(date);
}

String _shortDate(DateTime date) => localizedShortDate(date);

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
  if (items.isEmpty) return lt('No data', '暂无数据');
  final best = items.reduce((a, b) => a.steps >= b.steps ? a : b);
  return lt(
    '${_shortDate(best.date)} · ${_formatInt(best.steps)} steps',
    '${_shortDate(best.date)} · ${_formatInt(best.steps)} 步',
  );
}

List<double> _normalizedSamples(Iterable<double> values) {
  final list = values.toList();
  if (list.isEmpty) return const [0];
  final maxValue = list.reduce((a, b) => a > b ? a : b);
  if (maxValue <= 0) return List<double>.filled(list.length, 0);
  return [for (final value in list) (value / maxValue).clamp(0.0, 1.0)];
}
