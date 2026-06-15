import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer/feature/workout/model/location_display_policy.dart';

void main() {
  const policy = LocationDisplayPolicy();

  test('precise fix is shown with accuracy label', () {
    final decision = policy.evaluate(accuracyMeters: 12);

    expect(decision.quality, LocationFixQuality.precise);
    expect(decision.showOnMap, isTrue);
    expect(decision.statusLabel, contains('定位精度'));
    expect(decision.statusLabel, contains('12'));
  });

  test('weak but usable fix is still shown instead of getting stuck', () {
    // 80m 在旧的 35m 门槛下会被丢弃，导致一直卡在“等待定位信号”。
    final decision = policy.evaluate(accuracyMeters: 80);

    expect(decision.quality, LocationFixQuality.weak);
    expect(decision.showOnMap, isTrue);
    expect(decision.statusLabel, contains('较弱'));
    expect(decision.statusLabel, contains('80'));
  });

  test('non-positive accuracy is unusable and keeps waiting', () {
    final decision = policy.evaluate(accuracyMeters: 0);

    expect(decision.quality, LocationFixQuality.unusable);
    expect(decision.showOnMap, isFalse);
    expect(decision.statusLabel, '等待定位信号');
  });

  test('accuracy beyond the usable ceiling keeps waiting', () {
    final decision = policy.evaluate(accuracyMeters: 500);

    expect(decision.quality, LocationFixQuality.unusable);
    expect(decision.showOnMap, isFalse);
    expect(decision.statusLabel, '等待定位信号');
  });
}
