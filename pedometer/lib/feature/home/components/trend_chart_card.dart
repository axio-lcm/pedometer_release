import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/home/model/home_model.dart';
import 'package:pedometer/feature/home/resources/home_resource.dart';

/// 趋势大卡：标题 + fl_chart 平滑曲线（渐变填充 + 发光节点）。
class TrendChartCard extends StatelessWidget {
  final List<TrendPoint> points;
  const TrendChartCard({super.key, required this.points});

  static const double _maxY = 8000;
  static const double _curveSmoothness = 0.56;

  @override
  Widget build(BuildContext context) {
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
            child: LineChart(_chartData(), duration: Duration.zero),
          ),
        ],
      ),
    );
  }

  LineChartData _chartData() {
    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].value),
    ];
    return LineChartData(
      minX: 0,
      maxX: (points.length - 1).toDouble(),
      minY: 0,
      maxY: _maxY,
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
            reservedSize: 30,
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
            reservedSize: 22,
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i < 0 || i >= points.length) return const SizedBox.shrink();
              final p = points[i];
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  p.label,
                  style: TextStyle(
                    color: p.highlight
                        ? AppColors.brandGreen
                        : AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: p.highlight ? FontWeight.w700 : FontWeight.w400,
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
          curveSmoothness: _curveSmoothness,
          preventCurveOverShooting: true,
          isStrokeCapRound: true,
          color: AppColors.brandGreen,
          barWidth: 2.5,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) {
              final highlight = points[index].highlight;
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
