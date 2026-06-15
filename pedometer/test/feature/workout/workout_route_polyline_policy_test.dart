import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pedometer/feature/workout/model/workout_route_polyline_policy.dart';

void main() {
  test('does not create a route polyline with fewer than two points', () {
    expect(WorkoutRoutePolylinePolicy.build({}), isEmpty);
    expect(
      WorkoutRoutePolylinePolicy.build({const LatLng(31.0, 121.0)}),
      isEmpty,
    );
  });

  test('creates a GoogleMap route polyline from a route point snapshot', () {
    final polylines = WorkoutRoutePolylinePolicy.build({
      const LatLng(31.0, 121.0),
      const LatLng(31.00002, 121.0),
    });

    expect(polylines, hasLength(1));
    final route = polylines.single;
    expect(route.polylineId, const PolylineId('workout-route'));
    expect(route.points, [
      const LatLng(31.0, 121.0),
      const LatLng(31.00002, 121.0),
    ]);
    expect(route.width, 6);
  });
}
