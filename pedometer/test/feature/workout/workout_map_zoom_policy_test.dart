import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer/feature/workout/model/workout_map_zoom_policy.dart';

void main() {
  test('clamps zoom to the workout map range', () {
    expect(WorkoutMapZoomPolicy.clampZoom(8), WorkoutMapZoomPolicy.minZoom);
    expect(WorkoutMapZoomPolicy.clampZoom(25), WorkoutMapZoomPolicy.maxZoom);
    expect(WorkoutMapZoomPolicy.clampZoom(14), 14);
  });

  test('zooms in and out by one level within range', () {
    expect(WorkoutMapZoomPolicy.zoomIn(14), 15);
    expect(WorkoutMapZoomPolicy.zoomOut(14), 13);
    expect(WorkoutMapZoomPolicy.zoomIn(WorkoutMapZoomPolicy.maxZoom), 21);
    expect(WorkoutMapZoomPolicy.zoomOut(WorkoutMapZoomPolicy.minZoom), 12);
  });

  test('default zoom scale at the default latitude is about 817 meters per 100 pixels', () {
    final meters = WorkoutMapZoomPolicy.scaleMetersForPixels(
      zoom: WorkoutMapZoomPolicy.defaultZoom,
      latitude: 31.2304,
      pixels: 100,
    );

    expect(meters, closeTo(817, 1));
  });
}
