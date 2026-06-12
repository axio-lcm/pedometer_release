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
    '距离：初学者建议 3–5 公里，进阶者 5–10 公里',
    '时长：建议 30–60 分钟，有助于提升心肺能力',
    '消耗：建议 300–600 kcal，保持健康体重',
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
                  AppTopNavigationBar(title: '编辑运动目标', onBack: _back),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    '设定目标，激励自己，每天进步一点点 💪',
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
                    title: '目标距离',
                    value: _distance.toStringAsFixed(2),
                    unit: '公里',
                    suggestion: '建议 3.00 - 20.00 公里',
                    enabled: enabled,
                    onDecrease: () => _changeDistance(-_distanceStep),
                    onIncrease: () => _changeDistance(_distanceStep),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  GoalAdjustCard(
                    icon: Icons.timer_outlined,
                    color: AppColors.accentCyan,
                    title: '目标时长',
                    value: '$_duration',
                    unit: '分钟',
                    suggestion: '建议 10 - 300 分钟',
                    enabled: enabled,
                    onDecrease: () => _changeDuration(-_durationStep),
                    onIncrease: () => _changeDuration(_durationStep),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  GoalAdjustCard(
                    icon: Icons.local_fire_department_rounded,
                    color: AppColors.accentOrange,
                    title: '目标消耗',
                    value: '$_calories',
                    unit: 'kcal',
                    suggestion: '建议 100 - 2000 kcal',
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
                  GradientActionButton(label: '保存目标', onTap: _save),
                  SizedBox(height: AppSpacing.md),
                  Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _restoreDefaults,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Text(
                          '恢复默认',
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
