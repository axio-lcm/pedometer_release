import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';

void main() {
  test('copyWith overrides live fields and keeps the rest', () {
    final updated = WorkoutTrackingData.mock.copyWith(
      status: WorkoutStatus.running,
      distanceKm: '0.42',
      duration: '00:01:05',
      calories: '7',
      pace: "05'00''",
    );

    expect(updated.status, WorkoutStatus.running);
    expect(updated.distanceKm, '0.42');
    expect(updated.duration, '00:01:05');
    expect(updated.calories, '7');
    expect(updated.pace, "05'00''");
    // 未覆盖字段保持 mock 原值。
    expect(updated.workoutTitle, WorkoutTrackingData.mock.workoutTitle);
    expect(updated.targetKm, WorkoutTrackingData.mock.targetKm);
  });
}
