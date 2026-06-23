import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/feature/workout/model/workout_calorie_policy.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';
import 'package:pedometer/feature/workout/model/workout_pace_policy.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';
import 'package:pedometer/feature/workout/viewmodel/workout_view_model.dart';

/// 户外运动会话 view model：持有实时距离 / 时长 / 卡路里 / 配速 / 轨迹 / 方位，
/// 作为运动追踪页与地图的唯一数据源。
class WorkoutTrackingViewModel extends GetxController
    implements IBaseViewModel {
  WorkoutTrackingViewModel({
    WorkoutCaloriePolicy? caloriePolicy,
    WorkoutPacePolicy? pacePolicy,
    this.template = WorkoutTrackingData.mock,
    this.minMoveMeters = 2.5,
    this.minRoutePointMeters = 1.5,
  }) : _caloriePolicy = caloriePolicy ?? const WorkoutCaloriePolicy(),
       _pacePolicy = pacePolicy ?? WorkoutPacePolicy();

  final WorkoutCaloriePolicy _caloriePolicy;
  final WorkoutPacePolicy _pacePolicy;

  /// 页面静态模板（标题 / 目标 / GPS / 音乐等），实时值由状态合并。
  /// 目标里程在 [init] 中与运动栏的目标设置同步。
  WorkoutTrackingData template;

  /// 小于该距离（米）的相邻定位不累计运动距离；可视轨迹另由
  /// [minRoutePointMeters] 控制。
  final double minMoveMeters;

  /// 地图可视轨迹的最低位移。它小于 [minMoveMeters]，用于让真机小范围
  /// 移动先出现路线，但不参与距离 / 配速 / 卡路里计算。
  final double minRoutePointMeters;

  final status = WorkoutStatus.ready.obs;
  final startPoint = Rxn<LatLng>();
  final currentPosition = Rxn<LatLng>();
  final pathPoints = <LatLng>[].obs;
  final distanceMeters = 0.0.obs;
  final elapsed = Duration.zero.obs;
  final calories = 0.0.obs;
  final bearing = 0.0.obs;
  final pace = Rxn<Duration>();
  late final RxString workoutTitle = template.workoutTitle.obs;

  /// 是否为室内运动：室内无 GPS 地图，运动区域显示纯色背景且累积里程固定居中。
  final isIndoor = false.obs;

  Timer? _ticker;
  Position? _lastRaw; // 上一个被接受的原始定位（算距离 / 方位）
  Position? _currentRaw; // 最近一次定位，开始运动时用作第一段距离基准
  Position? _lastRouteRaw; // 上一个被画到地图轨迹上的原始定位
  double _lastSpeedKmh = 0; // 当前 tick 卡路里用的速度

  // ---- 状态机 ----

  void start() {
    if (status.value == WorkoutStatus.running) return;
    if (status.value == WorkoutStatus.paused) {
      resume();
      return;
    }
    if (status.value == WorkoutStatus.ended) return;

    distanceMeters.value = 0;
    elapsed.value = Duration.zero;
    calories.value = 0;
    pace.value = null;
    pathPoints.clear();
    _pacePolicy.reset();
    _lastRaw = _currentRaw;
    _lastRouteRaw = _currentRaw;
    _lastSpeedKmh = 0;

    final pos = currentPosition.value;
    startPoint.value = pos;
    if (pos != null) pathPoints.add(pos);

    status.value = WorkoutStatus.running;
    _startTicker();
  }

  void pause() {
    if (status.value != WorkoutStatus.running) return;
    status.value = WorkoutStatus.paused;
    _stopTicker();
  }

  void resume() {
    if (status.value != WorkoutStatus.paused) return;
    status.value = WorkoutStatus.running;
    _startTicker();
  }

  void end() {
    status.value = WorkoutStatus.ended;
    _stopTicker();
  }

  /// 主按钮点击：依据当前状态切换。
  void togglePrimary() {
    switch (status.value) {
      case WorkoutStatus.ready:
        start();
        break;
      case WorkoutStatus.running:
        pause();
        break;
      case WorkoutStatus.paused:
        resume();
        break;
      case WorkoutStatus.ended:
        break;
    }
  }

  // ---- 定位输入 ----

  /// 每个被地图接受的定位点回调一次。
  /// [raw] 原始 WGS84（算距离 / 方位），[display] 纠偏后的显示坐标（画轨迹 / marker）。
  void onFix(Position raw, LatLng display) {
    _currentRaw = raw;
    currentPosition.value = display;

    final last = _lastRaw;
    if (last == null) {
      _lastRaw = raw;
      if (status.value == WorkoutStatus.running && pathPoints.isEmpty) {
        startPoint.value ??= display;
        pathPoints.add(display);
        _lastRouteRaw = raw;
      }
      return;
    }

    final delta = Geolocator.distanceBetween(
      last.latitude,
      last.longitude,
      raw.latitude,
      raw.longitude,
    );
    if (delta < minMoveMeters) {
      _appendVisibleRoutePointIfNeeded(raw, display);
      return; // 抖动，保持上次 bearing / 距离
    }

    bearing.value = Geolocator.bearingBetween(
      last.latitude,
      last.longitude,
      raw.latitude,
      raw.longitude,
    );

    if (status.value == WorkoutStatus.running) {
      distanceMeters.value += delta;
      _appendRoutePoint(raw, display);
      _pacePolicy.addSample(
        cumulativeMeters: distanceMeters.value,
        at: DateTime.now(),
      );
      pace.value = _pacePolicy.pacePerKm;
      _lastSpeedKmh = (raw.speed.isFinite && raw.speed > 0)
          ? raw.speed * 3.6
          : _speedFromDelta(delta, last.timestamp, raw.timestamp);
    }

    _lastRaw = raw;
  }

  void _appendVisibleRoutePointIfNeeded(Position raw, LatLng display) {
    if (status.value != WorkoutStatus.running) return;

    final lastRoute = _lastRouteRaw;
    if (lastRoute == null) {
      _appendRoutePoint(raw, display);
      return;
    }

    final delta = Geolocator.distanceBetween(
      lastRoute.latitude,
      lastRoute.longitude,
      raw.latitude,
      raw.longitude,
    );
    if (delta < minRoutePointMeters) return;
    _appendRoutePoint(raw, display);
  }

  void _appendRoutePoint(Position raw, LatLng display) {
    if (pathPoints.isEmpty) {
      startPoint.value ??= display;
    }
    if (pathPoints.isEmpty || pathPoints.last != display) {
      pathPoints.add(display);
    }
    _lastRouteRaw = raw;
  }

  double _speedFromDelta(double meters, DateTime from, DateTime to) {
    final secs = to.difference(from).inMilliseconds / 1000;
    if (secs <= 0) return 0;
    return (meters / secs) * 3.6;
  }

  // ---- 计时器 ----

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsed.value += const Duration(seconds: 1);
      calories.value += _caloriePolicy.kcalForTick(
        speedKmh: _lastSpeedKmh,
        seconds: 1,
      );
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void onInit() {
    super.onInit();
    init();
  }

  @override
  void init() {
    final args = Get.arguments;
    if (args is WorkoutType) {
      workoutTitle.value = args.title;
      isIndoor.value = args.title == WorkoutText.indoorRun;
    } else if (args is String && args.trim().isNotEmpty) {
      workoutTitle.value = args;
      isIndoor.value = args == WorkoutText.indoorRun;
    }
    _syncGoalFromWorkout();
  }

  /// 同步运动栏「目标与成就」中的目标里程，使地图上的「目标 X 公里」与之一致。
  void _syncGoalFromWorkout() {
    if (!Get.isRegistered<WorkoutViewModel>()) return;
    final workout = Get.find<WorkoutViewModel>();
    template = template.copyWith(
      targetKm: workout.goalDistance.toStringAsFixed(2),
    );
  }

  @override
  void unInit() {
    _stopTicker();
  }

  @override
  void onClose() {
    unInit();
    super.onClose();
  }

  // ---- 格式化展示 ----

  String get distanceKmText => (distanceMeters.value / 1000).toStringAsFixed(2);

  String get durationText {
    final d = elapsed.value;
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get caloriesText => calories.value.round().toString();

  /// 模板叠加实时值后的展示数据。
  WorkoutTrackingData get liveData => template.copyWith(
    workoutTitle: workoutTitle.value,
    status: status.value,
    distanceKm: distanceKmText,
    duration: durationText,
    calories: caloriesText,
    pace: paceText,
  );

  String get paceText {
    final p = pace.value;
    if (p == null) return "--'--''";
    final total = p.inSeconds;
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return "$m'$s''";
  }

  /// 结束后用于结果页的聚合数据。
  ExerciseResultData toResultData() {
    return ExerciseResultData(
      sportType: workoutTitle.value,
      dateText: ExerciseResultData.mock.dateText,
      distance: distanceKmText,
      distanceUnit: WorkoutText.distanceUnit,
      metrics: [
        ExerciseResultMetric(
          icon: Icons.schedule_rounded,
          color: AppColors.brandGreen,
          label: WorkoutText.metricDuration,
          value: durationText,
        ),
        ExerciseResultMetric(
          icon: Icons.local_fire_department_rounded,
          color: AppColors.accentOrange,
          label: WorkoutText.metricCalorieKcal,
          value: caloriesText,
        ),
        ExerciseResultMetric(
          icon: Icons.speed_rounded,
          color: AppColors.accentCyan,
          label: WorkoutText.metricPaceMinKm,
          value: paceText,
        ),
      ],
    );
  }
}
