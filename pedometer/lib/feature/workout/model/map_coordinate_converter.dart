import 'dart:math' as math;

class WorkoutMapCoordinate {
  final double latitude;
  final double longitude;

  const WorkoutMapCoordinate({
    required this.latitude,
    required this.longitude,
  });
}

class MapCoordinateConverter {
  static const _axis = 6378245.0;
  static const _eccentricity = 0.00669342162296594323;

  const MapCoordinateConverter._();

  static WorkoutMapCoordinate wgs84ToGcj02(WorkoutMapCoordinate coordinate) {
    final latitude = coordinate.latitude;
    final longitude = coordinate.longitude;
    if (_isOutsideMainlandChina(latitude, longitude)) {
      return coordinate;
    }

    var deltaLatitude = _transformLatitude(
      longitude - 105.0,
      latitude - 35.0,
    );
    var deltaLongitude = _transformLongitude(
      longitude - 105.0,
      latitude - 35.0,
    );
    final radLatitude = latitude / 180.0 * math.pi;
    var magic = math.sin(radLatitude);
    magic = 1 - _eccentricity * magic * magic;
    final sqrtMagic = math.sqrt(magic);

    deltaLatitude =
        (deltaLatitude * 180.0) /
        ((_axis * (1 - _eccentricity)) /
            (magic * sqrtMagic) *
            math.pi);
    deltaLongitude =
        (deltaLongitude * 180.0) /
        (_axis / sqrtMagic * math.cos(radLatitude) * math.pi);

    return WorkoutMapCoordinate(
      latitude: latitude + deltaLatitude,
      longitude: longitude + deltaLongitude,
    );
  }

  static bool _isOutsideMainlandChina(double latitude, double longitude) {
    return longitude < 72.004 ||
        longitude > 137.8347 ||
        latitude < 0.8293 ||
        latitude > 55.8271;
  }

  static double _transformLatitude(double x, double y) {
    var result =
        -100.0 +
        2.0 * x +
        3.0 * y +
        0.2 * y * y +
        0.1 * x * y +
        0.2 * math.sqrt(x.abs());
    result +=
        (20.0 * math.sin(6.0 * x * math.pi) +
            20.0 * math.sin(2.0 * x * math.pi)) *
        2.0 /
        3.0;
    result +=
        (20.0 * math.sin(y * math.pi) +
            40.0 * math.sin(y / 3.0 * math.pi)) *
        2.0 /
        3.0;
    result +=
        (160.0 * math.sin(y / 12.0 * math.pi) +
            320 * math.sin(y * math.pi / 30.0)) *
        2.0 /
        3.0;
    return result;
  }

  static double _transformLongitude(double x, double y) {
    var result =
        300.0 +
        x +
        2.0 * y +
        0.1 * x * x +
        0.1 * x * y +
        0.1 * math.sqrt(x.abs());
    result +=
        (20.0 * math.sin(6.0 * x * math.pi) +
            20.0 * math.sin(2.0 * x * math.pi)) *
        2.0 /
        3.0;
    result +=
        (20.0 * math.sin(x * math.pi) +
            40.0 * math.sin(x / 3.0 * math.pi)) *
        2.0 /
        3.0;
    result +=
        (150.0 * math.sin(x / 12.0 * math.pi) +
            300.0 * math.sin(x / 30.0 * math.pi)) *
        2.0 /
        3.0;
    return result;
  }
}
