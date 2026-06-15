import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer/feature/workout/model/workout_calorie_policy.dart';

void main() {
  test('MET table maps speed bands to expected values', () {
    expect(WorkoutCaloriePolicy.metForSpeedKmh(0), 2.5);
    expect(WorkoutCaloriePolicy.metForSpeedKmh(3.9), 2.5);
    expect(WorkoutCaloriePolicy.metForSpeedKmh(4), 3.5);
    expect(WorkoutCaloriePolicy.metForSpeedKmh(7), 6.0);
    expect(WorkoutCaloriePolicy.metForSpeedKmh(9), 8.3);
    expect(WorkoutCaloriePolicy.metForSpeedKmh(11), 9.8);
    expect(WorkoutCaloriePolicy.metForSpeedKmh(15), 11.0);
  });

  test('kcalForTick = MET * weight * hours', () {
    const policy = WorkoutCaloriePolicy(weightKg: 60);
    final kcal = policy.kcalForTick(speedKmh: 9, seconds: 1);
    expect(kcal, closeTo(8.3 * 60 * (1 / 3600), 1e-9));
  });

  test('default weight is 60kg', () {
    const policy = WorkoutCaloriePolicy();
    expect(policy.weightKg, 60);
  });
}
