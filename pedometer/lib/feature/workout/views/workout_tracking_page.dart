import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/workout/components/workout_tracking_components.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';
import 'package:pedometer/feature/workout/viewmodel/workout_tracking_controller.dart';
import 'package:pedometer/feature/workout/views/exercise_result_page.dart';

/// 点击「开始运动」后的运动记录中页面。
class WorkoutTrackingPage extends StatefulWidget {
  static const String routeName = WorkoutRouteTable.pathTracking;

  final WorkoutTrackingData data;

  const WorkoutTrackingPage({super.key, this.data = WorkoutTrackingData.mock});

  @override
  State<WorkoutTrackingPage> createState() => _WorkoutTrackingPageState();
}

class _WorkoutTrackingPageState extends State<WorkoutTrackingPage> {
  late final WorkoutTrackingController controller =
      Get.isRegistered<WorkoutTrackingController>()
      ? Get.find<WorkoutTrackingController>()
      : Get.put(WorkoutTrackingController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorkoutResource.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _WorkoutTrackingBackground()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: AppTopNavigationBar(
                    title: widget.data.workoutTitle,
                    onBack: _back,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: AppSpacing.xl),
                    child: Column(
                      children: [
                        WorkoutMapSection(data: widget.data),
                        const SizedBox(height: 4),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: Obx(() {
                            final data = _liveData();
                            return Column(
                              children: [
                                WorkoutMetricPanel(data: data),
                                const SizedBox(height: 28),
                                WorkoutControlPanel(
                                  data: data,
                                  onPrimaryTap: controller.togglePrimary,
                                  onEnd: _endWorkout,
                                ),
                                const SizedBox(
                                  height: AppBottomTabBarMetrics.bottomOffset,
                                ),
                                WorkoutMusicCard(data: data),
                              ],
                            );
                          }),
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

  void _back() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
      return;
    }
  }

  WorkoutTrackingData _liveData() {
    return widget.data.copyWith(
      status: controller.status.value,
      distanceKm: controller.distanceKmText,
      duration: controller.durationText,
      calories: controller.caloriesText,
      pace: controller.paceText,
    );
  }

  // 结束运动：聚合真实数据并跳结果页（替换记录中页，结果页「完成」回到运动主页）。
  void _endWorkout() {
    controller.end();
    Get.offNamed(
      ExerciseResultPage.routeName,
      arguments: controller.toResultData(),
    );
  }
}

class _WorkoutTrackingBackground extends StatelessWidget {
  const _WorkoutTrackingBackground();

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
      child: Stack(
        children: [
          Positioned(
            top: 130,
            left: -90,
            right: -90,
            height: 360,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.bgRadialGreen.withValues(alpha: 0.32),
                    AppColors.bgRadialBlue.withValues(alpha: 0.12),
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
