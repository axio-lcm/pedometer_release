import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/workout/components/edit_sport_goal_components.dart';
import 'package:pedometer/feature/workout/components/workout_components.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';

/// 运动完成 Hero：发光六边形 + 勾选 + 彩纸，主副标题。
class ExerciseCompleteHero extends StatelessWidget {
  /// 图标区域 key：供页面定位礼花发射点。
  final Key? iconAreaKey;

  const ExerciseCompleteHero({super.key, this.iconAreaKey});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          key: iconAreaKey,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: const [
              _ConfettiLayer(),
              _HexagonCheckBadge(),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        Text(
          WorkoutResource.resultCompleteTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          WorkoutResource.resultCompleteSubtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
      ],
    );
  }
}

/// 发光六边形徽章 + 中心勾选图标。六边形用 CustomPaint 绘制。
class _HexagonCheckBadge extends StatelessWidget {
  const _HexagonCheckBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背后柔和绿色光晕。
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.brandGreen.withValues(alpha: 0.34),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          CustomPaint(size: const Size(130, 130), painter: _HexagonPainter()),
          Icon(
            Icons.check_rounded,
            color: AppColors.brandGreenLight,
            size: 64,
          ),
        ],
      ),
    );
  }
}

class _HexagonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = math.pi / 180 * (60 * i - 90);
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    path.close();

    final glow = Paint()
      ..color = AppColors.brandGreen.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final stroke = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.brandGreenLight, AppColors.brandGreen],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = AppColors.brandGreen.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, glow);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 彩纸粒子占位层：若干小色块，后续可替换为图片 / Lottie。
class _ConfettiLayer extends StatelessWidget {
  const _ConfettiLayer();

  static const _pieces = <_ConfettiPiece>[
    _ConfettiPiece(left: 24, top: 24, color: Color(0xFF0CD9FF), angle: 0.4),
    _ConfettiPiece(right: 30, top: 14, color: Color(0xFFFF9F12), angle: -0.6),
    _ConfettiPiece(left: 54, top: 70, color: Color(0xFF24F04E), angle: 0.9),
    _ConfettiPiece(right: 48, top: 64, color: Color(0xFFB7FF24), angle: 0.2),
    _ConfettiPiece(left: 14, top: 104, color: Color(0xFFFF9F12), angle: -0.3),
    _ConfettiPiece(right: 18, top: 110, color: Color(0xFF3D7CFF), angle: 0.7),
    _ConfettiPiece(left: 96, top: 18, color: Color(0xFFB7FF24), angle: -0.5),
    _ConfettiPiece(right: 96, top: 30, color: Color(0xFF24F04E), angle: 0.5),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(children: _pieces);
  }
}

class _ConfettiPiece extends StatelessWidget {
  final double? left;
  final double? right;
  final double top;
  final Color color;
  final double angle;

  const _ConfettiPiece({
    this.left,
    this.right,
    required this.top,
    required this.color,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: 10,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// 运动结果总览卡片：类型 / 时间 / 距离 + 2×3 统计网格。
class ExerciseResultSummaryCard extends StatelessWidget {
  final ExerciseResultData data;

  const ExerciseResultSummaryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xl,
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              CircleIconBadge(
                icon: Icons.directions_run_rounded,
                color: AppColors.brandGreen,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.sportType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxs),
                    Text(
                      data.dateText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      data.distance,
                      maxLines: 1,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 34,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      data.distanceUnit,
                      maxLines: 1,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          Divider(height: 1, color: AppColors.divider),
          SizedBox(height: AppSpacing.sm),
          _MetricGrid(metrics: data.metrics),
        ],
      ),
    );
  }
}

/// 2 行 × 3 列统计网格，列/行间细分割线。
class _MetricGrid extends StatelessWidget {
  final List<ExerciseResultMetric> metrics;

  const _MetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row * 3 < metrics.length; row++) ...[
          if (row != 0) Divider(height: 1, color: AppColors.divider),
          Row(
            children: [
              for (var col = 0; col < 3; col++) ...[
                if (col != 0)
                  Container(width: 1, height: 44, color: AppColors.divider),
                Expanded(
                  child: row * 3 + col < metrics.length
                      ? ResultMetricItem(metric: metrics[row * 3 + col])
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// 单个统计项：图标 + 标题（顶部一行），数值（下方大号白字）。
class ResultMetricItem extends StatelessWidget {
  final ExerciseResultMetric metric;

  const ResultMetricItem({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(metric.icon, color: metric.color, size: 16),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              metric.value,
              maxLines: 1,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 暗色玻璃次级按钮（完成）。
class SecondaryGlassButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const SecondaryGlassButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.full),
          gradient: LinearGradient(
            colors: [AppColors.surfaceCardTop, AppColors.surfaceCardBottom],
          ),
          border: Border.all(color: AppColors.strokeCard),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 底部操作按钮区：完成（次级玻璃）+ 分享（绿色渐变主按钮）。
class ExerciseResultActionButtons extends StatelessWidget {
  final VoidCallback? onDone;
  final VoidCallback? onShare;

  const ExerciseResultActionButtons({super.key, this.onDone, this.onShare});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SecondaryGlassButton(
            label: WorkoutResource.resultDone,
            onTap: onDone,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: GradientActionButton(
            label: WorkoutResource.resultShare,
            icon: Icons.ios_share_rounded,
            onTap: onShare,
          ),
        ),
      ],
    );
  }
}
