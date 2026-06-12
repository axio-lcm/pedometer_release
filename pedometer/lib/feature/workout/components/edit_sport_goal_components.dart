import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';

/// 圆形玻璃底座图标：深色玻璃 + 功能色描边与柔和发光。
class CircleIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const CircleIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.22), AppColors.surfaceIcon],
        ),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.30),
            blurRadius: 16,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: size * 0.46),
    );
  }
}

/// 圆形加减调节按钮。
class RoundAdjustButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  const RoundAdjustButton({
    super.key,
    required this.icon,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceIcon.withValues(alpha: 0.5),
            border: Border.all(color: AppColors.strokeCard),
          ),
          child: Icon(icon, color: AppColors.textSecondary, size: 20),
        ),
      ),
    );
  }
}

/// 可复用目标编辑卡片：图标 + 标题/当前值（左），减号-数值-加号 + 建议（右）。
class GoalAdjustCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String unit;
  final String suggestion;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  /// 自由训练开启时置为 false：调节按钮与数值弱化展示。
  final bool enabled;

  const GoalAdjustCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.unit,
    required this.suggestion,
    this.onDecrease,
    this.onIncrease,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xl,
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          CircleIconBadge(icon: icon, color: color),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        maxLines: 1,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        unit,
                        maxLines: 1,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: enabled ? 1 : 0.5,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RoundAdjustButton(
                      icon: Icons.remove_rounded,
                      onTap: onDecrease,
                      enabled: enabled,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: 56,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          value,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: color,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    RoundAdjustButton(
                      icon: Icons.add_rounded,
                      onTap: onIncrease,
                      enabled: enabled,
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  suggestion,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: AppColors.textTertiary,
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

/// 自由训练开关卡片：图标 + 标题/文案（左），iOS 风格 Switch（右）。
class FreeTrainingCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const FreeTrainingCard({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xl,
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          CircleIconBadge(
            icon: Icons.all_inclusive_rounded,
            color: AppColors.accentPurple,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '自由训练',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  '不设定目标',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  '开启后将不设定任何目标',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.brandGreen,
          ),
        ],
      ),
    );
  }
}

/// 目标建议说明卡片：绿色提示标题 + 要点列表。
class GoalSuggestionCard extends StatelessWidget {
  final List<String> suggestions;

  const GoalSuggestionCard({super.key, required this.suggestions});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xl,
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.brandGreen,
                size: 18,
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                '目标建议',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.brandGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          for (var i = 0; i < suggestions.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == suggestions.length - 1 ? 0 : AppSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•  ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      suggestions[i],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
