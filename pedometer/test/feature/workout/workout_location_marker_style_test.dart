import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer/feature/workout/model/workout_location_marker_style.dart';

void main() {
  test('current location marker is a centered Google-style dot with heading cone', () {
    // 方形画布、圆点居中，便于光锥绕圆点旋转。
    expect(WorkoutLocationMarkerStyle.logicalSize.width, 64);
    expect(WorkoutLocationMarkerStyle.logicalSize.height, 64);
    expect(WorkoutLocationMarkerStyle.dotCenter.dx, 32);
    expect(WorkoutLocationMarkerStyle.dotCenter.dy, 32);
    expect(WorkoutLocationMarkerStyle.dotRadius, 9);
    expect(WorkoutLocationMarkerStyle.whiteRingRadius, 13);

    // 锚点为画布中心（圆点）。
    expect(WorkoutLocationMarkerStyle.anchor.dx, 0.5);
    expect(WorkoutLocationMarkerStyle.anchor.dy, 0.5);

    // 方向光锥从圆点向外张开，且不超出画布。
    expect(WorkoutLocationMarkerStyle.coneRadius, greaterThan(0));
    expect(
      WorkoutLocationMarkerStyle.coneRadius,
      lessThanOrEqualTo(WorkoutLocationMarkerStyle.logicalSize.height / 2),
    );
    expect(WorkoutLocationMarkerStyle.coneHalfAngleRad, greaterThan(0));
  });
}
