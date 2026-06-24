import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';

/// 运动类型（户外 / 室内 / 健走 / 徒步）。
class WorkoutType {
  final String title;
  final IconData icon;
  final String? iconAsset;
  final Color color;

  const WorkoutType({
    required this.title,
    required this.icon,
    this.iconAsset,
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
  final String imageAsset;
  final Color color;

  const Achievement({
    required this.title,
    required this.imageAsset,
    required this.color,
  });
}

/// 运动记录状态。
enum WorkoutStatus { ready, running, paused, ended }

class WorkoutMusicTrackData {
  final String name;
  final bool current;

  const WorkoutMusicTrackData({required this.name, required this.current});
}

class WorkoutRouteHistoryRecord {
  final String id;
  final String sportType;
  final DateTime endedAt;
  final String distanceKm;
  final String duration;
  final String averagePace;
  final LatLng? startPoint;
  final LatLng? endPoint;
  final List<LatLng> routePoints;
  final Uint8List? mapSnapshot;

  const WorkoutRouteHistoryRecord({
    required this.id,
    required this.sportType,
    required this.endedAt,
    required this.distanceKm,
    required this.duration,
    required this.averagePace,
    required this.startPoint,
    required this.endPoint,
    required this.routePoints,
    this.mapSnapshot,
  });
}

class WorkoutRouteHistoryStore {
  WorkoutRouteHistoryStore._();

  static final revision = ValueNotifier<int>(0);
  static final List<WorkoutRouteHistoryRecord> _records = [];

  static List<WorkoutRouteHistoryRecord> get records =>
      List<WorkoutRouteHistoryRecord>.unmodifiable(_records);

  static WorkoutRouteHistoryRecord? get latest =>
      _records.isEmpty ? null : _records.first;

  static void add(WorkoutRouteHistoryRecord record) {
    _records.removeWhere((item) => item.id == record.id);
    _records.insert(0, record);
    revision.value++;
  }
}

/// 开始运动后的实时记录展示数据。
class WorkoutTrackingData {
  final String workoutTitle;
  final WorkoutStatus status;
  final String distanceKm;
  final String targetKm;
  final String duration;
  final String calories;
  final String pace;
  final String endHint;
  final String musicTitle;
  final String musicStatus;
  final bool hasMusic;
  final bool musicPlaying;

  const WorkoutTrackingData({
    required this.workoutTitle,
    required this.status,
    required this.distanceKm,
    required this.targetKm,
    required this.duration,
    required this.calories,
    required this.pace,
    required this.endHint,
    required this.musicTitle,
    required this.musicStatus,
    this.hasMusic = false,
    this.musicPlaying = false,
  });

  static const mock = WorkoutTrackingData(
    workoutTitle: WorkoutText.outdoorRun,
    status: WorkoutStatus.ready,
    distanceKm: '2.35',
    targetKm: '8.00',
    duration: '00:18:36',
    calories: '186',
    pace: "07'54''",
    endHint: WorkoutText.trackingEndHint,
    musicTitle: WorkoutText.trackingMusicTitle,
    musicStatus: WorkoutText.trackingMusicIdle,
  );

  WorkoutTrackingData copyWith({
    String? workoutTitle,
    WorkoutStatus? status,
    String? distanceKm,
    String? targetKm,
    String? duration,
    String? calories,
    String? pace,
    String? musicTitle,
    String? musicStatus,
    bool? hasMusic,
    bool? musicPlaying,
  }) {
    return WorkoutTrackingData(
      workoutTitle: workoutTitle ?? this.workoutTitle,
      status: status ?? this.status,
      distanceKm: distanceKm ?? this.distanceKm,
      targetKm: targetKm ?? this.targetKm,
      duration: duration ?? this.duration,
      calories: calories ?? this.calories,
      pace: pace ?? this.pace,
      endHint: endHint,
      musicTitle: musicTitle ?? this.musicTitle,
      musicStatus: musicStatus ?? this.musicStatus,
      hasMusic: hasMusic ?? this.hasMusic,
      musicPlaying: musicPlaying ?? this.musicPlaying,
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

  WorkoutPageData copyWith({
    List<GoalMetric>? goalMetrics,
    List<Achievement>? achievements,
  }) {
    return WorkoutPageData(
      heroTitle: heroTitle,
      heroSubtitle: heroSubtitle,
      workoutTypes: workoutTypes,
      goalMetrics: goalMetrics ?? this.goalMetrics,
      achievements: achievements ?? this.achievements,
    );
  }

  // 颜色使用与 AppColors fallback 一致的字面量，保证可 const 化（对齐 sync_data_detail_model 写法）。
  static const _green = Color(0xFF24F04E);
  static const _cyan = Color(0xFF0CD9FF);
  static const _purple = Color(0xFF7A3DFF);
  static const _orange = Color(0xFFFF9F12);

  static WorkoutPageData localized() {
    return WorkoutPageData(
      heroTitle: WorkoutResource.heroTitle,
      heroSubtitle: WorkoutResource.heroSubtitle,
      workoutTypes: [
        WorkoutType(
          title: WorkoutResource.outdoorRun,
          icon: Icons.directions_run_rounded,
          iconAsset: 'assets/workout_outdoor.svg',
          color: _green,
        ),
        WorkoutType(
          title: WorkoutResource.indoorRun,
          icon: Icons.fitness_center_rounded,
          iconAsset: 'assets/workout_indoor.svg',
          color: _cyan,
        ),
        WorkoutType(
          title: WorkoutResource.fitnessWalk,
          icon: Icons.directions_walk_rounded,
          iconAsset: 'assets/workout_fitness_walk.svg',
          color: _purple,
        ),
        WorkoutType(
          title: WorkoutResource.hiking,
          icon: Icons.hiking_rounded,
          iconAsset: 'assets/workout_hiking.svg',
          color: _orange,
        ),
      ],
      goalMetrics: [
        GoalMetric(
          title: WorkoutResource.goalKm,
          value: '0.00 / 8.00',
          unit: WorkoutResource.distanceUnit,
          icon: Icons.adjust_rounded,
          color: _green,
        ),
        GoalMetric(
          title: WorkoutResource.goalDuration,
          value: '0 / 60',
          unit: WorkoutResource.durationUnit,
          icon: Icons.timer_outlined,
          color: _cyan,
        ),
        GoalMetric(
          title: WorkoutResource.goalCalorie,
          value: '0 / 500',
          unit: 'kcal',
          icon: Icons.local_fire_department_rounded,
          color: _orange,
        ),
        GoalMetric(
          title: WorkoutResource.freeTraining,
          value: WorkoutResource.noGoal,
          icon: Icons.all_inclusive_rounded,
          color: _purple,
        ),
      ],
      achievements: [
        Achievement(
          title: WorkoutResource.beginnerRunner,
          imageAsset: 'assets/1.png',
          color: _green,
        ),
        Achievement(
          title: WorkoutResource.persistent,
          imageAsset: 'assets/2.png',
          color: _cyan,
        ),
        Achievement(
          title: WorkoutResource.hundredKm,
          imageAsset: 'assets/3.png',
          color: _purple,
        ),
      ],
    );
  }

  static const mock = WorkoutPageData(
    heroTitle: WorkoutText.heroTitle,
    heroSubtitle: WorkoutText.heroSubtitle,
    workoutTypes: [
      WorkoutType(
        title: WorkoutText.outdoorRun,
        icon: Icons.directions_run_rounded,
        iconAsset: 'assets/workout_outdoor.svg',
        color: _green,
      ),
      WorkoutType(
        title: WorkoutText.indoorRun,
        icon: Icons.fitness_center_rounded,
        iconAsset: 'assets/workout_indoor.svg',
        color: _cyan,
      ),
      WorkoutType(
        title: WorkoutText.fitnessWalk,
        icon: Icons.directions_walk_rounded,
        iconAsset: 'assets/workout_fitness_walk.svg',
        color: _purple,
      ),
      WorkoutType(
        title: WorkoutText.hiking,
        icon: Icons.hiking_rounded,
        iconAsset: 'assets/workout_hiking.svg',
        color: _orange,
      ),
    ],
    goalMetrics: [
      GoalMetric(
        title: WorkoutText.goalKm,
        value: '0.00 / 8.00',
        unit: WorkoutText.distanceUnit,
        icon: Icons.adjust_rounded,
        color: _green,
      ),
      GoalMetric(
        title: WorkoutText.goalDuration,
        value: '0 / 60',
        unit: WorkoutText.durationUnit,
        icon: Icons.timer_outlined,
        color: _cyan,
      ),
      GoalMetric(
        title: WorkoutText.goalCalorie,
        value: '0 / 500',
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
        imageAsset: 'assets/1.png',
        color: _green,
      ),
      Achievement(
        title: WorkoutText.persistent,
        imageAsset: 'assets/2.png',
        color: _cyan,
      ),
      Achievement(
        title: WorkoutText.hundredKm,
        imageAsset: 'assets/3.png',
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

  ExerciseResultData copyWith({
    String? sportType,
    String? dateText,
    String? distance,
    String? distanceUnit,
    List<ExerciseResultMetric>? metrics,
  }) {
    return ExerciseResultData(
      sportType: sportType ?? this.sportType,
      dateText: dateText ?? this.dateText,
      distance: distance ?? this.distance,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      metrics: metrics ?? this.metrics,
    );
  }

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
