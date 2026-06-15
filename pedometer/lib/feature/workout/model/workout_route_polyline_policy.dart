import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class WorkoutRoutePolylinePolicy {
  const WorkoutRoutePolylinePolicy._();

  static Set<Polyline> build(Iterable<LatLng> points) {
    final snapshot = points.toList(growable: false);
    if (snapshot.length < 2) return const {};
    return {
      Polyline(
        polylineId: const PolylineId('workout-route'),
        points: snapshot,
        color: const Color(0xFF24F04E),
        width: 6,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }
}
