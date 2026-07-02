import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer/feature/workout/model/indoor_step_distance_estimator.dart';

void main() {
  group('IndoorStepDistanceEstimator', () {
    final baseTime = DateTime(2026, 1, 1, 8);

    test('低步频时按走路步长估算（身高 × 0.415）', () {
      final estimator = IndoorStepDistanceEstimator(heightCm: 175);
      estimator.distanceForSteps(deltaSteps: 5, at: baseTime);
      // 20 步 / 10 秒 = 120 步/分，属于走路档（≤130）。
      final meters = estimator.distanceForSteps(
        deltaSteps: 20,
        at: baseTime.add(const Duration(seconds: 10)),
      );
      expect(meters, closeTo(20 * 1.75 * 0.415, 0.01));
    });

    test('高步频时按跑步步长估算（身高 × 0.60）', () {
      final estimator = IndoorStepDistanceEstimator(heightCm: 175);
      estimator.distanceForSteps(deltaSteps: 5, at: baseTime);
      // 28 步 / 10 秒 = 168 步/分，超过跑步档下限 150。
      final meters = estimator.distanceForSteps(
        deltaSteps: 28,
        at: baseTime.add(const Duration(seconds: 10)),
      );
      expect(meters, closeTo(28 * 1.75 * 0.60, 0.01));
    });

    test('走跑之间的步频线性过渡', () {
      final estimator = IndoorStepDistanceEstimator(heightCm: 175);
      estimator.distanceForSteps(deltaSteps: 5, at: baseTime);
      // 24 步 / 10 秒 = 144 步/分，落在 130-150 过渡区。
      const blend = (144.0 - 130.0) / (150.0 - 130.0);
      const coeff = 0.415 + (0.60 - 0.415) * blend;
      final meters = estimator.distanceForSteps(
        deltaSteps: 24,
        at: baseTime.add(const Duration(seconds: 10)),
      );
      expect(meters, closeTo(24 * 1.75 * coeff, 0.01));
    });

    test('有 GPS 自校准步长时优先使用，忽略身高与步频', () {
      final estimator = IndoorStepDistanceEstimator(
        heightCm: 175,
        calibratedStepLengthMeters: 0.8,
      );
      final meters = estimator.distanceForSteps(deltaSteps: 50, at: baseTime);
      expect(meters, closeTo(50 * 0.8, 0.001));
    });

    test('样本间隔过长（暂停恢复）不计入步频', () {
      final estimator = IndoorStepDistanceEstimator(heightCm: 175);
      estimator.distanceForSteps(deltaSteps: 5, at: baseTime);
      // 间隔 5 分钟远超 30 秒上限，应被忽略：若误计入，步频会变成
      // 200 步 / 300 秒 = 40 步/分，把后续 EMA 拉进走路档。
      estimator.distanceForSteps(
        deltaSteps: 200,
        at: baseTime.add(const Duration(minutes: 5)),
      );
      // 正确实现下，下一个 168 步/分样本直接进入跑步档。
      final meters = estimator.distanceForSteps(
        deltaSteps: 28,
        at: baseTime.add(const Duration(minutes: 5, seconds: 10)),
      );
      expect(meters, closeTo(28 * 1.75 * 0.60, 0.01));
    });

    test('零或负步数增量不产生距离', () {
      final estimator = IndoorStepDistanceEstimator(heightCm: 175);
      expect(estimator.distanceForSteps(deltaSteps: 0, at: baseTime), 0);
      expect(
        estimator.distanceForSteps(
          deltaSteps: -3,
          at: baseTime.add(const Duration(seconds: 5)),
        ),
        0,
      );
    });
  });
}
