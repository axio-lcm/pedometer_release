import 'package:flutter/material.dart';
import 'package:pedometer/common/config/app_colors.dart';

/// 通用顶部导航：固定返回按钮，标题与右侧操作由调用方按需传入。
class AppTopNavigationBar extends StatelessWidget {
  final String? title;
  final VoidCallback onBack;
  final IconData? rightIcon;
  final VoidCallback? onRightTap;

  /// 标题左侧切换箭头回调（如「上一周」）。为空则不显示左箭头。
  final VoidCallback? onTitlePrev;

  /// 标题右侧切换箭头回调（如「下一周」）。为空或 disabled 时箭头变暗且不可点。
  final VoidCallback? onTitleNext;

  /// 右侧箭头是否可用，false 时变暗并禁用点击（如已到当前周不能再往后）。
  final bool titleNextEnabled;

  const AppTopNavigationBar({
    super.key,
    required this.onBack,
    this.title,
    this.rightIcon,
    this.onRightTap,
    this.onTitlePrev,
    this.onTitleNext,
    this.titleNextEnabled = true,
  });

  bool get _showTitleArrows => onTitlePrev != null || onTitleNext != null;

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
              padding: EdgeInsets.symmetric(
                horizontal: _showTitleArrows ? 56 : 70,
              ),
              child: _showTitleArrows
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TitleArrow(
                          icon: Icons.chevron_left_rounded,
                          onTap: onTitlePrev,
                        ),
                        const SizedBox(width: 4),
                        Flexible(child: _titleText()),
                        const SizedBox(width: 4),
                        _TitleArrow(
                          icon: Icons.chevron_right_rounded,
                          onTap: titleNextEnabled ? onTitleNext : null,
                        ),
                      ],
                    )
                  : _titleText(),
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

  Widget _titleText() {
    return Text(
      title!,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// 标题两侧的小切换箭头，onTap 为空时变暗且不可点击。
class _TitleArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _TitleArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 26,
          color: AppColors.textPrimary.withValues(
            alpha: enabled ? 1.0 : 0.3,
          ),
        ),
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
