import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/common/component/asset_metric_icon.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/common/config/app_icon_source.dart';
import 'package:pedometer/common/config/localized_text.dart';
import 'package:pedometer/feature/home/components/walking_scene_placeholder.dart';
import 'package:pedometer/feature/home/model/sport_detail_model.dart';

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
  final bool glow;

  const CircleIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 52,
    this.iconSize = 27,
    this.glow = true,
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
        boxShadow: glow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  blurRadius: 20,
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

class MetricIconBadge extends StatelessWidget {
  final String assetName;
  final double size;

  const MetricIconBadge({super.key, required this.assetName, this.size = 52});

  @override
  Widget build(BuildContext context) {
    final assetSize = size - 5;
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: AssetMetricIcon(assetName: assetName, size: assetSize),
      ),
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
          MetricIconBadge(assetName: data.iconAsset, size: 45),
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
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
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
        0,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const sceneAspect = 226 / 100;
          final sceneBleedX = AppSpacing.xxs;
          final sceneHeight =
              (constraints.maxWidth + sceneBleedX * 2) / sceneAspect;
          final ringSize = (constraints.maxWidth - 10).clamp(142.0, 178.0);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -sceneBleedX,
                right: -sceneBleedX,
                bottom: 0,
                child: WalkingSceneOverlay(
                  height: sceneHeight,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.bottomCenter,
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: NeonRingProgress(
                  size: ringSize,
                  strokeWidth: 18,
                  progress: data.progress,
                  center: _RingCenter(data: data),
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
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, color: AppColors.brandLime, size: 9),
                  const SizedBox(width: 2),
                  Text(
                    '${data.badgePrefix} ${data.percent}%',
                    style: TextStyle(
                      color: AppColors.brandLime,
                      fontSize: 8,
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
  static List<Color> get progressGradientColors => [
    AppColors.brandGreenMid,
    AppColors.brandGreen,
    AppColors.brandGreenLight,
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
      ..shader = LinearGradient(
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
class HourlyStepTrendCard extends StatefulWidget {
  final List<HourlyStepData> data;

  const HourlyStepTrendCard({super.key, required this.data});

  static const double _chartMaxX = 10;
  static const double _chartMaxY = 5000;
  static const double _leftTitleReservedSize = 34;
  static const double _bottomTitleReservedSize = 26;
  static const double _tooltipWidth = 126;
  static const double _tooltipHeight = 32;
  static const double _tooltipGap = 8;

  /// 按下到抬起的位移在此范围内才视为「点击」，超过则当作滚动忽略。
  static const double _tapSlop = 44;

  @override
  State<HourlyStepTrendCard> createState() => _HourlyStepTrendCardState();
}

class _HourlyStepTrendCardState extends State<HourlyStepTrendCard> {
  int? _selectedIndex;
  Offset? _pointerDownPosition;

  int get _effectiveSelectedIndex {
    if (widget.data.isEmpty) return -1;
    final selectedIndex = _selectedIndex;
    if (selectedIndex != null &&
        selectedIndex >= 0 &&
        selectedIndex < widget.data.length) {
      return selectedIndex;
    }
    final noonIndex = widget.data.indexWhere((item) => item.label == '12:00');
    return noonIndex == -1 ? widget.data.length ~/ 2 : noonIndex;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _effectiveSelectedIndex;
    final selectedItem = selectedIndex < 0 ? null : widget.data[selectedIndex];
    final tooltipText = selectedItem == null
        ? null
        : lt(
            '${selectedItem.label} · ${NumberFormat.decimalPattern().format(selectedItem.steps)} steps',
            '${selectedItem.label} · ${NumberFormat.decimalPattern().format(selectedItem.steps)} 步',
          );
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
          _CardTitle(lt('Hourly Steps Trend', '小时步数趋势')),
          SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 150,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final selectedPoint = selectedIndex < 0
                    ? null
                    : _chartPointFor(
                        constraints.biggest,
                        selectedIndex,
                        widget.data[selectedIndex].steps,
                      );
                return Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) {
                    _pointerDownPosition = event.localPosition;
                  },
                  onPointerUp: (event) {
                    final down = _pointerDownPosition;
                    _pointerDownPosition = null;
                    if (down == null) return;
                    if ((event.localPosition - down).distance >
                        HourlyStepTrendCard._tapSlop) {
                      return;
                    }
                    _selectIndexAt(
                      event.localPosition.dx,
                      constraints.maxWidth,
                    );
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      LineChart(
                        _lineData(selectedIndex),
                        duration: Duration.zero,
                      ),
                      if (tooltipText != null && selectedPoint != null)
                        Positioned(
                          left: _tooltipLeftFor(
                            selectedPoint.dx,
                            constraints.maxWidth,
                          ),
                          top: _tooltipTopFor(
                            selectedPoint.dy,
                            constraints.maxHeight,
                          ),
                          child: IgnorePointer(
                            child: SizedBox(
                              width: HourlyStepTrendCard._tooltipWidth,
                              child: _ChartTooltip(text: tooltipText),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _selectIndexAt(double dx, double chartWidth) {
    if (widget.data.isEmpty) return;
    const left = HourlyStepTrendCard._leftTitleReservedSize;
    const right = 0.0;
    // 左侧刻度标签区不参与选点，避免点击 Y 轴数字误选最左侧坐标点。
    if (dx < left) return;
    final width = chartWidth - left - right;
    if (width <= 0) return;
    final chartX = ((dx - left) / width * HourlyStepTrendCard._chartMaxX).clamp(
      0.0,
      HourlyStepTrendCard._chartMaxX,
    );
    final index = _nearestIndexTo(chartX);
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  Offset _chartPointFor(Size size, int index, int steps) {
    const left = HourlyStepTrendCard._leftTitleReservedSize;
    const right = 0.0;
    const top = 0.0;
    const bottom = HourlyStepTrendCard._bottomTitleReservedSize;
    final width = size.width - left - right;
    final height = size.height - top - bottom;
    final chartX = _timeAxisXForLabel(widget.data[index].label);
    final yRatio =
        1 -
        steps.clamp(0, HourlyStepTrendCard._chartMaxY) /
            HourlyStepTrendCard._chartMaxY;
    return Offset(
      left + width * chartX / HourlyStepTrendCard._chartMaxX,
      top + height * yRatio,
    );
  }

  double _tooltipLeftFor(double pointX, double chartWidth) {
    final preferred = pointX + HourlyStepTrendCard._tooltipGap;
    return preferred.clamp(0.0, chartWidth - HourlyStepTrendCard._tooltipWidth);
  }

  double _tooltipTopFor(double pointY, double chartHeight) {
    final preferred = pointY - HourlyStepTrendCard._tooltipHeight / 2;
    return preferred.clamp(
      0.0,
      chartHeight - HourlyStepTrendCard._tooltipHeight,
    );
  }

  LineChartData _lineData(int selectedIndex) {
    final selectedX = selectedIndex < 0
        ? null
        : _timeAxisXForLabel(widget.data[selectedIndex].label);
    final spots = <FlSpot>[
      for (var i = 0; i < widget.data.length; i++)
        FlSpot(
          _timeAxisXForLabel(widget.data[i].label),
          widget.data[i].steps.toDouble(),
        ),
    ];
    return LineChartData(
      minX: 0,
      maxX: HourlyStepTrendCard._chartMaxX,
      minY: 0,
      maxY: HourlyStepTrendCard._chartMaxY,
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
            x: selectedX ?? 5,
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
            reservedSize: HourlyStepTrendCard._leftTitleReservedSize,
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
            reservedSize: HourlyStepTrendCard._bottomTitleReservedSize,
            getTitlesWidget: (value, meta) {
              final labels = <double, String>{
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
            checkToShowDot: (spot, bar) =>
                selectedX != null && (spot.x - selectedX).abs() < 0.001,
            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
              radius: selectedX != null && (spot.x - selectedX).abs() < 0.001
                  ? 5
                  : 3,
              color: AppColors.white,
              strokeWidth:
                  selectedX != null && (spot.x - selectedX).abs() < 0.001
                  ? 2.5
                  : 1.5,
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

  int _nearestIndexTo(double chartX) {
    var nearestIndex = 0;
    var nearestDistance = double.infinity;
    for (var i = 0; i < widget.data.length; i++) {
      final distance = (_timeAxisXForLabel(widget.data[i].label) - chartX)
          .abs();
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = i;
      }
    }
    return nearestIndex;
  }

  double _timeAxisXForLabel(String label) {
    final parts = label.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final totalMinutes = (hour * 60 + minute).clamp(0, 24 * 60);
    return totalMinutes / (24 * 60) * HourlyStepTrendCard._chartMaxX;
  }
}

/// 每周柱状统计卡，柱图使用项目已有 fl_chart 插件。
class WeeklyTrendCard extends StatefulWidget {
  final List<WeeklyStepData> data;

  const WeeklyTrendCard({super.key, required this.data});

  static const double _defaultMaxY = 10000;
  static const double _firstExpandedMaxY = 15000;
  static const double _expandedStepY = 5000;
  static const double _maxDynamicY = 50000;
  static const int _yAxisIntervalCount = 5;
  static const double _leftTitleReservedSize = 38;
  static const double _bottomTitleReservedSize = 25;
  static const double _barWidth = 18;
  static const double _tooltipWidth = 118;
  static const double _tooltipHeight = 32;
  static const double _tooltipGap = 8;

  /// 按下到抬起的位移在此范围内才视为「点击」，超过则当作滚动忽略。
  static const double _tapSlop = 44;

  /// 今天对应的星期标签，与柱图 label 保持一致（MON…SUN）。
  static String get _todayLabel {
    const enLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    const zhLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return (isZhLocale ? zhLabels : enLabels)[DateTime.now().weekday - 1];
  }

  /// 千分位格式化步数，如 8200 -> 8,200。
  static String _formatSteps(int steps) {
    final text = steps.abs().toString();
    final buffer = StringBuffer(steps < 0 ? '-' : '');
    for (var i = 0; i < text.length; i++) {
      final remaining = text.length - i;
      buffer.write(text[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  @override
  State<WeeklyTrendCard> createState() => _WeeklyTrendCardState();
}

class _WeeklyTrendCardState extends State<WeeklyTrendCard> {
  int? _selectedIndex;
  Offset? _pointerDownPosition;

  int get _effectiveSelectedIndex {
    if (widget.data.isEmpty) return -1;
    final selectedIndex = _selectedIndex;
    if (selectedIndex != null &&
        selectedIndex >= 0 &&
        selectedIndex < widget.data.length) {
      return selectedIndex;
    }
    final todayIndex = widget.data.indexWhere(
      (item) => item.label == WeeklyTrendCard._todayLabel,
    );
    return todayIndex == -1 ? 0 : todayIndex;
  }

  String get _selectedLabel {
    final index = _effectiveSelectedIndex;
    if (index < 0) return WeeklyTrendCard._todayLabel;
    return widget.data[index].label;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _effectiveSelectedIndex;
    final selectedItem = selectedIndex < 0 ? null : widget.data[selectedIndex];
    final tooltipText = selectedItem == null
        ? null
        : lt(
            '${selectedItem.label} · ${WeeklyTrendCard._formatSteps(selectedItem.steps)} steps',
            '${selectedItem.label} · ${WeeklyTrendCard._formatSteps(selectedItem.steps)} 步',
          );
    final yAxisScale = _yAxisScale;
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
          _CardTitle(lt('Weekly Trend', '每周趋势')),
          SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 170,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final selectedPoint = selectedIndex < 0
                    ? null
                    : _chartPointFor(
                        constraints.biggest,
                        selectedIndex,
                        widget.data[selectedIndex].steps,
                        yAxisScale,
                      );
                return Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) {
                    _pointerDownPosition = event.localPosition;
                  },
                  onPointerUp: (event) {
                    final down = _pointerDownPosition;
                    _pointerDownPosition = null;
                    if (down == null) return;
                    if ((event.localPosition - down).distance >
                        WeeklyTrendCard._tapSlop) {
                      return;
                    }
                    _selectIndexAt(
                      event.localPosition.dx,
                      constraints.maxWidth,
                    );
                  },
                  child: Stack(
                    children: [
                      BarChart(
                        _barData(_selectedLabel, yAxisScale),
                        duration: Duration.zero,
                      ),
                      IgnorePointer(
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: _WeeklyCurveOverlay(
                            data: widget.data,
                            yAxisScale: yAxisScale,
                          ),
                        ),
                      ),
                      if (tooltipText != null && selectedPoint != null)
                        Positioned(
                          left: _tooltipLeftFor(
                            selectedPoint.dx,
                            constraints.maxWidth,
                          ),
                          top: _tooltipTopFor(
                            selectedPoint.dy,
                            constraints.maxHeight,
                          ),
                          child: IgnorePointer(
                            child: SizedBox(
                              width: WeeklyTrendCard._tooltipWidth,
                              child: _ChartTooltip(text: tooltipText),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _selectIndexAt(double dx, double chartWidth) {
    if (widget.data.isEmpty) return;
    const left = WeeklyTrendCard._leftTitleReservedSize;
    const right = 0.0;
    // 左侧刻度标签区不参与选点，避免点击 Y 轴数字误选最左侧坐标点。
    if (dx < left) return;
    final width = chartWidth - left - right;
    if (width <= 0) return;
    final index = (((dx - left) / width) * widget.data.length).floor().clamp(
      0,
      widget.data.length - 1,
    );
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  Offset _chartPointFor(
    Size size,
    int index,
    int steps,
    _WeeklyYAxisScale yAxisScale,
  ) {
    const left = WeeklyTrendCard._leftTitleReservedSize;
    const right = 0.0;
    const top = 0.0;
    const bottom = WeeklyTrendCard._bottomTitleReservedSize;
    final width = size.width - left - right;
    final height = size.height - top - bottom;
    final yRatio =
        1 - steps.toDouble().clamp(0.0, yAxisScale.maxY) / yAxisScale.maxY;
    return Offset(
      left + width * (index + 0.5) / widget.data.length,
      top + height * yRatio,
    );
  }

  double _tooltipLeftFor(double pointX, double chartWidth) {
    final preferred =
        pointX + WeeklyTrendCard._barWidth / 2 + WeeklyTrendCard._tooltipGap;
    return preferred.clamp(0.0, chartWidth - WeeklyTrendCard._tooltipWidth);
  }

  double _tooltipTopFor(double pointY, double chartHeight) {
    final preferred = pointY - WeeklyTrendCard._tooltipHeight / 2;
    return preferred.clamp(0.0, chartHeight - WeeklyTrendCard._tooltipHeight);
  }

  BarChartData _barData(String selectedLabel, _WeeklyYAxisScale yAxisScale) {
    return BarChartData(
      minY: 0,
      maxY: yAxisScale.maxY,
      alignment: BarChartAlignment.spaceAround,
      barTouchData: BarTouchData(enabled: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: yAxisScale.interval,
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
            interval: yAxisScale.interval,
            reservedSize: WeeklyTrendCard._leftTitleReservedSize,
            getTitlesWidget: (value, meta) => Text(
              _yLabel(value),
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: WeeklyTrendCard._bottomTitleReservedSize,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= widget.data.length) {
                return const SizedBox.shrink();
              }
              final selected = widget.data[index].label == selectedLabel;
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  widget.data[index].label,
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
        for (var i = 0; i < widget.data.length; i++)
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: widget.data[i].steps.toDouble().clamp(
                  0.0,
                  yAxisScale.maxY,
                ),
                width: WeeklyTrendCard._barWidth,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: widget.data[i].label == selectedLabel
                      ? [AppColors.brandGreenMid, AppColors.brandGreenLight]
                      : [
                          AppColors.brandGreenShade,
                          AppColors.brandGreen.withValues(alpha: 0.72),
                        ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  _WeeklyYAxisScale get _yAxisScale {
    final maxValue = widget.data.fold<int>(
      0,
      (max, item) => item.steps > max ? item.steps : max,
    );
    final maxY = _dynamicMaxYFor(maxValue.toDouble());
    return _WeeklyYAxisScale(
      maxY: maxY,
      interval: maxY / WeeklyTrendCard._yAxisIntervalCount,
    );
  }

  double _dynamicMaxYFor(double maxValue) {
    if (maxValue < WeeklyTrendCard._defaultMaxY) {
      return WeeklyTrendCard._defaultMaxY;
    }
    if (maxValue <= WeeklyTrendCard._firstExpandedMaxY) {
      return WeeklyTrendCard._firstExpandedMaxY;
    }
    final steppedMaxY =
        (maxValue / WeeklyTrendCard._expandedStepY).ceil() *
        WeeklyTrendCard._expandedStepY;
    return steppedMaxY.clamp(
      WeeklyTrendCard._firstExpandedMaxY + WeeklyTrendCard._expandedStepY,
      WeeklyTrendCard._maxDynamicY,
    );
  }

  String _yLabel(double value) {
    if (value <= 0) return '0';
    final thousands = value / 1000;
    if (thousands == thousands.roundToDouble()) {
      return '${thousands.round()}K';
    }
    return '${thousands.toStringAsFixed(1)}K';
  }
}

class _WeeklyCurveOverlay extends CustomPainter {
  final List<WeeklyStepData> data;
  final _WeeklyYAxisScale yAxisScale;

  const _WeeklyCurveOverlay({required this.data, required this.yAxisScale});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    const left = WeeklyTrendCard._leftTitleReservedSize;
    const right = 0.0;
    const top = 0.0;
    const bottom = WeeklyTrendCard._bottomTitleReservedSize;
    final width = size.width - left - right;
    final height = size.height - top - bottom;
    final points = <Offset>[
      for (var i = 0; i < data.length; i++)
        Offset(
          left + width * (i + 0.5) / data.length,
          top +
              height *
                  (1 -
                      data[i].steps.toDouble().clamp(0.0, yAxisScale.maxY) /
                          yAxisScale.maxY),
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
      oldDelegate.data != data || oldDelegate.yAxisScale != yAxisScale;
}

class _WeeklyYAxisScale {
  final double maxY;
  final double interval;

  const _WeeklyYAxisScale({required this.maxY, required this.interval});
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
          _CardTitle(lt('Active Periods', '活跃时段')),
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
              AssetMetricIcon(assetName: data.assetIcon, size: 22),
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
class MonthlyHeatCalendarCard extends StatefulWidget {
  final List<MonthlyDayData> days;

  /// 滑动切换月份后回调，offset：0 = 本月，-1 = 上月，依此类推。
  final void Function(int offset)? onMonthChanged;

  const MonthlyHeatCalendarCard({
    super.key,
    required this.days,
    this.onMonthChanged,
  });

  @override
  State<MonthlyHeatCalendarCard> createState() =>
      _MonthlyHeatCalendarCardState();
}

class _MonthlyHeatCalendarCardState extends State<MonthlyHeatCalendarCard> {
  // 用一个较大的基准页代表「本月」：左滑（更早）页码减小，
  // 而本月即最大页（itemCount 上限），故无法滑向未来月份。
  static const int _basePage = 100000;
  late final PageController _controller = PageController(
    initialPage: _basePage,
  );

  // 当前展示的月份偏移（0 = 本月）与被点选的日期（null = 未选）。
  int _currentOffset = 0;
  int? _selectedDay;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime _monthForOffset(int offset) {
    final now = DateTime.now();
    return DateTime(now.year, now.month + offset, 1);
  }

  /// 千分位格式化步数，如 8240 -> 8,240。
  String _formatSteps(int steps) {
    final text = steps.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final remaining = text.length - i;
      buffer.write(text[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final byDay = {for (final day in widget.days) day.day: day};
    final selectedDay = _selectedDay;
    final selectedMonth = _monthForOffset(_currentOffset);
    final selectedSteps = selectedDay == null
        ? 0
        : byDay[selectedDay]?.steps ?? 0;
    return GlassCard(
      radius: AppRadius.xl,
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _CardTitle(lt('Monthly Heatmap', '月度热力图'))),
              if (selectedDay != null)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      lt(
                        '${_monthName(selectedMonth.month)} $selectedDay · ${_formatSteps(selectedSteps)} steps',
                        '${_monthName(selectedMonth.month)}$selectedDay日 · ${_formatSteps(selectedSteps)} 步',
                      ),
                      style: TextStyle(
                        color: AppColors.brandGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (final label
                  in isZhLocale
                      ? const ['一', '二', '三', '四', '五', '六', '日']
                      : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
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
          LayoutBuilder(
            builder: (context, constraints) {
              final spacing = AppSpacing.sm;
              final cell = (constraints.maxWidth - spacing * 6) / 7;
              // 固定 6 行，保证各月等高，PageView 翻页时高度不跳动。
              final gridHeight = cell * 6 + spacing * 5;
              return SizedBox(
                height: gridHeight,
                child: PageView.builder(
                  controller: _controller,
                  // 上限 = 本月（_basePage），不能滑向未来。
                  itemCount: _basePage + 1,
                  onPageChanged: (page) {
                    setState(() {
                      _currentOffset = page - _basePage;
                      // 切月后清除上个月的选中态。
                      _selectedDay = null;
                    });
                    widget.onMonthChanged?.call(page - _basePage);
                  },
                  itemBuilder: (context, page) {
                    final offset = page - _basePage;
                    final monthDate = _monthForOffset(offset);
                    return _MonthGrid(
                      year: monthDate.year,
                      month: monthDate.month,
                      // 仅当前展示月份的格子使用真实数据并可点选。
                      byDay: offset == _currentOffset
                          ? byDay
                          : const <int, MonthlyDayData>{},
                      cellExtent: cell,
                      spacing: spacing,
                      selectedDay: offset == _currentOffset
                          ? _selectedDay
                          : null,
                      onDayTap: offset == _currentOffset
                          ? (day) => setState(
                              () => _selectedDay = _selectedDay == day
                                  ? null
                                  : day,
                            )
                          : null,
                    );
                  },
                ),
              );
            },
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  lt('Fewer steps', '步数少'),
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
                  lt('More steps', '步数多'),
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

/// 单个月份的热力网格（固定 6 行）。
class _MonthGrid extends StatelessWidget {
  final int year;
  final int month;
  final Map<int, MonthlyDayData> byDay;
  final double cellExtent;
  final double spacing;
  final int? selectedDay;
  final void Function(int day)? onDayTap;

  const _MonthGrid({
    required this.year,
    required this.month,
    required this.byDay,
    required this.cellExtent,
    required this.spacing,
    this.selectedDay,
    this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    // 当月 1 号是周几（1=周一…7=周日），决定前导空格数。
    final leading = DateTime(year, month, 1).weekday - 1;
    // 当月天数：下个月的第 0 天即本月最后一天。
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return GridView.builder(
      padding: EdgeInsets.zero,
      itemCount: 42,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        mainAxisExtent: cellExtent,
      ),
      itemBuilder: (context, index) {
        final day = index - leading + 1;
        if (index < leading || day > daysInMonth) {
          return const SizedBox.shrink();
        }
        final step = byDay[day]?.steps ?? 0;
        return _HeatDayCircle(
          day: day,
          steps: step,
          selected: selectedDay == day,
          onTap: onDayTap == null ? null : () => onDayTap!(day),
        );
      },
    );
  }
}

class _HeatDayCircle extends StatelessWidget {
  final int day;
  final int steps;
  final bool selected;
  final VoidCallback? onTap;

  const _HeatDayCircle({
    required this.day,
    required this.steps,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hot = steps >= 7000;
    final circle = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _heatColor(steps),
        border: selected
            ? Border.all(color: AppColors.brandGreenLight, width: 2)
            : hot
            ? Border.all(
                color: AppColors.brandGreenLight.withValues(alpha: 0.65),
              )
            : null,
        boxShadow: (hot || selected)
            ? [
                BoxShadow(
                  color: AppColors.brandGreen.withValues(
                    alpha: selected ? 0.45 : 0.30,
                  ),
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
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
    if (onTap == null) return Center(child: circle);
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: circle,
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
            width: 56,
            child: Center(
              child: data.icon is AssetAppIcon
                  ? MetricIconBadge(
                      assetName: (data.icon as AssetAppIcon).assetName,
                      size: 52,
                    )
                  : CircleIconBadge(
                      icon: (data.icon as MaterialAppIcon).icon,
                      color: data.color,
                      size: 52,
                      iconSize: 27,
                      glow: false,
                    ),
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
                          text: data.secondary.contains('\n')
                              ? data.secondary
                              : '\n${data.secondary}',
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
        gradient: LinearGradient(
          colors: [AppColors.pillGreenStart, AppColors.pillGreenEnd],
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
      width: AppBottomTabBarMetrics.width(context),
      height: AppBottomTabBarMetrics.height,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.full),
        color: AppColors.surfaceCapsule,
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
            label: lt('Day', '日'),
            value: SportPeriod.day,
            current: current,
            onChanged: onChanged,
          ),
          _PeriodTabButton(
            label: lt('Week', '周'),
            value: SportPeriod.week,
            current: current,
            onChanged: onChanged,
          ),
          _PeriodTabButton(
            label: lt('Month', '月'),
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
            width: AppBottomTabBarMetrics.selectedWidth,
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
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: selected ? AppColors.bgPrimary : AppColors.tabInactive,
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

String _monthName(int month) {
  if (isZhLocale) return '$month月';
  const names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return names[(month - 1).clamp(0, names.length - 1)];
}
