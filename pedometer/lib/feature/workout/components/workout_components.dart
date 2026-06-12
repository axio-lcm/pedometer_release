import 'package:flutter/material.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';

/// 绿色渐变胶囊主按钮，带轻微发光。
class GradientActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  const GradientActionButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
  });

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
            colors: [AppColors.brandGreenLight, AppColors.brandGreen],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandGreen.withValues(alpha: 0.45),
              blurRadius: 22,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.bgPrimary, size: 20),
              SizedBox(width: AppSpacing.sm),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.bgPrimary,
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

/// 运动类型横向选择条：4 个等宽小卡片，适配小屏。
class WorkoutTypeSelector extends StatelessWidget {
  final List<WorkoutType> types;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  const WorkoutTypeSelector({
    super.key,
    required this.types,
    required this.selectedIndex,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // 卡片为方形（AspectRatio 提供有界高度），等宽 Expanded → 自然等高。
    return Row(
      children: [
        for (var i = 0; i < types.length; i++) ...[
          Expanded(
            child: WorkoutTypeCard(
              type: types[i],
              selected: i == selectedIndex,
              onTap: onSelected == null ? null : () => onSelected!(i),
            ),
          ),
          if (i != types.length - 1) SizedBox(width: AppSpacing.md),
        ],
      ],
    );
  }
}

/// 单个运动类型卡片：圆形玻璃底座图标 + 文案，选中态绿描边/发光/右上勾。
class WorkoutTypeCard extends StatelessWidget {
  final WorkoutType type;
  final bool selected;
  final VoidCallback? onTap;

  const WorkoutTypeCard({
    super.key,
    required this.type,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1, // 方形展示框
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: GlassCard(
                radius: AppRadius.md,
                glow: selected,
                borderColor: selected ? AppColors.strokeGreen : null,
                padding: EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 图标随方形尺寸自适应缩放，保证窄屏不溢出。
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _IconBadge(icon: type.icon, color: type.color),
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        type.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected
                              ? AppColors.brandGreen
                              : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (selected)
              Positioned(
                top: AppSpacing.xs,
                right: AppSpacing.xs,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brandGreen,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandGreen.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: AppColors.bgPrimary,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 圆形玻璃底座图标：功能色低透明填充 + 同色描边。
class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}

/// 运动 Hero 主视觉卡片：标题 + 副信息 + 开始按钮，右侧为插画占位。
class WorkoutHeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onStart;

  const WorkoutHeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xl,
      glow: true,
      borderColor: AppColors.strokeGreen,
      padding: EdgeInsets.all(AppSpacing.xxl),
      child: SizedBox(
        height: 230,
        child: Stack(
          children: [
            // 复杂插画（夜间森林跑道 / 3D 跑步人物）先占位，后续替换素材。
            Positioned(
              right: 0,
              bottom: 0,
              child: WorkoutHeroIllustrationPlaceholder(),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: AppColors.brandGreen,
                      size: 18,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GradientActionButton(
                    label: actionLabel ?? WorkoutResource.startWorkout,
                    icon: Icons.play_arrow_rounded,
                    onTap: onStart,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Hero 插画占位：透明承载 + 轻量霓虹氛围，后续替换为 PNG / WebP / Lottie。
class WorkoutHeroIllustrationPlaceholder extends StatelessWidget {
  final double width;
  final double height;

  const WorkoutHeroIllustrationPlaceholder({
    super.key,
    this.width = 150,
    this.height = 170,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: Container(
          width: width * 0.8,
          height: height * 0.8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.brandGreen.withValues(alpha: 0.18),
                Colors.transparent,
              ],
            ),
          ),
          child: Icon(
            Icons.directions_run_rounded,
            color: AppColors.brandGreen.withValues(alpha: 0.32),
            size: 72,
          ),
        ),
      ),
    );
  }
}

/// 运动目标与成就大卡片：目标概览 + 成就徽章两段式。
class GoalAchievementCard extends StatelessWidget {
  final List<GoalMetric> metrics;
  final List<Achievement> achievements;
  final VoidCallback? onEdit;
  final VoidCallback? onViewMore;

  const GoalAchievementCard({
    super.key,
    required this.metrics,
    required this.achievements,
    this.onEdit,
    this.onViewMore,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xxl,
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  WorkoutResource.goalAchievementTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _TextAction(label: WorkoutResource.edit, onTap: onEdit),
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    WorkoutResource.goalAchievementHint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.accentOrange,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < metrics.length; i++) ...[
                  Expanded(child: GoalMetricCard(metric: metrics[i])),
                  if (i != metrics.length - 1) SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          Divider(height: 1, color: AppColors.divider),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  WorkoutResource.achievementBadge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              _TextAction(label: WorkoutResource.viewMore, onTap: onViewMore),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < achievements.length; i++)
                Expanded(child: AchievementBadge(data: achievements[i])),
            ],
          ),
        ],
      ),
    );
  }
}

/// 卡片右侧文字动作入口。
class _TextAction extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _TextAction({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// 单个目标指标小卡片：图标 + 标题 + 数值（数字/单位分离，FittedBox 防溢出）。
class GoalMetricCard extends StatelessWidget {
  final GoalMetric metric;

  const GoalMetricCard({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.md,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(metric.icon, color: metric.color, size: 16),
              SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  metric.title,
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  metric.value,
                  maxLines: 1,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (metric.unit.isNotEmpty) ...[
                  const SizedBox(width: 3),
                  Text(
                    metric.unit,
                    maxLines: 1,
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 成就徽章占位：霓虹发光玻璃底座 + 图标 + 标题，后续可替换为图片资源。
class AchievementBadge extends StatelessWidget {
  final Achievement data;

  const AchievementBadge({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                data.color.withValues(alpha: 0.30),
                data.color.withValues(alpha: 0.12),
              ],
            ),
            border: Border.all(color: data.color.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: data.color.withValues(alpha: 0.40),
                blurRadius: 24,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Icon(data.icon, color: data.color, size: 32),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          data.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: data.color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
