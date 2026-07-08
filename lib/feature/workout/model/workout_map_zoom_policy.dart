import 'dart:math' as math;

class WorkoutMapZoomPolicy {
  /// Farthest zoom: roughly a 2 km / 2 mi training map overview.
  static const double minZoom = 12;

  /// Closest zoom: roughly a 5 m / 10 ft detail view.
  static const double maxZoom = 21;

  static const double defaultZoom = 14;
  static const double trackingZoom = 17;
  static const double zoomStep = 1;

  const WorkoutMapZoomPolicy._();

  static double clampZoom(double zoom) {
    return zoom.clamp(minZoom, maxZoom).toDouble();
  }

  static double zoomIn(double zoom) => clampZoom(zoom + zoomStep);

  static double zoomOut(double zoom) => clampZoom(zoom - zoomStep);

  static double metersPerPixel({
    required double zoom,
    required double latitude,
  }) {
    final latitudeRadians = latitude * math.pi / 180;
    return 156543.03392 * math.cos(latitudeRadians) / math.pow(2, zoom);
  }

  static double scaleMetersForPixels({
    required double zoom,
    required double latitude,
    required double pixels,
  }) {
    return metersPerPixel(zoom: zoom, latitude: latitude) * pixels;
  }
}
