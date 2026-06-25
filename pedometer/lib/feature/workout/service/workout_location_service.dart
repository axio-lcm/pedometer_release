import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/feature/workout/model/workout_location_settings_policy.dart';

/// 运动定位授权结果：区分"已授权 / 服务未开 / 被拒绝 / 永久拒绝"，
/// 以便调用方按状态给出不同的引导（开定位服务 / 重试请求 / 去系统设置）。
enum WorkoutLocationAuth { authorized, serviceDisabled, denied, deniedForever }

/// 运动定位平台服务：集中隔离 Geolocator / Compass 插件调用。
class WorkoutLocationService {
  WorkoutLocationService({TargetPlatform? platform})
    : platform = platform ?? defaultTargetPlatform;

  final TargetPlatform platform;

  Future<WorkoutLocationAuth> ensureAuthorized() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return WorkoutLocationAuth.serviceDisabled;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => WorkoutLocationAuth.authorized,
      LocationPermission.deniedForever => WorkoutLocationAuth.deniedForever,
      // denied / unableToDetermine 视为可重试的拒绝。
      _ => WorkoutLocationAuth.denied,
    };
  }

  /// 打开系统「定位服务」开关页（服务未开时引导）。
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  /// 打开本 App 的系统设置页（权限被永久拒绝时引导）。
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<Position?> lastKnownPosition() {
    return Geolocator.getLastKnownPosition();
  }

  Future<Position> currentPosition({required bool tracking}) {
    return Geolocator.getCurrentPosition(
      locationSettings: tracking
          ? WorkoutLocationSettingsPolicy.currentFixSettingsFor(platform)
          : WorkoutLocationSettingsPolicy.startupCurrentFixSettingsFor(
              platform,
            ),
    );
  }

  Stream<Position> positionStream({required bool tracking}) {
    return Geolocator.getPositionStream(
      locationSettings: tracking
          ? WorkoutLocationSettingsPolicy.streamSettingsFor(platform)
          : WorkoutLocationSettingsPolicy.startupStreamSettingsFor(platform),
    );
  }

  Future<void> requestPreciseLocationIfNeeded() async {
    final accuracyStatus = await Geolocator.getLocationAccuracy();
    if (accuracyStatus == LocationAccuracyStatus.reduced) {
      await Geolocator.requestTemporaryFullAccuracy(
        purposeKey: 'WorkoutPreciseLocation',
      );
    }
  }

  Stream<double>? headingStream() {
    final stream = FlutterCompass.events;
    if (stream == null) return null;
    return stream
        .map((event) => event.heading)
        .where((heading) => heading != null)
        .cast<double>();
  }
}
