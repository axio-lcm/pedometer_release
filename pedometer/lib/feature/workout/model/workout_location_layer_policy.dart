import 'package:pedometer/feature/workout/model/map_coordinate_converter.dart';

class WorkoutLocationLayerDecision {
  final bool useNativeMyLocationLayer;
  final bool useCorrectedFixedMarker;

  const WorkoutLocationLayerDecision({
    required this.useNativeMyLocationLayer,
    required this.useCorrectedFixedMarker,
  });
}

class WorkoutLocationLayerPolicy {
  static const double _coordinateEpsilon = 0.000001;

  const WorkoutLocationLayerPolicy._();

  static WorkoutLocationLayerDecision decide({
    required WorkoutMapCoordinate rawCoordinate,
    required WorkoutMapCoordinate displayCoordinate,
  }) {
    final hasCoordinateOffset =
        (rawCoordinate.latitude - displayCoordinate.latitude).abs() >
            _coordinateEpsilon ||
        (rawCoordinate.longitude - displayCoordinate.longitude).abs() >
            _coordinateEpsilon;

    return WorkoutLocationLayerDecision(
      useNativeMyLocationLayer: !hasCoordinateOffset,
      useCorrectedFixedMarker: hasCoordinateOffset,
    );
  }
}
