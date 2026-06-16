import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/feature/workout/model/workout_location_startup_policy.dart';

class WorkoutLocationSettingsPolicy {
  const WorkoutLocationSettingsPolicy._();

  static LocationSettings startupStreamSettingsFor(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return AppleSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 5,
          pauseLocationUpdatesAutomatically: true,
          allowBackgroundLocationUpdates: false,
          showBackgroundLocationIndicator: false,
        );
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 5,
          intervalDuration: const Duration(seconds: 2),
        );
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 5,
        );
    }
  }

  static LocationSettings streamSettingsFor(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return AppleSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 1,
          pauseLocationUpdatesAutomatically: false,
          allowBackgroundLocationUpdates: false,
          showBackgroundLocationIndicator: false,
        );
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 1,
          intervalDuration: const Duration(seconds: 1),
        );
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 1,
        );
    }
  }

  static LocationSettings startupCurrentFixSettingsFor(
    TargetPlatform platform,
  ) {
    switch (platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return AppleSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 5,
          timeLimit: WorkoutLocationStartupPolicy.startupFixTimeout,
          pauseLocationUpdatesAutomatically: true,
          allowBackgroundLocationUpdates: false,
          showBackgroundLocationIndicator: false,
        );
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 5,
          timeLimit: WorkoutLocationStartupPolicy.startupFixTimeout,
          intervalDuration: const Duration(seconds: 2),
        );
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 5,
          timeLimit: WorkoutLocationStartupPolicy.startupFixTimeout,
        );
    }
  }

  static LocationSettings currentFixSettingsFor(TargetPlatform platform) {
    final base = streamSettingsFor(platform);
    switch (base) {
      case AppleSettings():
        return AppleSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1,
          timeLimit: WorkoutLocationStartupPolicy.currentFixTimeout,
          pauseLocationUpdatesAutomatically:
              base.pauseLocationUpdatesAutomatically,
          allowBackgroundLocationUpdates: false,
          showBackgroundLocationIndicator: false,
        );
      case AndroidSettings():
        return AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1,
          timeLimit: WorkoutLocationStartupPolicy.currentFixTimeout,
          intervalDuration: const Duration(seconds: 1),
        );
      default:
        return const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1,
          timeLimit: WorkoutLocationStartupPolicy.currentFixTimeout,
        );
    }
  }
}
