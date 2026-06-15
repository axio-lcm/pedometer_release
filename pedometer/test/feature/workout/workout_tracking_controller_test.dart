import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';
import 'package:pedometer/feature/workout/viewmodel/workout_tracking_controller.dart';

Position _pos(double lat, double lng, {double speed = 0, DateTime? at}) {
  return Position(
    latitude: lat,
    longitude: lng,
    timestamp: at ?? DateTime(2026, 6, 15, 8),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: speed,
    speedAccuracy: 0,
  );
}

void main() {
  test('start resets metrics and pins the start point', () {
    final c = WorkoutTrackingController();
    c.onFix(_pos(31.0, 121.0), const LatLng(31.0, 121.0));
    c.start();

    expect(c.status.value, WorkoutStatus.running);
    expect(c.distanceMeters.value, 0);
    expect(c.elapsed.value, Duration.zero);
    expect(c.calories.value, 0);
    expect(c.startPoint.value, const LatLng(31.0, 121.0));
    expect(c.pathPoints, [const LatLng(31.0, 121.0)]);
  });

  test('distance accumulates only while running and ignores sub-threshold jitter', () {
    final c = WorkoutTrackingController(minMoveMeters: 2.5);
    c.onFix(_pos(31.20000, 121.40000), const LatLng(31.20000, 121.40000));
    c.start();
    // ~1.1m（< 2.5m 抖动门限，应被丢弃）。
    c.onFix(_pos(31.200010, 121.40000), const LatLng(31.200010, 121.40000));
    expect(c.distanceMeters.value, 0);

    // ~55m（> 门限，应累计）。
    c.onFix(_pos(31.200510, 121.40000), const LatLng(31.200510, 121.40000));
    expect(c.distanceMeters.value, greaterThan(50));
    expect(c.pathPoints.length, 2); // 起点 + 1 个有效移动点
  });

  test('paused freezes the timer; running accumulates duration and calories', () {
    fakeAsync((async) {
      final c = WorkoutTrackingController();
      c.onFix(_pos(31.0, 121.0, speed: 2.5), const LatLng(31.0, 121.0)); // 9km/h
      c.start();
      async.elapse(const Duration(seconds: 3));
      expect(c.elapsed.value, const Duration(seconds: 3));
      expect(c.calories.value, greaterThan(0));

      final frozen = c.calories.value;
      c.pause();
      async.elapse(const Duration(seconds: 5));
      expect(c.elapsed.value, const Duration(seconds: 3)); // 暂停期间不走动
      expect(c.calories.value, frozen);

      c.resume();
      async.elapse(const Duration(seconds: 2));
      expect(c.elapsed.value, const Duration(seconds: 5));
      c.end();
    });
  });

  test('togglePrimary follows the state machine', () {
    final c = WorkoutTrackingController();
    c.onFix(_pos(31.0, 121.0), const LatLng(31.0, 121.0));
    expect(c.status.value, WorkoutStatus.ready);
    c.togglePrimary();
    expect(c.status.value, WorkoutStatus.running);
    c.togglePrimary();
    expect(c.status.value, WorkoutStatus.paused);
    c.togglePrimary();
    expect(c.status.value, WorkoutStatus.running);
    c.end();
    expect(c.status.value, WorkoutStatus.ended);
  });

  test('durationText / distanceKmText / paceText format correctly', () {
    final c = WorkoutTrackingController();
    expect(c.durationText, '00:00:00');
    expect(c.distanceKmText, '0.00');
    expect(c.paceText, "--'--''"); // 无配速数据
  });
}
