import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/home/model/home_model.dart';

/// 底部分析小卡：标题 + 大数字 + 变化 + fl_chart 平滑曲线（末端发光节点）。
class MiniAnalysisCard extends StatelessWidget {
  final AnalysisData data;
  final IconData icon;
  const MiniAnalysisCard({super.key, required this.data, required this.icon});

  static const double _curveSmoothness = 0.56;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xl,
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: data.color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          // 数字 + 单位：缩放兜底，小屏不溢出
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Text(data.unit, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${data.delta} ↑',
            style: TextStyle(color: data.color, fontSize: 12),
          ),
          SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 40,
            width: double.infinity,
            child: LineChart(_chartData(), duration: Duration.zero),
          ),
        ],
      ),
    );
  }

  LineChartData _chartData() {
    final lastX = (data.samples.length - 1).toDouble();
    final spots = <FlSpot>[
      for (var i = 0; i < data.samples.length; i++)
        FlSpot(i.toDouble(), data.samples[i]),
    ];
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
          spots: spots,
          isCurved: true,
          curveSmoothness: _curveSmoothness,
          preventCurveOverShooting: true,
          isStrokeCapRound: true,
          color: data.color,
          barWidth: 2,
          dotData: FlDotData(
            show: true,
            // 只在末端（最新点）显示一个发光节点
            checkToShowDot: (spot, bar) => spot.x == lastX,
            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
              radius: 3,
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
                data.color.withValues(alpha: 0.5),
                data.color.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
