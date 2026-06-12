import 'package:flutter/material.dart';

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
    workoutTitle: '户外跑步',
    status: WorkoutStatus.ready,
    gpsLabel: 'GPS',
    gpsStatus: '信号良好',
    distanceKm: '2.35',
    targetKm: '8.00',
    duration: '00:18:36',
    calories: '186',
    pace: "07'54''",
    endHint: '长按结束',
    musicTitle: '运动音乐',
    musicStatus: '播放中',
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
    heroTitle: '准备开始今天的训练',
    heroSubtitle: '连接 GPS / 开启记录',
    workoutTypes: [
      WorkoutType(
        title: '户外跑步',
        icon: Icons.directions_run_rounded,
        color: _green,
      ),
      WorkoutType(
        title: '室内跑步',
        icon: Icons.fitness_center_rounded,
        color: _cyan,
      ),
      WorkoutType(
        title: '健走',
        icon: Icons.directions_walk_rounded,
        color: _purple,
      ),
      WorkoutType(title: '徒步', icon: Icons.hiking_rounded, color: _orange),
    ],
    goalMetrics: [
      GoalMetric(
        title: '公里数',
        value: '8.00 / 8.00',
        unit: '公里',
        icon: Icons.adjust_rounded,
        color: _green,
      ),
      GoalMetric(
        title: '时长',
        value: '60 / 60',
        unit: '分钟',
        icon: Icons.timer_outlined,
        color: _cyan,
      ),
      GoalMetric(
        title: '消耗',
        value: '500 / 500',
        unit: 'kcal',
        icon: Icons.local_fire_department_rounded,
        color: _orange,
      ),
      GoalMetric(
        title: '自由训练',
        value: '不设定目标',
        icon: Icons.all_inclusive_rounded,
        color: _purple,
      ),
    ],
    achievements: [
      Achievement(
        title: '初级跑者',
        icon: Icons.directions_run_rounded,
        color: _green,
      ),
      Achievement(title: '坚持不懈', icon: Icons.flag_rounded, color: _cyan),
      Achievement(
        title: '百公里',
        icon: Icons.military_tech_rounded,
        color: _purple,
      ),
    ],
  );
}
