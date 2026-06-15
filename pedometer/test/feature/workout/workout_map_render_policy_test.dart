import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer/feature/workout/model/workout_map_render_policy.dart';

void main() {
  test('does not create the platform map before it is allowed', () {
    expect(
      WorkoutMapRenderPolicy.canCreatePlatformMap(
        allowPlatformMap: false,
        isWidgetTest: false,
      ),
      isFalse,
    );
  });

  test('does not create the platform map in widget tests', () {
    expect(
      WorkoutMapRenderPolicy.canCreatePlatformMap(
        allowPlatformMap: true,
        isWidgetTest: true,
      ),
      isFalse,
    );
  });

  test('creates the platform map once allowed even before location is ready', () {
    expect(
      WorkoutMapRenderPolicy.canCreatePlatformMap(
        allowPlatformMap: true,
        isWidgetTest: false,
      ),
      isTrue,
    );
  });
}
