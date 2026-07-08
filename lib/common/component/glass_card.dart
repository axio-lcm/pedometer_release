import 'package:flutter/material.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';

/// Liquid Glass 半透明玻璃卡片：渐变 + 白描边 + 暗阴影（可选绿色发光）。
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;
  final bool glow;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius,
    this.glow = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius ?? AppRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceCardTop, AppColors.surfaceCardBottom],
        ),
        border: Border.all(
          color: borderColor ?? AppColors.strokeCard,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          if (glow)
            BoxShadow(
              color: AppColors.brandGreen.withValues(alpha: 0.22),
              blurRadius: 28,
              spreadRadius: -4,
            ),
        ],
      ),
      child: child,
    );
  }
}
