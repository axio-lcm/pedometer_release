import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/common/config/app_metric_assets.dart';
import 'package:pedometer/common/config/localized_text.dart';
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

  /// 一周（×7）/ 一月（×当月天数）总目标步数提示。
  String _stepsTotalsHint(int weekly, int monthly) {
    final fmt = NumberFormat.decimalPattern();
    final w = fmt.format(weekly);
    final m = fmt.format(monthly);
    return lt('Weekly $w · Monthly $m steps', '一周 $w 步 · 一月 $m 步');
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
                          () => GoalAdjustCard(
                            iconAsset: AppMetricAssets.syncSteps,
                            color: AppColors.accentPurple,
                            title: WorkoutResource.targetSteps,
                            value: '${controller.steps.value}',
                            unit: WorkoutResource.stepUnit,
                            // 提示展示按日目标换算出的一周 / 一月总目标步数。
                            suggestion: _stepsTotalsHint(
                              controller.weeklyStepGoal,
                              controller.monthlyStepGoal,
                            ),
                            // 每日步数目标与「自由训练」无关，始终可调。
                            enabled: true,
                            onDecrease: () => controller.changeSteps(
                              -EditSportGoalViewModel.stepsStep,
                            ),
                            onIncrease: () => controller.changeSteps(
                              EditSportGoalViewModel.stepsStep,
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
                        GoalSuggestionCard(
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
