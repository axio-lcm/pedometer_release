import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/subscription/config/subscription_config.dart';
import 'package:pedometer/feature/subscription/service/subscription_service.dart';
import 'package:pedometer/feature/workout/components/workout_components.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';
import 'package:pedometer/feature/workout/viewmodel/workout_view_model.dart';
import 'package:pedometer/feature/workout/views/achievement_badge_page.dart';
import 'package:pedometer/feature/workout/views/edit_sport_goal_page.dart';
import 'package:pedometer/feature/workout/views/workout_tracking_page.dart';

/// 运动 / 训练页：运动类型选择 + Hero 入口 + 目标与成就。
///
/// 由 MainPage 的底部三栏导航宿主，选中态为「运动」，故本页不自带底部导航。
class WorkoutPage extends GetView<WorkoutViewModel> {
  const WorkoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorkoutResource.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _WorkoutBackground()),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              // 底部留白避让 MainPage 的玻璃胶囊导航栏。
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                120,
              ),
              child: Obx(() {
                final data = controller.data.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WorkoutTypeSelector(
                      types: data.workoutTypes,
                      selectedIndex: controller.selectedType.value,
                      onSelected: controller.selectType,
                    ),
                    SizedBox(height: AppSpacing.lg),
                    WorkoutHeroCard(
                      title: data.heroTitle,
                      subtitle: data.heroSubtitle,
                      onStart: _onStart,
                    ),
                    SizedBox(height: AppSpacing.lg),
                    GoalAchievementCard(
                      metrics: data.goalMetrics,
                      achievements: data.achievements,
                      onEdit: _onEdit,
                      onViewMore: _onViewMore,
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _onStart() {
    Get.find<SubscriptionService>().navigateWithVipGate(
      destination: WorkoutTrackingPage.routeName,
      arguments: controller.selectedWorkoutType,
      source: SubscriptionSource.subscription,
    );
  }

  void _onEdit() => Get.toNamed(EditSportGoalPage.routeName);

  // TODO: 接入成就列表入口。
  void _onViewMore() => Get.toNamed(AchievementBadgePage.routeName);
}

class _WorkoutBackground extends StatelessWidget {
  const _WorkoutBackground();

  @override
  Widget build(BuildContext context) {
    // 与首页 / 我的页背景保持一致，统一顶部安全区底色。
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.6),
          radius: 1.2,
          colors: [AppColors.bgRadialBlue, AppColors.bgPrimary],
        ),
      ),
    );
  }
}
