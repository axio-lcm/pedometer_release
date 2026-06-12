import 'package:flutter/material.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';

/// 运动类型（户外跑步 / 室内跑步 / 健走 / 徒步）。
class WorkoutType {
  final String title;
  final IconData icon;
  final Color color;

  const WorkoutType({
    required this.title,
    required this.icon,
    required this.color,
  });
}

/// 运动目标指标：数字与单位分离，便于后续国际化。
class GoalMetric {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const GoalMetric({
    required this.title,
    required this.value,
    this.unit = '',
    required this.icon,
    required this.color,
  });
}

/// 成就徽章。
class Achievement {
  final String title;
  final IconData icon;
  final Color color;

  const Achievement({
    required this.title,
    required this.icon,
    required this.color,
  });
}

/// 运动记录状态。
enum WorkoutStatus { ready, running, paused, ended }

/// 开始运动后的实时记录展示数据。
class WorkoutTrackingData {
  final String workoutTitle;
  final WorkoutStatus status;
  final String gpsLabel;
  final String gpsStatus;
  final String distanceKm;
  final String targetKm;
  final String duration;
  final String calories;
  final String pace;
  final String endHint;
  final String musicTitle;
  final String musicStatus;

  const WorkoutTrackingData({
    required this.workoutTitle,
    required this.status,
    required this.gpsLabel,
    required this.gpsStatus,
    required this.distanceKm,
    required this.targetKm,
    required this.duration,
    required this.calories,
    required this.pace,
    required this.endHint,
    required this.musicTitle,
    required this.musicStatus,
  });

  static const mock = WorkoutTrackingData(
    workoutTitle: WorkoutText.outdoorRun,
    status: WorkoutStatus.ready,
    gpsLabel: 'GPS',
    gpsStatus: WorkoutText.trackingGpsGood,
    distanceKm: '2.35',
    targetKm: '8.00',
    duration: '00:18:36',
    calories: '186',
    pace: "07'54''",
    endHint: WorkoutText.trackingEndHint,
    musicTitle: WorkoutText.trackingMusicTitle,
    musicStatus: WorkoutText.trackingMusicStatus,
  );

  WorkoutTrackingData copyWith({WorkoutStatus? status}) {
    return WorkoutTrackingData(
      workoutTitle: workoutTitle,
      status: status ?? this.status,
      gpsLabel: gpsLabel,
      gpsStatus: gpsStatus,
      distanceKm: distanceKm,
      targetKm: targetKm,
      duration: duration,
      calories: calories,
      pace: pace,
      endHint: endHint,
      musicTitle: musicTitle,
      musicStatus: musicStatus,
    );
  }
}

/// 运动 / 训练页展示数据。
class WorkoutPageData {
  final String heroTitle;
  final String heroSubtitle;
  final List<WorkoutType> workoutTypes;
  final List<GoalMetric> goalMetrics;
  final List<Achievement> achievements;

  const WorkoutPageData({
    required this.heroTitle,
    required this.heroSubtitle,
    required this.workoutTypes,
    required this.goalMetrics,
    required this.achievements,
  });

  // 颜色使用与 AppColors fallback 一致的字面量，保证可 const 化（对齐 sync_data_detail_model 写法）。
  static const _green = Color(0xFF24F04E);
  static const _cyan = Color(0xFF0CD9FF);
  static const _purple = Color(0xFF7A3DFF);
  static const _orange = Color(0xFFFF9F12);

  static const mock = WorkoutPageData(
    heroTitle: WorkoutText.heroTitle,
    heroSubtitle: WorkoutText.heroSubtitle,
    workoutTypes: [
      WorkoutType(
        title: WorkoutText.outdoorRun,
        icon: Icons.directions_run_rounded,
        color: _green,
      ),
      WorkoutType(
        title: WorkoutText.indoorRun,
        icon: Icons.fitness_center_rounded,
        color: _cyan,
      ),
      WorkoutType(
        title: WorkoutText.fitnessWalk,
        icon: Icons.directions_walk_rounded,
        color: _purple,
      ),
      WorkoutType(
        title: WorkoutText.hiking,
        icon: Icons.hiking_rounded,
        color: _orange,
      ),
    ],
    goalMetrics: [
      GoalMetric(
        title: WorkoutText.goalKm,
        value: '8.00 / 8.00',
        unit: WorkoutText.distanceUnit,
        icon: Icons.adjust_rounded,
        color: _green,
      ),
      GoalMetric(
        title: WorkoutText.goalDuration,
        value: '60 / 60',
        unit: WorkoutText.durationUnit,
        icon: Icons.timer_outlined,
        color: _cyan,
      ),
      GoalMetric(
        title: WorkoutText.goalCalorie,
        value: '500 / 500',
        unit: 'kcal',
        icon: Icons.local_fire_department_rounded,
        color: _orange,
      ),
      GoalMetric(
        title: WorkoutText.freeTraining,
        value: WorkoutText.noGoal,
        icon: Icons.all_inclusive_rounded,
        color: _purple,
      ),
    ],
    achievements: [
      Achievement(
        title: WorkoutText.beginnerRunner,
        icon: Icons.directions_run_rounded,
        color: _green,
      ),
      Achievement(
        title: WorkoutText.persistent,
        icon: Icons.flag_rounded,
        color: _cyan,
      ),
      Achievement(
        title: WorkoutText.hundredKm,
        icon: Icons.military_tech_rounded,
        color: _purple,
      ),
    ],
  );
}

/// 运动结果页单个统计项。
class ExerciseResultMetric {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const ExerciseResultMetric({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });
}

/// 运动结束（运动完成）结果页展示数据。
class ExerciseResultData {
  final String sportType;
  final String dateText;
  final String distance;
  final String distanceUnit;
  final List<ExerciseResultMetric> metrics;

  const ExerciseResultData({
    required this.sportType,
    required this.dateText,
    required this.distance,
    required this.distanceUnit,
    required this.metrics,
  });

  // 颜色字面量与 AppColors fallback 一致，保证可 const 化。
  static const _green = Color(0xFF24F04E);
  static const _cyan = Color(0xFF0CD9FF);
  static const _orange = Color(0xFFFF9F12);

  static const mock = ExerciseResultData(
    sportType: WorkoutText.outdoorRun,
    dateText: WorkoutText.resultDate,
    distance: '2.35',
    distanceUnit: WorkoutText.distanceUnit,
    metrics: [
      ExerciseResultMetric(
        icon: Icons.schedule_rounded,
        color: _green,
        label: WorkoutText.metricDuration,
        value: '00:18:36',
      ),
      ExerciseResultMetric(
        icon: Icons.local_fire_department_rounded,
        color: _orange,
        label: WorkoutText.metricCalorieKcal,
        value: '186',
      ),
      ExerciseResultMetric(
        icon: Icons.speed_rounded,
        color: _cyan,
        label: WorkoutText.metricPaceMinKm,
        value: "07'54''",
      ),
      ExerciseResultMetric(
        icon: Icons.directions_walk_rounded,
        color: _green,
        label: WorkoutText.resultSteps,
        value: '3,256',
      ),
      ExerciseResultMetric(
        icon: Icons.av_timer_rounded,
        color: _green,
        label: WorkoutText.resultAvgSpeed,
        value: '7.6',
      ),
      ExerciseResultMetric(
        icon: Icons.terrain_rounded,
        color: _green,
        label: WorkoutText.resultElevation,
        value: '32',
      ),
    ],
  );
}
