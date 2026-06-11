import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/home/model/sport_detail_model.dart';

/// 详情页顶部返回与日期切换。
class DateSwitcherHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const DateSwitcherHeader({
    super.key,
    required this.title,
    required this.onBack,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _GlassIconButton(
              icon: Icons.chevron_left_rounded,
              onTap: onBack,
              size: 48,
              iconSize: 32,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 70),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TinyTriangleButton(
                  icon: Icons.arrow_left_rounded,
                  onTap: onPrevious,
                ),
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                _TinyTriangleButton(
                  icon: Icons.arrow_right_rounded,
                  onTap: onNext,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    required this.size,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [AppColors.surfaceCardTop, AppColors.surfaceCardBottom],
          ),
          border: Border.all(color: AppColors.strokeCard),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: iconSize),
      ),
    );
  }
}

class _TinyTriangleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TinyTriangleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Icon(icon, color: AppColors.textSecondary, size: 24),
    );
  }
}

/// 顶部圆环 + 右侧 KPI 的组合区域。
class SportHeroSection extends StatelessWidget {
  final SportPeriodData data;

  const SportHeroSection({super.key, required this.data});

  static const int _heroFlex = 5;
  static const int _metricFlex = 4;
  static const double _homeHeroHeightRatio = 1.28;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - AppSpacing.md;
        final heroWidth =
            availableWidth * _heroFlex / (_heroFlex + _metricFlex);
        final sectionHeight = heroWidth * _homeHeroHeightRatio;

        return SizedBox(
          height: sectionHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: _heroFlex,
                child: StepProgressHeroCard(data: data.progress),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                flex: _metricFlex,
                child: Column(
                  children: [
                    for (var i = 0; i < data.metrics.length; i++) ...[
                      Expanded(child: MetricCard(data: data.metrics[i])),
                      if (i != data.metrics.length - 1)
                        SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricValue extends StatelessWidget {
  final SportMetricData data;

  const _MetricValue({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              maxLines: 1,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          data.unit,
          maxLines: 1,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

/// 圆形玻璃图标底座。
class CircleIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  const CircleIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 52,
    this.iconSize = 27,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.34),
            color.withValues(alpha: 0.12),
            AppColors.surfaceIcon.withValues(alpha: 0.72),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 20,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

/// 右侧 KPI 卡。
class MetricCard extends StatelessWidget {
  final SportMetricData data;

  const MetricCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.lg,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          CircleIconBadge(
            icon: data.icon,
            color: data.color,
            size: 45,
            iconSize: 24,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 96, maxWidth: 132),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _MetricValue(data: data),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 主数据圆环卡。
class StepProgressHeroCard extends StatelessWidget {
  final SportProgressData data;

  const StepProgressHeroCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xl,
      glow: true,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxs,
        AppSpacing.md,
        AppSpacing.xxs,
        AppSpacing.xs,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ringSize = math
              .min(constraints.maxWidth - 10, 178.0)
              .clamp(142.0, 178.0);
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: NeonRingProgress(
                  size: ringSize,
                  strokeWidth: 18,
                  progress: data.progress,
                  center: _RingCenter(data: data),
                ),
              ),
              const Positioned(
                bottom: 0,
                left: 6,
                right: 6,
                child: TransparentAssetPlaceholder(
                  height: 58,
                  assetName: '3D walking character and neon forest road',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RingCenter extends StatelessWidget {
  final SportProgressData data;

  const _RingCenter({required this.data});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern('en_US');
    return SizedBox(
      width: 124,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.brandGreen,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatter.format(data.value),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 40,
                fontWeight: FontWeight.w800,
                height: 0.95,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '/ ${formatter.format(data.goal)} ${data.goalUnit}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    color: AppColors.brandLime,
                    size: 12,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${data.badgePrefix} ${data.percent}%',
                    style: TextStyle(
                      color: AppColors.brandLime,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 霓虹绿色圆环进度。
class NeonRingProgress extends StatelessWidget {
  static const List<Color> progressGradientColors = [
    Color(0xFF00B956),
    Color(0xFF24F04E),
    Color(0xFF6CFF3D),
  ];

  final double size;
  final double strokeWidth;
  final double progress;
  final Widget center;

  const NeonRingProgress({
    super.key,
    required this.size,
    required this.strokeWidth,
    required this.progress,
    required this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _NeonRingPainter(
              progress: progress.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
            ),
          ),
          Center(child: center),
        ],
      ),
    );
  }
}

class _NeonRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  const _NeonRingPainter({required this.progress, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const gapDegrees = 64.0;
    final start = _radians(90 + gapDegrees / 2);
    final sweep = _radians(360 - gapDegrees);

    final bgPaint = Paint()
      ..color = AppColors.brandGreenDark.withValues(alpha: 0.58)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, start, sweep, false, bgPaint);

    final glowPaint = Paint()
      ..color = AppColors.brandGreen.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth + 3;
    canvas.drawArc(rect, start, sweep * progress, false, glowPaint);

    final fgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: NeonRingProgress.progressGradientColors,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, start, sweep * progress, false, fgPaint);
  }

  double _radians(double degrees) => degrees * math.pi / 180;

  @override
  bool shouldRepaint(covariant _NeonRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// 透明素材占位，后续替换真实 3D 资源。
class TransparentAssetPlaceholder extends StatelessWidget {
  final double? width;
  final double height;
  final String assetName;

  const TransparentAssetPlaceholder({
    super.key,
    this.width,
    required this.height,
    required this.assetName,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: replace transparent placeholder with the named 3D asset.
    return SizedBox(
      width: width,
      height: height,
      child: const ColoredBox(color: Colors.transparent),
    );
  }
}

/// 每日小时趋势卡。
class HourlyStepTrendCard extends StatelessWidget {
  final List<HourlyStepData> data;

  const HourlyStepTrendCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xl,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle('小时步数趋势'),
          SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 150,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                LineChart(_lineData(), duration: Duration.zero),
                Positioned(
                  top: 0,
                  left: 186,
                  child: _ChartTooltip(text: '12:00 · 4,210 步'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _lineData() {
    final spots = <FlSpot>[
      for (var i = 0; i < data.length; i++)
        FlSpot(i.toDouble(), data[i].steps.toDouble()),
    ];
    return LineChartData(
      minX: 0,
      maxX: (data.length - 1).toDouble(),
      minY: 0,
      maxY: 5000,
      lineTouchData: const LineTouchData(enabled: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1000,
        getDrawingHorizontalLine: (value) => FlLine(
          color: AppColors.gridLine,
          strokeWidth: 1,
          dashArray: const [4, 4],
        ),
      ),
      extraLinesData: ExtraLinesData(
        verticalLines: [
          VerticalLine(
            x: 5,
            color: AppColors.textSecondary.withValues(alpha: 0.55),
            strokeWidth: 1,
            dashArray: const [3, 3],
          ),
        ],
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1000,
            reservedSize: 34,
            getTitlesWidget: (value, meta) => Text(
              value == 0 ? '0' : '${(value / 1000).round()}K',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 2.5,
            reservedSize: 26,
            getTitlesWidget: (value, meta) {
              final labels = {
                0: '00:00',
                2.5: '06:00',
                5: '12:00',
                7.5: '18:00',
                10: '24:00',
              };
              final match = labels.entries
                  .where((e) => (e.key - value).abs() < 0.2)
                  .firstOrNull;
              if (match == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Text(
                  match.value,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.5,
          preventCurveOverShooting: true,
          isStrokeCapRound: true,
          color: AppColors.brandGreen,
          barWidth: 2.5,
          dotData: FlDotData(
            show: true,
            checkToShowDot: (spot, bar) => spot.x == 5 || spot.x % 2 == 0,
            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
              radius: spot.x == 5 ? 5 : 3,
              color: AppColors.white,
              strokeWidth: spot.x == 5 ? 2.5 : 1.5,
              strokeColor: AppColors.brandGreen,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.brandGreen.withValues(alpha: 0.52),
                AppColors.brandGreen.withValues(alpha: 0.00),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 每周柱状统计卡，柱图使用项目已有 fl_chart 插件。
class WeeklyTrendCard extends StatelessWidget {
  final List<WeeklyStepData> data;

  const WeeklyTrendCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xl,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle('本周趋势'),
          SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 170,
            child: Stack(
              children: [
                BarChart(_barData(), duration: Duration.zero),
                IgnorePointer(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _WeeklyCurveOverlay(data: data),
                  ),
                ),
                const Positioned(
                  top: 0,
                  right: 42,
                  child: _ChartTooltip(text: 'SAT · 8,200 步'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BarChartData _barData() {
    return BarChartData(
      minY: 0,
      maxY: 10000,
      barTouchData: BarTouchData(enabled: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 2000,
        getDrawingHorizontalLine: (value) => FlLine(
          color: AppColors.gridLine,
          strokeWidth: 1,
          dashArray: const [4, 4],
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 2000,
            reservedSize: 34,
            getTitlesWidget: (value, meta) => Text(
              value == 0 ? '0' : '${(value / 1000).round()}K',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 25,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= data.length) {
                return const SizedBox.shrink();
              }
              final selected = data[index].label == 'SAT';
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  data[index].label,
                  style: TextStyle(
                    color: selected
                        ? AppColors.brandGreen
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      barGroups: [
        for (var i = 0; i < data.length; i++)
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data[i].steps.toDouble(),
                width: 18,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: data[i].label == 'SAT'
                      ? const [Color(0xFF00B956), Color(0xFF6CFF3D)]
                      : [
                          const Color(0xFF0A7739),
                          AppColors.brandGreen.withValues(alpha: 0.72),
                        ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _WeeklyCurveOverlay extends CustomPainter {
  final List<WeeklyStepData> data;

  const _WeeklyCurveOverlay({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final left = 36.0;
    final right = 8.0;
    final top = 8.0;
    final bottom = 31.0;
    final width = size.width - left - right;
    final height = size.height - top - bottom;
    final points = <Offset>[
      for (var i = 0; i < data.length; i++)
        Offset(
          left + width * i / (data.length - 1),
          top + height * (1 - data[i].steps / 10000),
        ),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }
    final glow = Paint()
      ..color = AppColors.brandGreen.withValues(alpha: 0.22)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, glow);
    final line = Paint()
      ..color = AppColors.brandGreenLight
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, line);
    final dotPaint = Paint()..color = AppColors.white;
    final dotStroke = Paint()
      ..color = AppColors.brandGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final point in points) {
      canvas.drawCircle(point, 5, dotPaint);
      canvas.drawCircle(point, 5, dotStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyCurveOverlay oldDelegate) =>
      oldDelegate.data != data;
}

/// 每日活动时段列表。
class SportSegmentListCard extends StatelessWidget {
  final List<SportSegmentData> segments;

  const SportSegmentListCard({super.key, required this.segments});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xl,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle('活动时段'),
          SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < segments.length; i++) ...[
            _SegmentRow(data: segments[i]),
            if (i != segments.length - 1)
              Divider(color: AppColors.divider, height: 1),
          ],
        ],
      ),
    );
  }
}

class _SegmentRow extends StatelessWidget {
  final SportSegmentData data;

  const _SegmentRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          CircleIconBadge(
            icon: data.icon,
            color: data.color,
            size: 44,
            iconSize: 24,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Flexible(
            flex: 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                children: [
                  Text(
                    data.time,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    ' · ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    data.steps,
                    style: TextStyle(color: AppColors.brandGreen, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
            size: 24,
          ),
        ],
      ),
    );
  }
}

/// 分析小卡。
class SportMiniAnalysisCard extends StatelessWidget {
  final SportAnalysisData data;

  const SportMiniAnalysisCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xl,
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, color: data.color, size: 22),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  data.value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  data.unit,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${data.delta} ↑',
            style: TextStyle(color: data.color, fontSize: 13),
          ),
          SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 42,
            child: LineChart(_miniLineData(), duration: Duration.zero),
          ),
        ],
      ),
    );
  }

  LineChartData _miniLineData() {
    final lastX = (data.samples.length - 1).toDouble();
    return LineChartData(
      minX: 0,
      maxX: lastX,
      minY: 0,
      maxY: 1,
      lineTouchData: const LineTouchData(enabled: false),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: const FlTitlesData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: [
            for (var i = 0; i < data.samples.length; i++)
              FlSpot(i.toDouble(), data.samples[i]),
          ],
          isCurved: true,
          curveSmoothness: 0.54,
          preventCurveOverShooting: true,
          isStrokeCapRound: true,
          color: data.color,
          barWidth: 2,
          dotData: FlDotData(
            show: true,
            checkToShowDot: (spot, bar) => spot.x == lastX,
            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
              radius: 4,
              color: AppColors.white,
              strokeWidth: 2,
              strokeColor: data.color,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                data.color.withValues(alpha: 0.48),
                data.color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 月度热力圆形日历。
class MonthlyHeatCalendarCard extends StatelessWidget {
  final List<MonthlyDayData> days;

  const MonthlyHeatCalendarCard({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    final byDay = {for (final day in days) day.day: day};
    return GlassCard(
      radius: AppRadius.xl,
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle('月度热力'),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (final label in const [
                '周一',
                '周二',
                '周三',
                '周四',
                '周五',
                '周六',
                '周日',
              ])
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          GridView.builder(
            itemCount: 35,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
            ),
            itemBuilder: (context, index) {
              final day = index + 1;
              if (day > 30) return const SizedBox.shrink();
              final step = byDay[day]?.steps ?? 0;
              return _HeatDayCircle(day: day, steps: step);
            },
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  '步数较少',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              for (var i = 0; i < 5; i++) ...[
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: _heatColor((i + 1) * 1700),
                    shape: BoxShape.circle,
                  ),
                ),
                if (i != 4) SizedBox(width: AppSpacing.xs),
              ],
              SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  '步数较多',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatDayCircle extends StatelessWidget {
  final int day;
  final int steps;

  const _HeatDayCircle({required this.day, required this.steps});

  @override
  Widget build(BuildContext context) {
    final hot = steps >= 7000;
    return Center(
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _heatColor(steps),
          border: hot
              ? Border.all(
                  color: AppColors.brandGreenLight.withValues(alpha: 0.65),
                )
              : null,
          boxShadow: hot
              ? [
                  BoxShadow(
                    color: AppColors.brandGreen.withValues(alpha: 0.30),
                    blurRadius: 16,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            '$day',
            style: TextStyle(
              color: AppColors.textPrimary.withValues(
                alpha: steps <= 1500 ? 0.72 : 1,
              ),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// 总结 / 建议卡。
class SummaryCard extends StatelessWidget {
  final SportSummaryData data;

  const SummaryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xl,
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleIconBadge(
                  icon: data.icon,
                  color: data.color,
                  size: 56,
                  iconSize: 30,
                ),
                // TODO: replace with data.assetName real 3D asset.
                TransparentAssetPlaceholder(
                  height: 70,
                  assetName: data.assetName,
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.45,
                    ),
                    children: [
                      TextSpan(text: data.primary),
                      TextSpan(
                        text: data.highlight,
                        style: TextStyle(
                          color: AppColors.brandGreen,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: data.actionLabel == null ? '' : ' '),
                      if (data.actionLabel != null)
                        TextSpan(text: data.secondary.split('\n').first)
                      else
                        TextSpan(
                          text: data.secondary.startsWith('本')
                              ? '\n${data.secondary}'
                              : data.secondary,
                        ),
                    ],
                  ),
                ),
                if (data.actionLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    data.secondary.split('\n').last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (data.actionLabel != null) ...[
            SizedBox(width: AppSpacing.sm),
            _GreenPillButton(label: data.actionLabel!),
          ] else if (data.showChevron)
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 28,
            ),
        ],
      ),
    );
  }
}

class _GreenPillButton extends StatelessWidget {
  final String label;

  const _GreenPillButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 78),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.full),
        gradient: const LinearGradient(
          colors: [Color(0xFF0C682D), Color(0xFF0E8E37)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandGreen.withValues(alpha: 0.22),
            blurRadius: 18,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.brandLime,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 底部日/周/月胶囊切换。
class SportPeriodTabBar extends StatelessWidget {
  final SportPeriod current;
  final ValueChanged<SportPeriod> onChanged;

  const SportPeriodTabBar({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('shared_bottom_tab_capsule'),
      width: AppBottomTabBarMetrics.width,
      height: AppBottomTabBarMetrics.height,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.full),
        color: const Color(0xDB030F14),
        border: Border.all(color: AppColors.strokeCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _PeriodTabButton(
            label: '日',
            value: SportPeriod.day,
            current: current,
            onChanged: onChanged,
          ),
          _PeriodTabButton(
            label: '周',
            value: SportPeriod.week,
            current: current,
            onChanged: onChanged,
          ),
          _PeriodTabButton(
            label: '月',
            value: SportPeriod.month,
            current: current,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _PeriodTabButton extends StatelessWidget {
  final String label;
  final SportPeriod value;
  final SportPeriod current;
  final ValueChanged<SportPeriod> onChanged;

  const _PeriodTabButton({
    required this.label,
    required this.value,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(value),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: selected
                ? AppBottomTabBarMetrics.selectedWidth
                : AppBottomTabBarMetrics.itemExtent,
            height: AppBottomTabBarMetrics.itemExtent,
            alignment: Alignment.center,
            decoration: selected
                ? BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.brandGreenLight, AppColors.brandGreen],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandGreen.withValues(alpha: 0.4),
                        blurRadius: 14,
                      ),
                    ],
                  )
                : null,
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.bgPrimary : const Color(0xB3A5A5A5),
                fontSize: 18,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String text;

  const _CardTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ChartTooltip extends StatelessWidget {
  final String text;

  const _ChartTooltip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceCardBottom.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.strokeCard),
      ),
      child: Text(
        text,
        style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
      ),
    );
  }
}

Color _heatColor(int steps) {
  if (steps <= 0) return AppColors.brandGreenDark.withValues(alpha: 0.16);
  if (steps < 1800) return AppColors.brandGreenDark.withValues(alpha: 0.44);
  if (steps < 4500) return AppColors.brandGreen.withValues(alpha: 0.42);
  if (steps < 6500) return AppColors.brandGreen.withValues(alpha: 0.62);
  if (steps < 7600) return AppColors.brandGreen.withValues(alpha: 0.82);
  return AppColors.brandGreenLight.withValues(alpha: 0.92);
}
