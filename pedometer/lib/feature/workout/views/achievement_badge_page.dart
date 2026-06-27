import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/home/model/health_repository.dart';
import 'package:pedometer/feature/workout/model/achievement_stats_store.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';

/// 成就徽章页：3 列网格展示 12 枚徽章。
/// 已获得显示彩色徽章 + 「已获得」；未获得显示灰色徽章 + 进度条 + 「未获得」。
class AchievementBadgePage extends StatelessWidget {
  static const String routeName = WorkoutRouteTable.pathAchievement;

  const AchievementBadgePage({super.key});

  void _back() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back<void>();
    }
  }

  /// 步数达人 / 热量达人取自首页健康数据：历史单日最高步数、累计消耗 kcal。
  List<AchievementBadgeItem> _items() {
    final summaries = HealthSyncRuntime.activeSummaries;
    var maxDailySteps = 0;
    var totalCalories = 0.0;
    for (final s in summaries) {
      if (s.steps > maxDailySteps) maxDailySteps = s.steps;
      totalCalories += s.caloriesKcal;
    }
    return WorkoutAchievementCatalog.items(
      maxDailySteps: maxDailySteps,
      totalCalories: totalCalories,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorkoutResource.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _AchievementBackground()),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.lg,
                    0,
                  ),
                  child: AppTopNavigationBar(
                    title: WorkoutResource.achievementBadge,
                    onBack: _back,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: AppSpacing.sm),
                        // 运动结束后累积统计变更时刷新进度。
                        ValueListenableBuilder<int>(
                          valueListenable: AchievementStatsStore.revision,
                          builder: (context, _, _) =>
                              _BadgeGrid(items: _items()),
                        ),
                      ],
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

/// 3 列徽章网格。
class _BadgeGrid extends StatelessWidget {
  final List<AchievementBadgeItem> items;

  const _BadgeGrid({required this.items});

  static const int _perRow = 3;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += _perRow) {
      final cells = <Widget>[];
      for (var c = 0; c < _perRow; c++) {
        final index = i + c;
        if (c != 0) cells.add(SizedBox(width: AppSpacing.md));
        cells.add(
          Expanded(
            child: index < items.length
                ? _BadgeCell(item: items[index])
                : const SizedBox.shrink(),
          ),
        );
      }
      if (rows.isNotEmpty) rows.add(SizedBox(height: AppSpacing.md));
      rows.add(IntrinsicHeight(child: Row(children: cells)));
    }
    return Column(children: rows);
  }
}

/// 单个徽章卡片。
class _BadgeCell extends StatelessWidget {
  final AchievementBadgeItem item;

  /// 徽章图尺寸复用运动栏的 110×110；网格列较窄时按列宽自动缩放不溢出。
  static const double _badgeSize = 110;

  const _BadgeCell({required this.item});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xl,
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: _badgeSize,
              height: _badgeSize,
              child: Image.asset(item.imageAsset, fit: BoxFit.contain),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.25,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          const Spacer(),
          if (item.earned)
            const _EarnedTag()
          else
            _LockedStatus(progress: item.progress),
        ],
      ),
    );
  }
}

/// 已获得：绿色对勾 + 文案。
class _EarnedTag extends StatelessWidget {
  const _EarnedTag();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle, size: 15, color: AppColors.brandGreen),
        SizedBox(width: AppSpacing.xxs),
        Text(
          WorkoutResource.achievementEarned,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.brandGreen,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// 未获得：进度条 + 锁图标 + 文案。
class _LockedStatus extends StatelessWidget {
  final double progress;

  const _LockedStatus({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProgressBar(value: progress),
        SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 14,
              color: AppColors.textTertiary,
            ),
            SizedBox(width: AppSpacing.xxs),
            Text(
              WorkoutResource.achievementLocked,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 圆角绿色进度条。
class _ProgressBar extends StatelessWidget {
  final double value;

  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: SizedBox(
        height: 6,
        width: double.infinity,
        child: Stack(
          children: [
            // 未完成区域：铺满整行的灰色底槽（进度为 0 时也始终可见）。
            const Positioned.fill(child: ColoredBox(color: Color(0xFF2A323B))),
            // 已完成区域：按比例叠加的绿色填充。
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: clamped,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.brandGreenLight, AppColors.brandGreen],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 与运动二级页一致的渐变背景。
class _AchievementBackground extends StatelessWidget {
  const _AchievementBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bgPrimary,
            AppColors.bgRadialBlue.withValues(alpha: 0.72),
            AppColors.bgPrimary,
          ],
        ),
      ),
    );
  }
}
