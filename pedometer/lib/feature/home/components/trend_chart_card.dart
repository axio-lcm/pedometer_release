import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/home/model/home_model.dart';
import 'package:pedometer/feature/home/resources/home_resource.dart';

/// 趋势大卡：标题 + fl_chart 平滑曲线（渐变填充 + 发光节点）。
class TrendChartCard extends StatefulWidget {
  final List<TrendPoint> points;
  const TrendChartCard({super.key, required this.points});

  static const double _maxY = 8000;
  static const double _curveSmoothness = 0.56;
  static const double _leftTitleReservedSize = 30;
  static const double _bottomTitleReservedSize = 22;
  static const double _tooltipWidth = 116;
  static const double _tooltipHeight = 32;
  static const double _tooltipGap = 8;

  @override
  State<TrendChartCard> createState() => _TrendChartCardState();
}

class _TrendChartCardState extends State<TrendChartCard> {
  int? _selectedIndex;

  int get _effectiveSelectedIndex {
    if (widget.points.isEmpty) return -1;
    final selectedIndex = _selectedIndex;
    if (selectedIndex != null &&
        selectedIndex >= 0 &&
        selectedIndex < widget.points.length) {
      return selectedIndex;
    }
    final highlightedIndex = widget.points.indexWhere(
      (point) => point.highlight,
    );
    return highlightedIndex == -1 ? widget.points.length - 1 : highlightedIndex;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _effectiveSelectedIndex;
    final selectedPoint = selectedIndex < 0
        ? null
        : widget.points[selectedIndex];
    final tooltipText = selectedPoint == null
        ? null
        : '${selectedPoint.label} · ${NumberFormat.decimalPattern().format(selectedPoint.value.round())} 步';
    return GlassCard(
      radius: AppRadius.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  HomeResource.trend,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 160,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chartPoint = selectedIndex < 0
                    ? null
                    : _chartPointFor(
                        constraints.biggest,
                        selectedIndex,
                        widget.points[selectedIndex].value,
                      );
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) {
                    _selectIndexAt(
                      details.localPosition.dx,
                      constraints.maxWidth,
                    );
                  },
                  onHorizontalDragDown: (details) {
                    _selectIndexAt(
                      details.localPosition.dx,
                      constraints.maxWidth,
                    );
                  },
                  onHorizontalDragUpdate: (details) {
                    _selectIndexAt(
                      details.localPosition.dx,
                      constraints.maxWidth,
                    );
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      LineChart(
                        _chartData(selectedIndex),
                        duration: Duration.zero,
                      ),
                      if (tooltipText != null && chartPoint != null)
                        Positioned(
                          left: _tooltipLeftFor(
                            chartPoint.dx,
                            constraints.maxWidth,
                          ),
                          top: _tooltipTopFor(
                            chartPoint.dy,
                            constraints.maxHeight,
                          ),
                          child: SizedBox(
                            width: TrendChartCard._tooltipWidth,
                            child: _TrendTooltip(text: tooltipText),
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
    if (widget.points.isEmpty) return;
    const left = TrendChartCard._leftTitleReservedSize;
    const right = 0.0;
    final width = chartWidth - left - right;
    if (width <= 0) return;
    final index = (((dx - left) / width) * (widget.points.length - 1))
        .round()
        .clamp(0, widget.points.length - 1);
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  Offset _chartPointFor(Size size, int index, double value) {
    const left = TrendChartCard._leftTitleReservedSize;
    const right = 0.0;
    const top = 0.0;
    const bottom = TrendChartCard._bottomTitleReservedSize;
    final width = size.width - left - right;
    final height = size.height - top - bottom;
    final divisor = (widget.points.length - 1).clamp(1, widget.points.length);
    final yRatio =
        1 - value.clamp(0.0, TrendChartCard._maxY) / TrendChartCard._maxY;
    return Offset(left + width * index / divisor, top + height * yRatio);
  }

  double _tooltipLeftFor(double pointX, double chartWidth) {
    final preferred = pointX + TrendChartCard._tooltipGap;
    return preferred.clamp(0.0, chartWidth - TrendChartCard._tooltipWidth);
  }

  double _tooltipTopFor(double pointY, double chartHeight) {
    final preferred = pointY - TrendChartCard._tooltipHeight / 2;
    return preferred.clamp(0.0, chartHeight - TrendChartCard._tooltipHeight);
  }

  LineChartData _chartData(int selectedIndex) {
    final spots = <FlSpot>[
      for (var i = 0; i < widget.points.length; i++)
        FlSpot(i.toDouble(), widget.points[i].value),
    ];
    return LineChartData(
      minX: 0,
      maxX: (widget.points.length - 1)
          .clamp(0, widget.points.length)
          .toDouble(),
      minY: 0,
      maxY: TrendChartCard._maxY,
      lineTouchData: const LineTouchData(enabled: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 2000,
        getDrawingHorizontalLine: (value) => FlLine(
          color: AppColors.gridLine,
          strokeWidth: 1,
          dashArray: const [5, 4],
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
            reservedSize: TrendChartCard._leftTitleReservedSize,
            getTitlesWidget: (value, meta) => Text(
              _yLabel(value),
              style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: TrendChartCard._bottomTitleReservedSize,
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i < 0 || i >= widget.points.length) {
                return const SizedBox.shrink();
              }
              final p = widget.points[i];
              final selected = i == selectedIndex;
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  p.label,
                  style: TextStyle(
                    color: selected
                        ? AppColors.brandGreen
                        : AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
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
          curveSmoothness: TrendChartCard._curveSmoothness,
          preventCurveOverShooting: true,
          isStrokeCapRound: true,
          color: AppColors.brandGreen,
          barWidth: 2.5,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) {
              final highlight = index == selectedIndex;
              return FlDotCirclePainter(
                radius: highlight ? 5 : 4,
                color: AppColors.white,
                strokeWidth: highlight ? 2.5 : 1.5,
                strokeColor: AppColors.brandGreen,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.brandGreen.withValues(alpha: 0.58),
                AppColors.brandGreen.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _yLabel(double value) {
    if (value <= 0) return '0';
    return '${(value / 1000).round()}K';
  }
}

class _TrendTooltip extends StatelessWidget {
  final String text;

  const _TrendTooltip({required this.text});

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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
      ),
    );
  }
}
