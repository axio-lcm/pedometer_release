import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/workout/components/edit_sport_goal_components.dart';
import 'package:pedometer/feature/workout/components/workout_components.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';

/// 编辑运动目标页：由运动页「编辑」进入，调节距离 / 时长 / 消耗与自由训练开关。
class EditSportGoalPage extends StatefulWidget {
  static const String routeName = WorkoutRouteTable.pathEditGoal;

  /// 保存目标回调，预留实际业务接入位置。
  final ValueChanged<SportGoalResult>? onSaved;

  const EditSportGoalPage({super.key, this.onSaved});

  @override
  State<EditSportGoalPage> createState() => _EditSportGoalPageState();
}

class _EditSportGoalPageState extends State<EditSportGoalPage> {
  // 默认值
  static const double _defaultDistance = 8.0;
  static const int _defaultDuration = 60;
  static const int _defaultCalories = 500;

  // 取值范围与步长
  static const double _distanceMin = 3.0;
  static const double _distanceMax = 20.0;
  static const double _distanceStep = 0.5;
  static const int _durationMin = 10;
  static const int _durationMax = 300;
  static const int _durationStep = 5;
  static const int _caloriesMin = 100;
  static const int _caloriesMax = 2000;
  static const int _caloriesStep = 50;

  static const List<String> _suggestions = [
    WorkoutText.suggestionDistance,
    WorkoutText.suggestionDuration,
    WorkoutText.suggestionCalorie,
  ];

  double _distance = _defaultDistance;
  int _duration = _defaultDuration;
  int _calories = _defaultCalories;
  bool _freeTraining = false;

  void _changeDistance(double delta) {
    setState(
      () => _distance = (_distance + delta).clamp(_distanceMin, _distanceMax),
    );
  }

  void _changeDuration(int delta) {
    setState(
      () => _duration = (_duration + delta).clamp(_durationMin, _durationMax),
    );
  }

  void _changeCalories(int delta) {
    setState(
      () => _calories = (_calories + delta).clamp(_caloriesMin, _caloriesMax),
    );
  }

  void _restoreDefaults() {
    setState(() {
      _distance = _defaultDistance;
      _duration = _defaultDuration;
      _calories = _defaultCalories;
      _freeTraining = false;
    });
  }

  void _save() {
    // TODO: 接入真实目标持久化逻辑。
    widget.onSaved?.call(
      SportGoalResult(
        distance: _distance,
        duration: _duration,
        calories: _calories,
        freeTraining: _freeTraining,
      ),
    );
    _back();
  }

  void _back() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back<void>();
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = !_freeTraining;
    return Scaffold(
      backgroundColor: WorkoutResource.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _EditGoalBackground()),
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
                  AppTopNavigationBar(
                    title: WorkoutResource.editGoalTitle,
                    onBack: _back,
                  ),
                  SizedBox(height: AppSpacing.sm),
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
                  GoalAdjustCard(
                    icon: Icons.adjust_rounded,
                    color: AppColors.brandGreen,
                    title: WorkoutResource.targetDistance,
                    value: _distance.toStringAsFixed(2),
                    unit: WorkoutResource.distanceUnit,
                    suggestion: WorkoutResource.targetDistanceSuggestion,
                    enabled: enabled,
                    onDecrease: () => _changeDistance(-_distanceStep),
                    onIncrease: () => _changeDistance(_distanceStep),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  GoalAdjustCard(
                    icon: Icons.timer_outlined,
                    color: AppColors.accentCyan,
                    title: WorkoutResource.targetDuration,
                    value: '$_duration',
                    unit: WorkoutResource.durationUnit,
                    suggestion: WorkoutResource.targetDurationSuggestion,
                    enabled: enabled,
                    onDecrease: () => _changeDuration(-_durationStep),
                    onIncrease: () => _changeDuration(_durationStep),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  GoalAdjustCard(
                    icon: Icons.local_fire_department_rounded,
                    color: AppColors.accentOrange,
                    title: WorkoutResource.targetCalorie,
                    value: '$_calories',
                    unit: 'kcal',
                    suggestion: WorkoutResource.targetCalorieSuggestion,
                    enabled: enabled,
                    onDecrease: () => _changeCalories(-_caloriesStep),
                    onIncrease: () => _changeCalories(_caloriesStep),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  FreeTrainingCard(
                    value: _freeTraining,
                    onChanged: (v) => setState(() => _freeTraining = v),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  const GoalSuggestionCard(suggestions: _suggestions),
                  SizedBox(height: AppSpacing.xl),
                  GradientActionButton(
                    label: WorkoutResource.saveGoal,
                    onTap: _save,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _restoreDefaults,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
    );
  }
}

/// 保存目标返回结果。
class SportGoalResult {
  final double distance;
  final int duration;
  final int calories;
  final bool freeTraining;

  const SportGoalResult({
    required this.distance,
    required this.duration,
    required this.calories,
    required this.freeTraining,
  });
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
