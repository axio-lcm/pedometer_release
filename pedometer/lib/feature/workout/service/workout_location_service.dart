import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/feature/workout/model/workout_location_settings_policy.dart';

/// 运动定位平台服务：集中隔离 Geolocator / Compass 插件调用。
class WorkoutLocationService {
  WorkoutLocationService({TargetPlatform? platform})
    : platform = platform ?? defaultTargetPlatform;

  final TargetPlatform platform;

  Future<bool> ensureAuthorized() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }

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
