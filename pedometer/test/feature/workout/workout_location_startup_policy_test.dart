import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer/feature/workout/model/workout_location_startup_policy.dart';

void main() {
  test('current GPS fix timeout stays short enough for first-screen feedback', () {
    expect(
      WorkoutLocationStartupPolicy.currentFixTimeout,
      lessThanOrEqualTo(const Duration(seconds: 8)),
    );
  });

  test('accepts only recent cached positions for startup seeding', () {
    final now = DateTime(2026, 6, 15, 10, 44);

    expect(
      WorkoutLocationStartupPolicy.canUseCachedPosition(
        recordedAt: now.subtract(const Duration(seconds: 30)),
        now: now,
      ),
      isTrue,
    );
    expect(
      WorkoutLocationStartupPolicy.canUseCachedPosition(
        recordedAt: now.subtract(const Duration(minutes: 5)),
        now: now,
      ),
      isFalse,
    );
  });
}
