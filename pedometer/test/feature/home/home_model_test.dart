import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer/feature/home/model/home_model.dart';

void main() {
  group('StepData', () {
    test('progress and percent for 5276/6000', () {
      const d = StepData(steps: 5276, goal: 6000);
      expect(d.percent, 88);
      expect(d.progress, closeTo(0.879, 0.001));
    });

    test('progress clamps to 1.0 when over goal', () {
      const d = StepData(steps: 8000, goal: 6000);
      expect(d.progress, 1.0);
      expect(d.percent, 100);
    });

    test('progress is 0 when goal is 0', () {
      const d = StepData(steps: 100, goal: 0);
      expect(d.progress, 0);
    });
  });
}
