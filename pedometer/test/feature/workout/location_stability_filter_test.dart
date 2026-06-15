import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer/feature/workout/model/location_stability_filter.dart';

void main() {
  test('keeps the first accurate coordinate', () {
    final filter = LocationStabilityFilter();

    final accepted = filter.shouldAccept(
      const WorkoutCoordinate(latitude: 31.2304, longitude: 121.4737),
      accuracyMeters: 12,
      recordedAt: DateTime(2026, 6, 15, 8),
    );

    expect(accepted, isTrue);
    expect(filter.lastAccepted, isNotNull);
  });

  test('rejects low accuracy coordinates', () {
    final filter = LocationStabilityFilter(maxAccuracyMeters: 35);

    final accepted = filter.shouldAccept(
      const WorkoutCoordinate(latitude: 31.2304, longitude: 121.4737),
      accuracyMeters: 80,
      recordedAt: DateTime(2026, 6, 15, 8),
    );

    expect(accepted, isFalse);
    expect(filter.lastAccepted, isNull);
  });

  test('rejects impossible jumps between accepted coordinates', () {
    final filter = LocationStabilityFilter(maxSpeedMetersPerSecond: 9);
    final firstTime = DateTime(2026, 6, 15, 8);

    expect(
      filter.shouldAccept(
        const WorkoutCoordinate(latitude: 31.2304, longitude: 121.4737),
        accuracyMeters: 8,
        recordedAt: firstTime,
      ),
      isTrue,
    );

    final accepted = filter.shouldAccept(
      const WorkoutCoordinate(latitude: 31.2404, longitude: 121.4837),
      accuracyMeters: 8,
      recordedAt: firstTime.add(const Duration(seconds: 3)),
    );

    expect(accepted, isFalse);
    expect(filter.lastAccepted?.coordinate.latitude, 31.2304);
  });
}
