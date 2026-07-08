import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer/feature/workout/model/workout_calorie_policy.dart';

void main() {
  group('WorkoutCaloriePolicy', () {
    test('does not accumulate active calories while stationary', () {
      const policy = WorkoutCaloriePolicy(weightKg: 68);

      expect(policy.kcalForTick(speedKmh: 0, seconds: 60), 0);
      expect(policy.kcalForTick(speedKmh: 0.49, seconds: 60), 0);
    });

    test('uses ACSM walking equation at walking speeds', () {
      const policy = WorkoutCaloriePolicy(weightKg: 60);

      final kcal = policy.kcalForTick(speedKmh: 6, seconds: 60);

      // 6 km/h = 100 m/min; active VO2 = 0.1 * 100 = 10 ml/kg/min.
      // kcal/min = active VO2 * kg / 1000 * 5.
      expect(kcal, closeTo(10 * 60 / 1000 * 5, 1e-9));
    });

    test('uses ACSM running equation at running speeds', () {
      const policy = WorkoutCaloriePolicy(weightKg: 60);

      final kcal = policy.kcalForTick(speedKmh: 12, seconds: 60);

      // 12 km/h = 200 m/min; active VO2 = 0.2 * 200 = 40 ml/kg/min.
      expect(kcal, closeTo(40 * 60 / 1000 * 5, 1e-9));
    });

    test('smooths the walk-run transition', () {
      final low = WorkoutCaloriePolicy.grossVo2ForSpeedKmh(6.5);
      final mid = WorkoutCaloriePolicy.grossVo2ForSpeedKmh(7.25);
      final high = WorkoutCaloriePolicy.grossVo2ForSpeedKmh(8);

      expect(mid, greaterThan(low));
      expect(mid, lessThan(high));
    });
  });
}
