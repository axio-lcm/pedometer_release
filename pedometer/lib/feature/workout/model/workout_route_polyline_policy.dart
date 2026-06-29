import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class WorkoutRoutePolylinePolicy {
  const WorkoutRoutePolylinePolicy._();

  static const double _cornerRadiusFraction = 0.35;
  static const double _maxCornerRadiusMeters = 8;
  static const double _minCornerRadiusMeters = 0.45;
  static const double _minTurnDegrees = 8;
  static const int _curveSteps = 8;

  static Set<Polyline> build(Iterable<LatLng> points) {
    final snapshot = points.toList(growable: false);
    if (snapshot.length < 2) return const {};
    return {
      Polyline(
        polylineId: const PolylineId('workout-route'),
        points: smoothForDisplay(snapshot),
        color: const Color(0xFF24F04E),
        width: 16,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }

  /// 将原始 GPS 折线转换成显示用圆角曲线。
  ///
  /// 这里只影响地图上的视觉线条，不修改原始轨迹点、距离、配速或历史记录。
  static List<LatLng> smoothForDisplay(List<LatLng> points) {
    if (points.length < 3) return points;

    final smoothed = <LatLng>[points.first];
    for (var i = 1; i < points.length - 1; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final next = points[i + 1];

      final previousDistance = _distanceMeters(previous, current);
      final nextDistance = _distanceMeters(current, next);
      if (previousDistance <= 0 || nextDistance <= 0) {
        _appendIfDistinct(smoothed, current);
        continue;
      }

      final turnDegrees = _turnDegrees(previous, current, next);
      if (turnDegrees < _minTurnDegrees) {
        _appendIfDistinct(smoothed, current);
        continue;
      }

      final radiusMeters = math.min(
        _maxCornerRadiusMeters,
        math.min(previousDistance, nextDistance) * _cornerRadiusFraction,
      );
      if (radiusMeters < _minCornerRadiusMeters) {
        _appendIfDistinct(smoothed, current);
        continue;
      }

      final approach = _lerp(
        current,
        previous,
        radiusMeters / previousDistance,
      );
      final departure = _lerp(current, next, radiusMeters / nextDistance);

      _appendIfDistinct(smoothed, approach);
      for (var step = 1; step <= _curveSteps; step++) {
        final t = step / _curveSteps;
        _appendIfDistinct(
          smoothed,
          _quadraticBezier(approach, current, departure, t),
        );
      }
    }
    _appendIfDistinct(smoothed, points.last);
    return List<LatLng>.unmodifiable(smoothed);
  }

  static void _appendIfDistinct(List<LatLng> points, LatLng point) {
    if (points.isEmpty || points.last != point) points.add(point);
  }

  static LatLng _quadraticBezier(
    LatLng start,
    LatLng control,
    LatLng end,
    double t,
  ) {
    final inverse = 1 - t;
    final latitude =
        inverse * inverse * start.latitude +
        2 * inverse * t * control.latitude +
        t * t * end.latitude;
    final longitude =
        inverse * inverse * start.longitude +
        2 * inverse * t * control.longitude +
        t * t * end.longitude;
    return LatLng(latitude, longitude);
  }

  static LatLng _lerp(LatLng from, LatLng to, double t) {
    return LatLng(
      from.latitude + (to.latitude - from.latitude) * t,
      from.longitude + (to.longitude - from.longitude) * t,
    );
  }

  static double _turnDegrees(LatLng previous, LatLng current, LatLng next) {
    final ax = current.longitude - previous.longitude;
    final ay = current.latitude - previous.latitude;
    final bx = next.longitude - current.longitude;
    final by = next.latitude - current.latitude;
    final aLength = math.sqrt(ax * ax + ay * ay);
    final bLength = math.sqrt(bx * bx + by * by);
    if (aLength == 0 || bLength == 0) return 0;

    final dot = (ax * bx + ay * by) / (aLength * bLength);
    final angle = math.acos(dot.clamp(-1, 1));
    return angle * 180 / math.pi;
  }

  static double _distanceMeters(LatLng a, LatLng b) {
    const earthRadiusMeters = 6371000.0;
    final lat1 = _radians(a.latitude);
    final lat2 = _radians(b.latitude);
    final deltaLat = _radians(b.latitude - a.latitude);
    final deltaLon = _radians(b.longitude - a.longitude);

    final h =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    return earthRadiusMeters * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
}
