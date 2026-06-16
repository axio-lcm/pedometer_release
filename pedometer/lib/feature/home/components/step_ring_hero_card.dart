import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/home/components/walking_scene_placeholder.dart';
import 'package:pedometer/feature/home/model/home_model.dart';
import 'package:pedometer/feature/home/resources/home_resource.dart';

/// 主步数圆环卡：自绘缺口圆环 + 标题 + 超大数字 + 目标 + 达成胶囊 + 场景占位。
class StepRingHeroCard extends StatelessWidget {
  final StepData step;
  const StepRingHeroCard({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    // 圆环半径随屏宽自适应（封顶 86），避免小屏溢出卡片边框。
    // 不用 LayoutBuilder：本卡处于外层 IntrinsicHeight 中，LayoutBuilder 不支持固有尺寸测量。
    // 假设 hero 卡片占主行 5/9 宽（页面左右边距 16、主行间距 12、卡片左右内边距 xxs）。
    final screenW = MediaQuery.of(context).size.width;
    final heroInner =
        (screenW - 2 * AppSpacing.lg - AppSpacing.md) * 5 / 9 -
        2 * AppSpacing.xxs;
    final radius = ((heroInner - 4) / 2).clamp(60.0, 86.0);
    const sceneHeight = 98.0;
    return GlassCard(
      radius: AppRadius.xxl,
      glow: true,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxs,
        AppSpacing.lg,
        AppSpacing.xxs,
        AppSpacing.md,
      ),
      child: SizedBox(
        height: radius * 2 + sceneHeight * 0.7,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            StepRingArc(
              radius: radius,
              lineWidth: radius >= 78 ? 15 : 13,
              percent: step.progress,
              backgroundColor: AppColors.brandGreenDark.withValues(alpha: 0.55),
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [
                  const Color(0xFF00B956),
                  AppColors.brandGreen,
                  AppColors.brandGreenLight,
                ],
              ),
              center: _center(radius),
            ),
            Positioned(
              left: AppSpacing.xxs,
              right: AppSpacing.xxs,
              bottom: 0,
              child: WalkingSceneOverlay(
                height: sceneHeight,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _center(double radius) {
    // 限制中心内容宽度，避免大数字溢出较小的圆环内圈（随半径自适应）。
    return SizedBox(
      width: (radius * 2 - 22).clamp(96.0, 146.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            HomeResource.todaySteps,
            style: TextStyle(color: AppColors.brandGreen, fontSize: 13),
          ),
          const SizedBox(height: 3),
          FittedBox(
            child: Text(
              _formatThousand(step.steps),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 40,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '/ ${_formatThousand(step.goal)} ${HomeResource.goalSuffix}',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, color: AppColors.brandLime, size: 13),
                const SizedBox(width: 3),
                Text(
                  '${HomeResource.achieved} ${step.percent}%',
                  style: TextStyle(
                    color: AppColors.brandLime,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 千分位（无 intl 依赖的本地实现；后续可换 NumberFormat）。
  String _formatThousand(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

/// 底部留缺口的主步数圆环。
class StepRingArc extends StatelessWidget {
  static const double defaultGapDegrees = 58;

  final double radius;
  final double lineWidth;
  final double percent;
  final double gapDegrees;
  final Color backgroundColor;
  final Gradient gradient;
  final Widget center;

  const StepRingArc({
    super.key,
    required this.radius,
    required this.lineWidth,
    required this.percent,
    required this.backgroundColor,
    required this.gradient,
    required this.center,
    this.gapDegrees = defaultGapDegrees,
  });

  double get sweepDegrees => 360 - gapDegrees;

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;
    return SizedBox.square(
      dimension: diameter,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _StepRingArcPainter(
              lineWidth: lineWidth,
              percent: percent,
              gapDegrees: gapDegrees,
              backgroundColor: backgroundColor,
              gradient: gradient,
            ),
          ),
          Center(child: center),
        ],
      ),
    );
  }
}

class _StepRingArcPainter extends CustomPainter {
  final double lineWidth;
  final double percent;
  final double gapDegrees;
  final Color backgroundColor;
  final Gradient gradient;

  const _StepRingArcPainter({
    required this.lineWidth,
    required this.percent,
    required this.gapDegrees,
    required this.backgroundColor,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - lineWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepDegrees = 360 - gapDegrees;
    final startDegrees = 90 + gapDegrees / 2;
    final startAngle = _degreesToRadians(startDegrees);
    final sweepAngle = _degreesToRadians(sweepDegrees);
    final progressSweep = _degreesToRadians(
      sweepDegrees * percent.clamp(0.0, 1.0),
    );

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = lineWidth;
    canvas.drawArc(rect, startAngle, sweepAngle, false, backgroundPaint);

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = lineWidth;
    canvas.drawArc(rect, startAngle, progressSweep, false, progressPaint);
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;

  @override
  bool shouldRepaint(covariant _StepRingArcPainter oldDelegate) {
    return oldDelegate.lineWidth != lineWidth ||
        oldDelegate.percent != percent ||
        oldDelegate.gapDegrees != gapDegrees ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.gradient != gradient;
  }
}
