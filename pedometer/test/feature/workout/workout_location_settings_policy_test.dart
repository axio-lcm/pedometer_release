import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/feature/workout/model/workout_location_settings_policy.dart';

void main() {
  test('iOS uses continuous high accuracy updates without automatic pausing', () {
    final settings = WorkoutLocationSettingsPolicy.streamSettingsFor(
      TargetPlatform.iOS,
    );

    expect(settings, isA<AppleSettings>());
    final apple = settings as AppleSettings;
    expect(apple.accuracy, LocationAccuracy.bestForNavigation);
    expect(apple.distanceFilter, 1);
    expect(apple.pauseLocationUpdatesAutomatically, isFalse);
    expect(apple.allowBackgroundLocationUpdates, isFalse);
  });

  test('Android uses frequent high accuracy foreground updates', () {
    final settings = WorkoutLocationSettingsPolicy.streamSettingsFor(
      TargetPlatform.android,
    );

    expect(settings, isA<AndroidSettings>());
    final android = settings as AndroidSettings;
    expect(android.accuracy, LocationAccuracy.bestForNavigation);
    expect(android.distanceFilter, 1);
    expect(android.intervalDuration, const Duration(seconds: 1));
  });
}
