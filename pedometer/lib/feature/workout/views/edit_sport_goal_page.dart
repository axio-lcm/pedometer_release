import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/common/config/app_metric_assets.dart';
import 'package:pedometer/feature/workout/components/edit_sport_goal_components.dart';
import 'package:pedometer/feature/workout/components/workout_components.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';
import 'package:pedometer/feature/workout/viewmodel/edit_sport_goal_view_model.dart';

/// 编辑运动目标页：由运动页「编辑」进入，调节距离 / 时长 / 消耗与自由训练开关。
class EditSportGoalPage extends GetView<EditSportGoalViewModel> {
  static const String routeName = WorkoutRouteTable.pathEditGoal;

  const EditSportGoalPage({super.key});

  void _save() {
    controller.save();
    _back();
  }

  void _back() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back<void>();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorkoutResource.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _EditGoalBackground()),
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
                    title: WorkoutResource.editGoalTitle,
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
                        Text(
                          WorkoutResource.editGoalSubtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xl),
                        Obx(
                          () => GoalAdjustCard(
                            iconAsset: AppMetricAssets.editGoalDistance,
                            color: AppColors.brandGreen,
                            title: WorkoutResource.targetDistance,
                            value: controller.distance.value.toStringAsFixed(2),
                            unit: WorkoutResource.distanceUnit,
                            suggestion:
                                WorkoutResource.targetDistanceSuggestion,
                            enabled: controller.adjustEnabled,
                            onDecrease: () => controller.changeDistance(
                              -EditSportGoalViewModel.distanceStep,
                            ),
                            onIncrease: () => controller.changeDistance(
                              EditSportGoalViewModel.distanceStep,
                            ),
                          ),
                        ),
                        SizedBox(height: AppSpacing.lg),
                        Obx(
                          () => GoalAdjustCard(
                            iconAsset: AppMetricAssets.editGoalDuration,
                            color: AppColors.accentCyan,
                            title: WorkoutResource.targetDuration,
                            value: '${controller.duration.value}',
                            unit: WorkoutResource.durationUnit,
                            suggestion:
                                WorkoutResource.targetDurationSuggestion,
                            enabled: controller.adjustEnabled,
                            onDecrease: () => controller.changeDuration(
                              -EditSportGoalViewModel.durationStep,
                            ),
                            onIncrease: () => controller.changeDuration(
                              EditSportGoalViewModel.durationStep,
                            ),
                          ),
                        ),
                        SizedBox(height: AppSpacing.lg),
                        Obx(
                          () => GoalAdjustCard(
                            iconAsset: AppMetricAssets.editGoalCalorie,
                            color: AppColors.accentOrange,
                            title: WorkoutResource.targetCalorie,
                            value: '${controller.calories.value}',
                            unit: 'kcal',
                            suggestion: WorkoutResource.targetCalorieSuggestion,
                            enabled: controller.adjustEnabled,
                            onDecrease: () => controller.changeCalories(
                              -EditSportGoalViewModel.caloriesStep,
                            ),
                            onIncrease: () => controller.changeCalories(
                              EditSportGoalViewModel.caloriesStep,
                            ),
                          ),
                        ),
                        SizedBox(height: AppSpacing.lg),
                        Obx(
                          () => FreeTrainingCard(
                            value: controller.freeTraining.value,
                            onChanged: controller.setFreeTraining,
                          ),
                        ),
                        SizedBox(height: AppSpacing.lg),
                        const GoalSuggestionCard(
                          suggestions: EditSportGoalViewModel.suggestions,
                        ),
                        SizedBox(height: AppSpacing.xl),
                        GradientActionButton(
                          label: WorkoutResource.saveGoal,
                          onTap: _save,
                        ),
                        SizedBox(height: AppSpacing.md),
                        Center(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: controller.restoreDefaults,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                              ),
                              child: Text(
                                WorkoutResource.restoreDefault,
                                style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: AppSpacing.lg),
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

class _EditGoalBackground extends StatelessWidget {
  const _EditGoalBackground();

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
            top: 100,
            left: -80,
            right: -80,
            height: 300,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.bgRadialGreen.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: -90,
            right: -90,
            height: 320,
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
