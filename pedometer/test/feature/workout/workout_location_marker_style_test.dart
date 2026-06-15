import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer/feature/workout/model/workout_location_marker_style.dart';

void main() {
  test('current location marker matches a fixed-size Google style dot', () {
    expect(WorkoutLocationMarkerStyle.logicalSize.width, 48);
    expect(WorkoutLocationMarkerStyle.logicalSize.height, 36);
    expect(WorkoutLocationMarkerStyle.dotCenter.dx, 16);
    expect(WorkoutLocationMarkerStyle.dotCenter.dy, 15);
    expect(WorkoutLocationMarkerStyle.dotRadius, 8);
    expect(WorkoutLocationMarkerStyle.whiteRingRadius, 12);
    expect(
      WorkoutLocationMarkerStyle.anchor.dx,
      WorkoutLocationMarkerStyle.dotCenter.dx /
          WorkoutLocationMarkerStyle.logicalSize.width,
    );
    expect(
      WorkoutLocationMarkerStyle.directionTip.dx,
      greaterThan(WorkoutLocationMarkerStyle.dotCenter.dx),
    );
  });
}
