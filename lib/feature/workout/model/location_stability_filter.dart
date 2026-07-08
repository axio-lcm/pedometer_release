import 'dart:math' as math;

class WorkoutCoordinate {
  final double latitude;
  final double longitude;

  const WorkoutCoordinate({required this.latitude, required this.longitude});
}

class AcceptedWorkoutLocation {
  final WorkoutCoordinate coordinate;
  final double accuracyMeters;
  final DateTime recordedAt;

  const AcceptedWorkoutLocation({
    required this.coordinate,
    required this.accuracyMeters,
    required this.recordedAt,
  });
}

class LocationStabilityFilter {
  final double maxAccuracyMeters;
  final double maxSpeedMetersPerSecond;

  AcceptedWorkoutLocation? _lastAccepted;

  LocationStabilityFilter({
    this.maxAccuracyMeters = 35,
    this.maxSpeedMetersPerSecond = 9,
  });

  AcceptedWorkoutLocation? get lastAccepted => _lastAccepted;

  bool shouldAccept(
    WorkoutCoordinate coordinate, {
    required double accuracyMeters,
    required DateTime recordedAt,
  }) {
    if (accuracyMeters <= 0 || accuracyMeters > maxAccuracyMeters) {
      return false;
    }

    final previous = _lastAccepted;
    if (previous != null) {
      final seconds = recordedAt
          .difference(previous.recordedAt)
          .inMilliseconds
          .abs()
          .clamp(1, double.maxFinite);
      final distance = distanceMeters(previous.coordinate, coordinate);
      final speed = distance / (seconds / 1000);
      if (speed > maxSpeedMetersPerSecond) {
        return false;
      }
    }

    _lastAccepted = AcceptedWorkoutLocation(
      coordinate: coordinate,
      accuracyMeters: accuracyMeters,
      recordedAt: recordedAt,
    );
    return true;
  }

  static double distanceMeters(WorkoutCoordinate a, WorkoutCoordinate b) {
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
