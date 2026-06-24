import 'package:flutter/material.dart';
import 'package:pedometer/common/component/asset_metric_icon.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_resource.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';

/// 绿色渐变胶囊主按钮，默认带轻微发光，可通过 [glow] 关闭。
class GradientActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool glow;

  const GradientActionButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.glow = true,
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
            if (glow)
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
                glow: false,
                borderColor: selected ? AppColors.strokeGreen : null,
                padding: EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 图标随方形尺寸自适应缩放，保证窄屏不溢出。
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _IconBadge(
                          icon: type.icon,
                          iconAsset: type.iconAsset,
                          color: type.color,
                        ),
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
  final String? iconAsset;
  final Color color;

  const _IconBadge({required this.icon, this.iconAsset, required this.color});

  @override
  Widget build(BuildContext context) {
    if (iconAsset != null) {
      return SizedBox(
        width: 50,
        height: 50,
        child: AssetMetricIcon(assetName: iconAsset!, size: 50),
      );
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Center(child: Icon(icon, color: color, size: 26)),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.strokeCard, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: SizedBox(
          height: 230,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 背景板：bkimage.png 铺满整张卡片，缺失时回退占位。
              Image.asset(
                AppImage.workoutHeroBackground,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const _WorkoutHeroFallbackBackground(),
              ),
              // 左侧暗角，保证文本在任意背景上的可读性。
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: Column(
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
                        glow: false,
                        onTap: onStart,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hero 卡背景板缺失时的回退：玻璃渐变 + 角落跑步插画占位。
class _WorkoutHeroFallbackBackground extends StatelessWidget {
  const _WorkoutHeroFallbackBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceCardTop, AppColors.surfaceCardBottom],
        ),
      ),
      child: const Align(
        alignment: Alignment.bottomRight,
        child: WorkoutHeroIllustrationPlaceholder(),
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
              _TextAction(label: WorkoutResource.edit, onTap: onEdit),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          _GoalMetricGrid(metrics: metrics),
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

/// 目标指标网格：每行 2 个，整体更大、标题与数值完整展示不省略。
class _GoalMetricGrid extends StatelessWidget {
  final List<GoalMetric> metrics;

  const _GoalMetricGrid({required this.metrics});

  static const int _perRow = 2;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < metrics.length; i += _perRow) {
      final cells = <Widget>[];
      for (var c = 0; c < _perRow; c++) {
        final index = i + c;
        if (c != 0) cells.add(SizedBox(width: AppSpacing.md));
        cells.add(
          Expanded(
            child: index < metrics.length
                ? GoalMetricCard(metric: metrics[index])
                : const SizedBox.shrink(),
          ),
        );
      }
      if (rows.isNotEmpty) rows.add(SizedBox(height: AppSpacing.md));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cells,
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

/// 单个目标指标小卡片：图标 + 标题 + 数值（数字/单位分离，FittedBox 防溢出）。
class GoalMetricCard extends StatelessWidget {
  final GoalMetric metric;

  const GoalMetricCard({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.lg,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(metric.icon, color: metric.color, size: 18),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  metric.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
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
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (metric.unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    metric.unit,
                    maxLines: 1,
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 13,
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

/// 成就徽章：图片徽章 + 标题，无发光。
class AchievementBadge extends StatelessWidget {
  final Achievement data;

  const AchievementBadge({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          data.imageAsset,
          width: 110,
          height: 110,
          fit: BoxFit.contain,
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          data.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
