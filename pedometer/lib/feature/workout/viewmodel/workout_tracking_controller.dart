import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pedometer/feature/workout/model/workout_calorie_policy.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';
import 'package:pedometer/feature/workout/model/workout_pace_policy.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';

/// 户外运动会话控制器：持有实时距离 / 时长 / 卡路里 / 配速 / 轨迹 / 方位，
/// 作为运动追踪页与地图的唯一数据源。
class WorkoutTrackingController extends GetxController {
  WorkoutTrackingController({
    WorkoutCaloriePolicy? caloriePolicy,
    WorkoutPacePolicy? pacePolicy,
    this.minMoveMeters = 2.5,
  })  : _caloriePolicy = caloriePolicy ?? const WorkoutCaloriePolicy(),
        _pacePolicy = pacePolicy ?? WorkoutPacePolicy();

  final WorkoutCaloriePolicy _caloriePolicy;
  final WorkoutPacePolicy _pacePolicy;

  /// 小于该距离（米）的相邻定位视为 GPS 抖动，不累计、不画点。
  final double minMoveMeters;

  final status = WorkoutStatus.ready.obs;
  final startPoint = Rxn<LatLng>();
  final currentPosition = Rxn<LatLng>();
  final pathPoints = <LatLng>[].obs;
  final distanceMeters = 0.0.obs;
  final elapsed = Duration.zero.obs;
  final calories = 0.0.obs;
  final bearing = 0.0.obs;
  final pace = Rxn<Duration>();

  Timer? _ticker;
  Position? _lastRaw; // 上一个被接受的原始定位（算距离 / 方位）
  double _lastSpeedKmh = 0; // 当前 tick 卡路里用的速度

  // ---- 状态机 ----

  void start() {
    distanceMeters.value = 0;
    elapsed.value = Duration.zero;
    calories.value = 0;
    pace.value = null;
    pathPoints.clear();
    _pacePolicy.reset();
    _lastRaw = null;
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
      case WorkoutStatus.running:
        pause();
      case WorkoutStatus.paused:
        resume();
      case WorkoutStatus.ended:
        break;
    }
  }

  // ---- 定位输入 ----

  /// 每个被地图接受的定位点回调一次。
  /// [raw] 原始 WGS84（算距离 / 方位），[display] 纠偏后的显示坐标（画轨迹 / marker）。
  void onFix(Position raw, LatLng display) {
    currentPosition.value = display;

    final last = _lastRaw;
    if (last == null) {
      _lastRaw = raw;
      return;
    }

    final delta = Geolocator.distanceBetween(
      last.latitude,
      last.longitude,
      raw.latitude,
      raw.longitude,
    );
    if (delta < minMoveMeters) return; // 抖动，保持上次 bearing / 距离

    bearing.value = Geolocator.bearingBetween(
      last.latitude,
      last.longitude,
      raw.latitude,
      raw.longitude,
    );

    if (status.value == WorkoutStatus.running) {
      distanceMeters.value += delta;
      pathPoints.add(display);
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
  void onClose() {
    _stopTicker();
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
      sportType: WorkoutText.outdoorRun,
      dateText: ExerciseResultData.mock.dateText,
      distance: distanceKmText,
      distanceUnit: WorkoutText.distanceUnit,
      metrics: [
        ExerciseResultMetric(
          icon: Icons.schedule_rounded,
          color: const Color(0xFF24F04E),
          label: WorkoutText.metricDuration,
          value: durationText,
        ),
        ExerciseResultMetric(
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFFF9F12),
          label: WorkoutText.metricCalorieKcal,
          value: caloriesText,
        ),
        ExerciseResultMetric(
          icon: Icons.speed_rounded,
          color: const Color(0xFF0CD9FF),
          label: WorkoutText.metricPaceMinKm,
          value: paceText,
        ),
      ],
    );
  }
}
