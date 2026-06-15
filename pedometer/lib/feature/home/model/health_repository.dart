import 'package:flutter/material.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/feature/home/model/home_model.dart';
import 'package:pedometer/feature/home/model/sport_detail_model.dart';
import 'package:pedometer_health/pedometer_health.dart';

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
  static HealthDataSource? _realDataSource;

  HealthSyncRuntime._();

  static HealthDataSource dataSourceOr(HealthDataSource fallback) {
    return _realDataSource ?? fallback;
  }

  static void replaceRealDataSource(HealthDataSource dataSource) {
    _realDataSource = dataSource;
    revision.value++;
  }

  static void resetForTest() {
    _realDataSource = null;
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
          icon: Icons.place_rounded,
          color: Color(0xFF7A3DFF),
          title: '距离',
          value: '1.6',
          unit: 'km',
        ),
        KpiItem(
          icon: Icons.local_fire_department_rounded,
          color: Color(0xFFFF9F12),
          title: '卡路里',
          value: '293',
          unit: 'kcal',
        ),
        KpiItem(
          icon: Icons.timer_rounded,
          color: Color(0xFF0CD9FF),
          title: '活动时间',
          value: '28',
          unit: 'min',
        ),
      ],
      trend: const [
        TrendPoint(label: 'WED', value: 4500),
        TrendPoint(label: 'THU', value: 6600),
        TrendPoint(label: 'FRI', value: 4200),
        TrendPoint(label: 'SAT', value: 8000),
        TrendPoint(label: 'SUN', value: 6500),
        TrendPoint(label: 'MON', value: 4100),
        TrendPoint(label: 'TUE', value: 7200, highlight: true),
      ],
      analyses: [
        AnalysisData(
          title: '卡路里分析',
          value: '293',
          unit: 'kcal',
          delta: '较昨日 +12%',
          color: AppColors.accentOrange,
          samples: const [0.30, 0.45, 0.38, 0.60, 0.55, 0.78, 0.92],
        ),
        AnalysisData(
          title: '活动时间分析',
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
    return SportDetailFixtures.byPeriod(period);
  }
}

class HealthPluginSyncService {
  final PedometerHealthClient client;

  const HealthPluginSyncService({required this.client});

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
  }) async {
    final summaries = await client.fetchDailySummaries(
      source: source,
      startDate: startDate,
      endDate: endDate,
      types: types,
    );
    return SyncedHealthDataSource(summaries: summaries);
  }
}

class SyncedHealthDataSource implements HealthDataSource {
  final List<HealthDailySummary> summaries;

  const SyncedHealthDataSource({required this.summaries});

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
          icon: Icons.place_rounded,
          color: AppColors.accentPurple,
          title: '距离',
          value: _formatDecimal(latest.distanceKm),
          unit: 'km',
        ),
        KpiItem(
          icon: Icons.local_fire_department_rounded,
          color: AppColors.accentOrange,
          title: '卡路里',
          value: _formatInt(latest.caloriesKcal.round()),
          unit: 'kcal',
        ),
        KpiItem(
          icon: Icons.timer_rounded,
          color: AppColors.accentCyan,
          title: '活动时间',
          value: _formatInt(latest.activeMinutes),
          unit: 'min',
        ),
      ],
      trend: [
        for (var i = 0; i < recent.length; i++)
          TrendPoint(
            label: _weekdayLabel(recent[i].date),
            value: recent[i].steps.toDouble(),
            highlight: i == recent.length - 1,
          ),
      ],
      analyses: [
        AnalysisData(
          title: '卡路里分析',
          value: _formatInt(latest.caloriesKcal.round()),
          unit: 'kcal',
          delta: '来自健康同步',
          color: AppColors.accentOrange,
          samples: _normalizedSamples(recent.map((item) => item.caloriesKcal)),
        ),
        AnalysisData(
          title: '活动时间分析',
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
      hourly: [HourlyStepData('24:00', latest.steps)],
      segments: const [],
      summary: SportSummaryData(
        icon: Icons.verified_rounded,
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
    final recent = _sorted.length <= 7
        ? _sorted
        : _sorted.sublist(_sorted.length - 7);
    final steps = _sumInt(recent.map((item) => item.steps));
    final activeDays = recent.where((item) => item.steps > 0).length;
    final goalDays = recent.where((item) => item.steps >= 6000).length;

    return SportPeriodData(
      period: SportPeriod.week,
      dateTitle: recent.isEmpty
          ? '本周'
          : '${_shortDate(recent.first.date)} - ${_shortDate(recent.last.date)}',
      progress: SportProgressData(
        title: '本周步数',
        value: steps,
        goal: 42000,
        goalUnit: '目标',
        badgePrefix: '完成',
      ),
      metrics: [
        SportMetricData(
          icon: Icons.timer_rounded,
          color: AppColors.accentCyan,
          title: '日均',
          value: _formatInt(
            recent.isEmpty ? 0 : (steps / recent.length).round(),
          ),
          unit: '步',
        ),
        SportMetricData(
          icon: Icons.local_fire_department_rounded,
          color: AppColors.accentOrange,
          title: '活跃天数',
          value: '$activeDays / 7',
          unit: '天',
        ),
        SportMetricData(
          icon: Icons.gps_fixed_rounded,
          color: AppColors.accentPurple,
          title: '达标天数',
          value: '$goalDays',
          unit: '天',
        ),
      ],
      weekly: [
        for (final item in recent)
          WeeklyStepData(_weekdayLabel(item.date), item.steps),
      ],
      analyses: _periodAnalyses(recent, '来自健康同步'),
      summary: SportSummaryData(
        icon: Icons.emoji_events_rounded,
        color: AppColors.brandGreen,
        title: '周总结',
        primary: '最高步数：',
        highlight: _bestDayText(recent),
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
          icon: Icons.directions_walk_rounded,
          color: AppColors.brandGreen,
          title: '日均',
          value: _formatInt(
            monthItems.isEmpty ? 0 : (steps / monthItems.length).round(),
          ),
          unit: '步',
        ),
        SportMetricData(
          icon: Icons.gps_fixed_rounded,
          color: AppColors.accentCyan,
          title: '达标天数',
          value: '$goalDays',
          unit: '天',
        ),
        SportMetricData(
          icon: Icons.place_rounded,
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
        icon: Icons.calendar_month_rounded,
        color: AppColors.brandGreen,
        title: '月度总结',
        primary: '最佳单日：',
        highlight: _bestDayText(monthItems),
        secondary: '本月已同步 ${monthItems.length} 天健康数据',
        assetName: 'synced monthly health data',
        showChevron: true,
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
        icon: Icons.place_rounded,
        color: AppColors.accentPurple,
        title: '距离',
        value: _formatDecimal(distanceKm),
        unit: 'km',
      ),
      SportMetricData(
        icon: Icons.local_fire_department_rounded,
        color: AppColors.accentOrange,
        title: '卡路里',
        value: _formatInt(caloriesKcal.round()),
        unit: 'kcal',
      ),
      SportMetricData(
        icon: Icons.timer_rounded,
        color: AppColors.accentCyan,
        title: '活动时间',
        value: _formatInt(activeMinutes),
        unit: 'min',
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
        icon: Icons.local_fire_department_rounded,
        color: AppColors.accentOrange,
        title: '卡路里分析',
        value: _formatInt(calories.round()),
        unit: 'kcal',
        delta: delta,
        samples: _normalizedSamples(items.map((item) => item.caloriesKcal)),
      ),
      SportAnalysisData(
        icon: Icons.timer_rounded,
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
  };
}

String _formatDecimal(double value) {
  final rounded = value.toStringAsFixed(1);
  return rounded.endsWith('.0')
      ? rounded.substring(0, rounded.length - 2)
      : rounded;
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
