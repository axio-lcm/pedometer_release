import 'package:flutter/material.dart';
import 'package:pedometer/common/config/app_colors.dart';

/// 运动详情周期。
enum SportPeriod { day, week, month }

/// 主圆环数据。
class SportProgressData {
  final String title;
  final int value;
  final int goal;
  final String goalUnit;
  final String badgePrefix;

  const SportProgressData({
    required this.title,
    required this.value,
    required this.goal,
    required this.goalUnit,
    required this.badgePrefix,
  });

  double get progress => goal <= 0 ? 0 : (value / goal).clamp(0.0, 1.05);
  int get percent => goal <= 0 ? 0 : (value / goal * 100).round().clamp(0, 100);
}

/// KPI 数据。
class SportMetricData {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String unit;

  const SportMetricData({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.unit,
  });
}

/// 每小时步数。
class HourlyStepData {
  final String label;
  final int steps;

  const HourlyStepData(this.label, this.steps);
}

/// 每周步数。
class WeeklyStepData {
  final String label;
  final int steps;

  const WeeklyStepData(this.label, this.steps);
}

/// 月热力日历单日数据。
class MonthlyDayData {
  final int day;
  final int steps;

  const MonthlyDayData(this.day, this.steps);
}

/// 活动时段。
class SportSegmentData {
  final IconData icon;
  final Color color;
  final String title;
  final String time;
  final String steps;

  const SportSegmentData({
    required this.icon,
    required this.color,
    required this.title,
    required this.time,
    required this.steps,
  });
}

/// 分析小卡数据。
class SportAnalysisData {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String unit;
  final String delta;
  final List<double> samples;

  const SportAnalysisData({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.unit,
    required this.delta,
    required this.samples,
  });
}

/// 总结/建议数据。
class SportSummaryData {
  final IconData icon;
  final Color color;
  final String title;
  final String primary;
  final String highlight;
  final String secondary;
  final String? actionLabel;
  final bool showChevron;
  final String assetName;

  const SportSummaryData({
    required this.icon,
    required this.color,
    required this.title,
    required this.primary,
    required this.highlight,
    required this.secondary,
    required this.assetName,
    this.actionLabel,
    this.showChevron = false,
  });
}

/// 单个周期页面所需全部展示数据。
class SportPeriodData {
  final SportPeriod period;
  final String dateTitle;
  final SportProgressData progress;
  final List<SportMetricData> metrics;
  final List<HourlyStepData> hourly;
  final List<WeeklyStepData> weekly;
  final List<MonthlyDayData> monthly;
  final List<SportSegmentData> segments;
  final List<SportAnalysisData> analyses;
  final SportSummaryData summary;

  const SportPeriodData({
    required this.period,
    required this.dateTitle,
    required this.progress,
    required this.metrics,
    this.hourly = const [],
    this.weekly = const [],
    this.monthly = const [],
    this.segments = const [],
    this.analyses = const [],
    required this.summary,
  });
}

/// 设计稿演示数据，后续可替换为真实运动/Health 数据源。
class SportDetailFixtures {
  SportDetailFixtures._();

  /// 当天日期标题，例如「6月10日 周二」，随系统日期实时变化。
  static String _todayTitle() {
    const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final now = DateTime.now();
    return '${now.month}月${now.day}日 ${labels[now.weekday - 1]}';
  }

  /// 指定周偏移的周一日期（0 = 本周，-1 = 上周，依此类推）。
  static DateTime weekMonday(int offset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: now.weekday - 1 - offset * 7));
  }

  /// 指定周偏移的日期范围标题，例如「6月15日 - 6月21日」，随系统日期实时变化。
  static String weekTitle({int offset = 0}) {
    final monday = weekMonday(offset);
    final sunday = monday.add(const Duration(days: 6));
    return '${monday.month}月${monday.day}日 - ${sunday.month}月${sunday.day}日';
  }

  static SportPeriodData byPeriod(SportPeriod period) {
    return switch (period) {
      SportPeriod.day => day,
      SportPeriod.week => week,
      SportPeriod.month => month,
    };
  }

  static SportPeriodData get day => SportPeriodData(
    period: SportPeriod.day,
    dateTitle: _todayTitle(),
    progress: const SportProgressData(
      title: '今日步数',
      value: 5276,
      goal: 6000,
      goalUnit: '步',
      badgePrefix: '达成',
    ),
    metrics: [
      SportMetricData(
        icon: Icons.place_rounded,
        color: AppColors.accentPurple,
        title: '距离',
        value: '1.6',
        unit: 'km',
      ),
      SportMetricData(
        icon: Icons.local_fire_department_rounded,
        color: AppColors.accentOrange,
        title: '卡路里',
        value: '293',
        unit: 'kcal',
      ),
      SportMetricData(
        icon: Icons.timer_rounded,
        color: AppColors.accentCyan,
        title: '活动时间',
        value: '28',
        unit: 'min',
      ),
    ],
    hourly: const [
      HourlyStepData('00:00', 80),
      HourlyStepData('02:00', 480),
      HourlyStepData('05:00', 900),
      HourlyStepData('07:00', 2900),
      HourlyStepData('09:00', 3200),
      HourlyStepData('12:00', 4210),
      HourlyStepData('14:00', 2600),
      HourlyStepData('17:00', 1800),
      HourlyStepData('21:00', 3450),
      HourlyStepData('23:00', 2200),
      HourlyStepData('24:00', 120),
    ],
    segments: [
      SportSegmentData(
        icon: Icons.wb_sunny_rounded,
        color: AppColors.brandGreen,
        title: '晨间步行',
        time: '07:30 - 08:10',
        steps: '1,280步',
      ),
      SportSegmentData(
        icon: Icons.light_mode_rounded,
        color: AppColors.accentOrange,
        title: '午间活动',
        time: '12:20 - 12:45',
        steps: '1,040步',
      ),
      SportSegmentData(
        icon: Icons.nights_stay_rounded,
        color: AppColors.accentPurple,
        title: '晚间散步',
        time: '19:10 - 19:35',
        steps: '1,360步',
      ),
    ],
    summary: SportSummaryData(
      icon: Icons.flag_rounded,
      color: AppColors.brandGreen,
      title: '目标建议',
      primary: '还差',
      highlight: '724',
      secondary: '步达成今日目标\n预计再步行 8 分钟可完成',
      actionLabel: '继续加油',
      assetName: '3D target recommendation',
    ),
  );

  static SportPeriodData get week => SportPeriodData(
    period: SportPeriod.week,
    dateTitle: weekTitle(),
    progress: const SportProgressData(
      title: '本周步数',
      value: 42380,
      goal: 42000,
      goalUnit: '目标',
      badgePrefix: '完成',
    ),
    metrics: [
      SportMetricData(
        icon: Icons.timer_rounded,
        color: AppColors.accentCyan,
        title: '日均',
        value: '6,054',
        unit: '步',
      ),
      SportMetricData(
        icon: Icons.local_fire_department_rounded,
        color: AppColors.accentOrange,
        title: '活跃天数',
        value: '6 / 7',
        unit: '天',
      ),
      SportMetricData(
        icon: Icons.gps_fixed_rounded,
        color: AppColors.accentPurple,
        title: '达标天数',
        value: '5',
        unit: '天',
      ),
    ],
    weekly: const [
      WeeklyStepData('MON', 4000),
      WeeklyStepData('TUE', 6100),
      WeeklyStepData('WED', 5200),
      WeeklyStepData('THU', 8000),
      WeeklyStepData('FRI', 5900),
      WeeklyStepData('SAT', 8200),
      WeeklyStepData('SUN', 4400),
    ],
    analyses: [
      SportAnalysisData(
        icon: Icons.local_fire_department_rounded,
        color: AppColors.accentOrange,
        title: '卡路里分析',
        value: '2,340',
        unit: 'kcal',
        delta: '较上周 +12%',
        samples: const [0.25, 0.42, 0.34, 0.55, 0.45, 0.64, 0.82],
      ),
      SportAnalysisData(
        icon: Icons.timer_rounded,
        color: AppColors.accentCyan,
        title: '活动时间分析',
        value: '3h 48',
        unit: 'min',
        delta: '较上周 +9%',
        samples: const [0.28, 0.47, 0.36, 0.60, 0.50, 0.70, 0.88],
      ),
    ],
    summary: SportSummaryData(
      icon: Icons.emoji_events_rounded,
      color: AppColors.brandGreen,
      title: '周总结',
      primary: '最佳表现：',
      highlight: '周六 8,200 步',
      secondary: '本周已连续 5 天达成目标',
      assetName: '3D weekly trophy',
    ),
  );

  static final SportPeriodData month = SportPeriodData(
    period: SportPeriod.month,
    dateTitle: '2026年6月',
    progress: const SportProgressData(
      title: '本月步数',
      value: 162500,
      goal: 180000,
      goalUnit: '目标',
      badgePrefix: '完成',
    ),
    metrics: [
      SportMetricData(
        icon: Icons.directions_walk_rounded,
        color: AppColors.brandGreen,
        title: '日均',
        value: '5,417',
        unit: '步',
      ),
      SportMetricData(
        icon: Icons.gps_fixed_rounded,
        color: AppColors.accentCyan,
        title: '达标天数',
        value: '18',
        unit: '天',
      ),
      SportMetricData(
        icon: Icons.place_rounded,
        color: AppColors.accentPurple,
        title: '总距离',
        value: '48.7',
        unit: 'km',
      ),
    ],
    monthly: const [
      MonthlyDayData(1, 7600),
      MonthlyDayData(2, 6900),
      MonthlyDayData(3, 1500),
      MonthlyDayData(4, 6400),
      MonthlyDayData(5, 7100),
      MonthlyDayData(6, 7800),
      MonthlyDayData(7, 900),
      MonthlyDayData(8, 5800),
      MonthlyDayData(9, 1200),
      MonthlyDayData(10, 6200),
      MonthlyDayData(11, 1400),
      MonthlyDayData(12, 8240),
      MonthlyDayData(13, 7000),
      MonthlyDayData(14, 6500),
      MonthlyDayData(15, 5900),
      MonthlyDayData(16, 5500),
      MonthlyDayData(17, 1100),
      MonthlyDayData(18, 6000),
      MonthlyDayData(19, 6700),
      MonthlyDayData(20, 6400),
      MonthlyDayData(21, 1000),
      MonthlyDayData(22, 5200),
      MonthlyDayData(23, 900),
      MonthlyDayData(24, 1200),
      MonthlyDayData(25, 6100),
      MonthlyDayData(26, 1000),
      MonthlyDayData(27, 6800),
      MonthlyDayData(28, 1300),
      MonthlyDayData(29, 1000),
      MonthlyDayData(30, 7200),
    ],
    analyses: [
      SportAnalysisData(
        icon: Icons.local_fire_department_rounded,
        color: AppColors.accentOrange,
        title: '卡路里分析',
        value: '9,360',
        unit: 'kcal',
        delta: '较上月 +8%',
        samples: const [0.30, 0.42, 0.36, 0.58, 0.47, 0.68, 0.84],
      ),
      SportAnalysisData(
        icon: Icons.timer_rounded,
        color: AppColors.accentCyan,
        title: '活动时间分析',
        value: '17h 24',
        unit: 'min',
        delta: '较上月 +11%',
        samples: const [0.35, 0.50, 0.40, 0.62, 0.48, 0.64, 0.82],
      ),
    ],
    summary: SportSummaryData(
      icon: Icons.calendar_month_rounded,
      color: AppColors.brandGreen,
      title: '月度总结',
      primary: '最佳单日：',
      highlight: '6月12日 · 8,240 步',
      secondary: '本月已完成目标 18 / 30 天',
      assetName: '3D monthly calendar',
      showChevron: true,
    ),
  );
}
