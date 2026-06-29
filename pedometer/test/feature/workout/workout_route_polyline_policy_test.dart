import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pedometer/feature/workout/model/workout_route_polyline_policy.dart';

void main() {
  group('WorkoutRoutePolylinePolicy', () {
    test('rounds visible corners with interpolated points', () {
      const route = [
        LatLng(31.2300, 121.4700),
        LatLng(31.2300, 121.4710),
        LatLng(31.2310, 121.4710),
      ];

      final smoothed = WorkoutRoutePolylinePolicy.smoothForDisplay(route);

      expect(smoothed.length, greaterThan(route.length));
      expect(smoothed.first, route.first);
      expect(smoothed.last, route.last);
      expect(smoothed, isNot(contains(route[1])));
    });

    test('keeps nearly straight routes unchanged', () {
      const route = [
        LatLng(31.2300, 121.4700),
        LatLng(31.2305, 121.4705),
        LatLng(31.2310, 121.4710),
      ];

      final smoothed = WorkoutRoutePolylinePolicy.smoothForDisplay(route);

      expect(smoothed, route);
    });
  });
}
