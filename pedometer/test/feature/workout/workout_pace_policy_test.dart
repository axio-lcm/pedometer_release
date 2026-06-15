import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer/feature/workout/model/workout_pace_policy.dart';

void main() {
  final t0 = DateTime(2026, 6, 15, 8);

  test('returns null with fewer than two samples', () {
    final policy = WorkoutPacePolicy();
    expect(policy.pacePerKm, isNull);
    policy.addSample(cumulativeMeters: 0, at: t0);
    expect(policy.pacePerKm, isNull);
  });

  test('returns null until window distance reaches the minimum gate', () {
    final policy = WorkoutPacePolicy(minWindowMeters: 30);
    policy.addSample(cumulativeMeters: 0, at: t0);
    policy.addSample(cumulativeMeters: 10, at: t0.add(const Duration(seconds: 5)));
    expect(policy.pacePerKm, isNull);
  });

  test('computes pace from window distance and time', () {
    final policy = WorkoutPacePolicy(minWindowMeters: 30);
    policy.addSample(cumulativeMeters: 0, at: t0);
    // 100m 用 20s（落在默认 20s 窗口内）→ 配速 = 20s / 0.1km = 200 s/km。
    policy.addSample(cumulativeMeters: 100, at: t0.add(const Duration(seconds: 20)));
    expect(policy.pacePerKm, const Duration(seconds: 200));
  });

  test('slides out samples older than the window', () {
    final policy = WorkoutPacePolicy(
      windowDuration: const Duration(seconds: 20),
      minWindowMeters: 30,
    );
    policy.addSample(cumulativeMeters: 0, at: t0);
    policy.addSample(cumulativeMeters: 100, at: t0.add(const Duration(seconds: 30)));
    // 第二个样本距首样本 30s > 20s 窗口 → 旧样本被滑出，只剩 1 个 → null。
    expect(policy.pacePerKm, isNull);
    policy.addSample(cumulativeMeters: 200, at: t0.add(const Duration(seconds: 40)));
    // 窗口内：100m(@30s) → 200m(@40s) = 100m / 10s = 100 s/km。
    expect(policy.pacePerKm, const Duration(seconds: 100));
  });

  test('reset clears samples', () {
    final policy = WorkoutPacePolicy(minWindowMeters: 30);
    policy.addSample(cumulativeMeters: 0, at: t0);
    policy.addSample(cumulativeMeters: 200, at: t0.add(const Duration(seconds: 60)));
    policy.reset();
    expect(policy.pacePerKm, isNull);
  });
}
