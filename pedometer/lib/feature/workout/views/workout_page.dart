import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/workout/components/workout_components.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';
import 'package:pedometer/feature/workout/viewmodel/workout_view_model.dart';
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
    Get.toNamed(
      WorkoutTrackingPage.routeName,
      arguments: controller.selectedWorkoutType,
    );
  }

  void _onEdit() => Get.toNamed(EditSportGoalPage.routeName);

  // TODO: 接入成就列表入口。
  void _onViewMore() {}
}

class _WorkoutBackground extends StatelessWidget {
  const _WorkoutBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bgPrimary,
            AppColors.bgRadialBlue,
            AppColors.bgPrimary,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 120,
            left: -80,
            right: -80,
            height: 320,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.bgRadialGreen.withValues(alpha: 0.5),
                    AppColors.bgRadialBlue.withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -90,
            right: -90,
            height: 340,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.brandGreenDark.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
