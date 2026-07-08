import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class WorkoutRoutePolylinePolicy {
  const WorkoutRoutePolylinePolicy._();

  static const double _cornerRadiusFraction = 0.35;
  static const double _maxCornerRadiusMeters = 8;
  static const double _minCornerRadiusMeters = 0.45;
  static const double _minTurnDegrees = 8;
  static const double _displaySimplifyToleranceMeters = 12;
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

    final cleaned = _simplifyStraightNoise(points);
    if (cleaned.length < 3) return cleaned;

    final smoothed = <LatLng>[cleaned.first];
    for (var i = 1; i < cleaned.length - 1; i++) {
      final previous = cleaned[i - 1];
      final current = cleaned[i];
      final next = cleaned[i + 1];

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
    _appendIfDistinct(smoothed, cleaned.last);
    return List<LatLng>.unmodifiable(smoothed);
  }

  /// 去掉直线段上的 GPS 横向漂移点。
  ///
  /// 真正的大拐弯会被保留；这里只把落在起终点连线附近的中间抖动点抽掉，
  /// 再交给圆角算法做视觉平滑。
  static List<LatLng> _simplifyStraightNoise(List<LatLng> points) {
    if (points.length < 4) return points;

    final keep = List<bool>.filled(points.length, false);
    keep[0] = true;
    keep[points.length - 1] = true;
    final stack = <({int start, int end})>[(start: 0, end: points.length - 1)];

    while (stack.isNotEmpty) {
      final range = stack.removeLast();
      var maxDistance = 0.0;
      var maxIndex = -1;
      for (var i = range.start + 1; i < range.end; i++) {
        final distance = _perpendicularDistanceMeters(
          points[i],
          points[range.start],
          points[range.end],
        );
        if (distance > maxDistance) {
          maxDistance = distance;
          maxIndex = i;
        }
      }

      if (maxIndex != -1 && maxDistance > _displaySimplifyToleranceMeters) {
        keep[maxIndex] = true;
        stack
          ..add((start: range.start, end: maxIndex))
          ..add((start: maxIndex, end: range.end));
      }
    }

    final simplified = <LatLng>[];
    for (var i = 0; i < points.length; i++) {
      if (keep[i]) simplified.add(points[i]);
    }
    return simplified;
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

  static double _perpendicularDistanceMeters(
    LatLng point,
    LatLng segmentStart,
    LatLng segmentEnd,
  ) {
    final origin = segmentStart;
    final p = _projectMeters(point, origin);
    final a = _projectMeters(segmentStart, origin);
    final b = _projectMeters(segmentEnd, origin);
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    if (dx == 0 && dy == 0) return _distanceMeters(point, segmentStart);

    final t =
        (((p.dx - a.dx) * dx) + ((p.dy - a.dy) * dy)) / (dx * dx + dy * dy);
    final clamped = t.clamp(0.0, 1.0).toDouble();
    final closest = Offset(a.dx + dx * clamped, a.dy + dy * clamped);
    return (p - closest).distance;
  }

  static Offset _projectMeters(LatLng point, LatLng origin) {
    const metersPerDegreeLatitude = 111320.0;
    final latRadians = _radians(origin.latitude);
    final metersPerDegreeLongitude =
        metersPerDegreeLatitude * math.cos(latRadians);
    return Offset(
      (point.longitude - origin.longitude) * metersPerDegreeLongitude,
      (point.latitude - origin.latitude) * metersPerDegreeLatitude,
    );
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
}
