import 'package:flutter/material.dart';
import 'package:pedometer/common/config/app_colors.dart';

/// 通用顶部导航：固定返回按钮，标题与右侧操作由调用方按需传入。
class AppTopNavigationBar extends StatelessWidget {
  final String? title;
  final VoidCallback onBack;
  final IconData? rightIcon;
  final VoidCallback? onRightTap;

  const AppTopNavigationBar({
    super.key,
    required this.onBack,
    this.title,
    this.rightIcon,
    this.onRightTap,
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
          if (title != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 70),
              child: Text(
                title!,
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
          if (rightIcon != null)
            Align(
              alignment: Alignment.centerRight,
              child: _GlassIconButton(
                icon: rightIcon!,
                onTap: onRightTap,
                size: 44,
                iconSize: 24,
              ),
            ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
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
