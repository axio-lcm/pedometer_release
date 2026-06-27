import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:pedometer/feature/workout/model/achievement_stats_store.dart';
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

/// 成就徽章详情（成就页用）：已获得显示彩色徽章，未获得显示灰色（0 开头）徽章 + 进度。
class AchievementBadgeItem {
  final String title;
  final String description;

  /// 徽章序号 1..12：彩色图 `assets/<index>.png`，灰色图 `assets/0<index>.png`。
  final int index;
  final bool earned;

  /// 未获得时的进度，0~1。
  final double progress;

  const AchievementBadgeItem({
    required this.title,
    required this.description,
    required this.index,
    required this.earned,
    this.progress = 0,
  });

  /// 已获得用彩色徽章，未获得用 0 开头的灰色徽章。
  String get imageAsset =>
      earned ? 'assets/$index.png' : 'assets/0$index.png';
}

/// 成就徽章目录：12 枚徽章，按真实累积数据计算进度，达标（≥100%）才点亮彩色徽章。
///
/// 运动类（距离 / 天数 / 时长 / 单月 / 连续周）取自 [AchievementStatsStore]
/// （开始运动结束时累积）；步数 / 卡路里类由首页数据传入。
/// 登峰造极（index 7）暂未实现功能与数据，保持锁定 0 进度。
class WorkoutAchievementCatalog {
  WorkoutAchievementCatalog._();

  /// [maxDailySteps] 历史单日最高步数、[totalCalories] 累计消耗（kcal），均来自首页。
  static List<AchievementBadgeItem> items({
    required int maxDailySteps,
    required double totalCalories,
  }) {
    final distanceKm = AchievementStatsStore.totalDistanceKm;
    final runDays = AchievementStatsStore.runDaysCount;
    final maxMinutes = AchievementStatsStore.maxSessionMinutes;
    final bestMonthKm = AchievementStatsStore.bestMonthDistanceKm;
    final weekStreak = AchievementStatsStore.longestWeekStreak;

    AchievementBadgeItem badge(
      int index,
      String title,
      String description,
      double current,
      double target,
    ) {
      final ratio = target <= 0 ? 0.0 : current / target;
      final progress = ratio.isFinite ? ratio.clamp(0.0, 1.0) : 0.0;
      return AchievementBadgeItem(
        title: title,
        description: description,
        index: index,
        earned: progress >= 1.0,
        progress: progress,
      );
    }

    return [
      badge(1, WorkoutResource.beginnerRunner,
          WorkoutResource.badgeDescBeginnerRunner, distanceKm, 10),
      badge(2, WorkoutResource.persistent,
          WorkoutResource.badgeDescPersistent, runDays.toDouble(), 30),
      badge(3, WorkoutResource.hundredKm,
          WorkoutResource.badgeDescHundredKm, distanceKm, 100),
      badge(4, WorkoutResource.badgeTimeMaster,
          WorkoutResource.badgeDescTimeMaster, maxMinutes.toDouble(), 60),
      badge(5, WorkoutResource.badge200Km,
          WorkoutResource.badgeDesc200Km, distanceKm, 200),
      badge(6, WorkoutResource.badgeCalorieMaster,
          WorkoutResource.badgeDescCalorieMaster, totalCalories, 2000),
      // 登峰造极：暂未实现累积数据，保持锁定 0 进度。
      AchievementBadgeItem(
        title: WorkoutResource.badgePeakClimber,
        description: WorkoutResource.badgeDescPeakClimber,
        index: 7,
        earned: false,
        progress: 0,
      ),
      badge(8, WorkoutResource.badgeAdvancedRunner,
          WorkoutResource.badgeDescAdvancedRunner, distanceKm, 50),
      badge(9, WorkoutResource.badgeWeeklyCheckin,
          WorkoutResource.badgeDescWeeklyCheckin, weekStreak.toDouble(), 7),
      badge(10, WorkoutResource.badgeMonthlyStar,
          WorkoutResource.badgeDescMonthlyStar, bestMonthKm, 100),
      badge(11, WorkoutResource.badgeStepsMaster,
          WorkoutResource.badgeDescStepsMaster, maxDailySteps.toDouble(), 20000),
      badge(12, WorkoutResource.badge500Km,
          WorkoutResource.badgeDesc500Km, distanceKm, 500),
    ];
  }
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

/// 运动轨迹历史：内存缓存 + sqflite 持久化。
/// 启动时 [load] 从库恢复；[add] 同时写缓存与库；列表页读 [records]（懒加载渲染）。
class WorkoutRouteHistoryStore {
  WorkoutRouteHistoryStore._();

  static final revision = ValueNotifier<int>(0);
  static final List<WorkoutRouteHistoryRecord> _records = [];
  static final _WorkoutRouteHistoryDb _db = _WorkoutRouteHistoryDb();

  static List<WorkoutRouteHistoryRecord> get records =>
      List<WorkoutRouteHistoryRecord>.unmodifiable(_records);

  static WorkoutRouteHistoryRecord? get latest =>
      _records.isEmpty ? null : _records.first;

  /// 启动时从持久化恢复（按结束时间倒序）。
  static Future<void> load() async {
    try {
      final stored = await _db.loadAll();
      _records
        ..clear()
        ..addAll(stored);
      revision.value++;
    } catch (_) {
      // 读取失败不影响功能，按空历史处理。
    }
  }

  static void add(WorkoutRouteHistoryRecord record) {
    _records.removeWhere((item) => item.id == record.id);
    _records.insert(0, record);
    revision.value++;
    unawaited(_db.insert(record));
  }
}

/// 运动轨迹历史的 sqflite 存储（独立库文件）。
class _WorkoutRouteHistoryDb {
  static const _dbName = 'pedometer_workout_routes.db';
  static const _table = 'route_history';

  Database? _db;
  Future<Database>? _opening;

  Future<Database> get _database {
    final db = _db;
    if (db != null) return Future.value(db);
    return _opening ??= _open();
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id TEXT PRIMARY KEY,
            ended_at INTEGER NOT NULL,
            sport_type TEXT NOT NULL,
            distance_km TEXT NOT NULL,
            duration TEXT NOT NULL,
            average_pace TEXT NOT NULL,
            start_point TEXT,
            end_point TEXT,
            route_points TEXT NOT NULL,
            map_snapshot BLOB
          )
        ''');
      },
    );
    _db = db;
    return db;
  }

  Future<void> insert(WorkoutRouteHistoryRecord record) async {
    final db = await _database;
    await db.insert(
      _table,
      _toRow(record),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<WorkoutRouteHistoryRecord>> loadAll() async {
    final db = await _database;
    final rows = await db.query(_table, orderBy: 'ended_at DESC');
    return [for (final row in rows) _fromRow(row)];
  }

  Map<String, Object?> _toRow(WorkoutRouteHistoryRecord r) => {
    'id': r.id,
    'ended_at': r.endedAt.millisecondsSinceEpoch,
    'sport_type': r.sportType,
    'distance_km': r.distanceKm,
    'duration': r.duration,
    'average_pace': r.averagePace,
    'start_point': _encodePoint(r.startPoint),
    'end_point': _encodePoint(r.endPoint),
    'route_points': jsonEncode([
      for (final pt in r.routePoints) [pt.latitude, pt.longitude],
    ]),
    'map_snapshot': r.mapSnapshot,
  };

  WorkoutRouteHistoryRecord _fromRow(Map<String, Object?> row) {
    final decoded = jsonDecode(row['route_points'] as String) as List;
    final points = [
      for (final e in decoded)
        LatLng((e[0] as num).toDouble(), (e[1] as num).toDouble()),
    ];
    final snapshot = row['map_snapshot'];
    return WorkoutRouteHistoryRecord(
      id: row['id'] as String,
      sportType: row['sport_type'] as String,
      endedAt: DateTime.fromMillisecondsSinceEpoch(row['ended_at'] as int),
      distanceKm: row['distance_km'] as String,
      duration: row['duration'] as String,
      averagePace: row['average_pace'] as String,
      startPoint: _decodePoint(row['start_point'] as String?),
      endPoint: _decodePoint(row['end_point'] as String?),
      routePoints: List<LatLng>.unmodifiable(points),
      mapSnapshot: snapshot is Uint8List
          ? snapshot
          : (snapshot is List<int> ? Uint8List.fromList(snapshot) : null),
    );
  }

  static String? _encodePoint(LatLng? point) =>
      point == null ? null : '${point.latitude},${point.longitude}';

  static LatLng? _decodePoint(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
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

  /// 室内会话步数（展示用）。
  final String steps;

  /// 是否以步数为主指标展示（室内）；否则以距离为主（户外）。
  final bool stepsPrimary;

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
    this.steps = '0',
    this.stepsPrimary = false,
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
    String? steps,
    bool? stepsPrimary,
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
      steps: steps ?? this.steps,
      stepsPrimary: stepsPrimary ?? this.stepsPrimary,
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
