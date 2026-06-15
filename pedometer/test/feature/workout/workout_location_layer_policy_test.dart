import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer/feature/workout/model/map_coordinate_converter.dart';
import 'package:pedometer/feature/workout/model/workout_location_layer_policy.dart';

void main() {
  test('uses corrected map overlay for mainland China coordinates', () {
    const raw = WorkoutMapCoordinate(latitude: 22.543096, longitude: 114.057865);
    final display = MapCoordinateConverter.wgs84ToGcj02(raw);

    final decision = WorkoutLocationLayerPolicy.decide(
      rawCoordinate: raw,
      displayCoordinate: display,
    );

    expect(decision.useNativeMyLocationLayer, isFalse);
    expect(decision.useCorrectedFixedMarker, isTrue);
  });

  test('uses native Google my-location layer outside mainland China', () {
    const raw = WorkoutMapCoordinate(latitude: 37.7749, longitude: -122.4194);
    final display = MapCoordinateConverter.wgs84ToGcj02(raw);

    final decision = WorkoutLocationLayerPolicy.decide(
      rawCoordinate: raw,
      displayCoordinate: display,
    );

    expect(decision.useNativeMyLocationLayer, isTrue);
    expect(decision.useCorrectedFixedMarker, isFalse);
  });
}
