import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pedometer/feature/workout/viewmodel/workout_tracking_view_model.dart';

void main() {
  group('WorkoutTrackingViewModel', () {
    test('filters weak accuracy and impossible GPS jumps from distance', () {
      final controller = WorkoutTrackingViewModel();
      final start = DateTime(2026, 1, 1, 8);

      controller.start();
      controller.onFix(_position(0, 0, start, accuracy: 5), const LatLng(0, 0));

      controller.onFix(
        _position(
          0,
          0.001,
          start.add(const Duration(seconds: 60)),
          accuracy: 80,
        ),
        const LatLng(0, 0.001),
      );
      expect(controller.distanceMeters.value, 0);
      expect(controller.pathPoints, [const LatLng(0, 0)]);

      controller.onFix(
        _position(0, 0.01, start.add(const Duration(seconds: 61)), accuracy: 5),
        const LatLng(0, 0.01),
      );
      expect(controller.distanceMeters.value, 0);
      expect(controller.pathPoints, [const LatLng(0, 0)]);

      controller.onFix(
        _position(
          0,
          0.001,
          start.add(const Duration(seconds: 120)),
          accuracy: 5,
        ),
        const LatLng(0, 0.001),
      );
      expect(controller.distanceMeters.value, closeTo(111, 1));

      controller.end();
      controller.onClose();
    });

    test('keeps realtime pace separate from average pace', () {
      final controller = WorkoutTrackingViewModel();

      controller.distanceMeters.value = 1000;
      controller.elapsed.value = const Duration(minutes: 6);
      controller.pace.value = const Duration(minutes: 5);

      expect(controller.paceText, "05'00''");
      expect(controller.averagePaceText, "06'00''");

      controller.onClose();
    });
  });
}

Position _position(
  double latitude,
  double longitude,
  DateTime timestamp, {
  required double accuracy,
  double speed = 0,
}) {
  return Position(
    longitude: longitude,
    latitude: latitude,
    timestamp: timestamp,
    accuracy: accuracy,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: speed,
    speedAccuracy: 0,
  );
}
