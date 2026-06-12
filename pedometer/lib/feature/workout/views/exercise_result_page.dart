import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/workout/components/exercise_result_components.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';

/// 运动结束（运动完成）结果页：长按结束运动后进入。
class ExerciseResultPage extends StatelessWidget {
  static const String routeName = WorkoutRouteTable.pathResult;

  final ExerciseResultData data;
  final VoidCallback? onDone;
  final VoidCallback? onShare;

  const ExerciseResultPage({
    super.key,
    this.data = ExerciseResultData.mock,
    this.onDone,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorkoutResource.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _ExerciseResultBackground()),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTopNavigationBar(title: data.sportType, onBack: _back),
                  SizedBox(height: AppSpacing.sm),
                  const ExerciseCompleteHero(),
                  SizedBox(height: AppSpacing.xl),
                  ExerciseResultSummaryCard(data: data),
                  SizedBox(height: AppSpacing.xl),
                  ExerciseResultActionButtons(
                    onDone: onDone ?? _back,
                    // TODO: 接入真实分享逻辑。
                    onShare: onShare,
                  ),
                  SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _back() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back<void>();
    }
  }
}

class _ExerciseResultBackground extends StatelessWidget {
  const _ExerciseResultBackground();

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
            top: 80,
            left: -70,
            right: -70,
            height: 320,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.bgRadialGreen.withValues(alpha: 0.55),
                    AppColors.bgRadialBlue.withValues(alpha: 0.14),
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
