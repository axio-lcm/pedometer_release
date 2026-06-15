import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer_health/pedometer_health.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(PedometerHealthClient.channelName);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('fetchDailySummaries maps platform payloads', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'fetchDailySummaries');
          expect(call.arguments['source'], 'appleHealth');
          return [
            {
              'date': '2026-06-15',
              'steps': 8123,
              'distanceKm': 5.8,
              'caloriesKcal': 420.0,
              'activeMinutes': 46,
              'source': 'appleHealth',
            },
          ];
        });

    final client = PedometerHealthClient();
    final summaries = await client.fetchDailySummaries(
      source: HealthSyncSource.appleHealth,
      startDate: DateTime(2026, 6, 15),
      endDate: DateTime(2026, 6, 15),
      types: const [
        HealthSyncDataType.steps,
        HealthSyncDataType.distance,
        HealthSyncDataType.calories,
        HealthSyncDataType.activeMinutes,
      ],
    );

    expect(summaries, hasLength(1));
    expect(summaries.single.steps, 8123);
    expect(summaries.single.distanceKm, 5.8);
    expect(summaries.single.source, HealthSyncSource.appleHealth);
  });

  test('requestAuthorization passes source and data types', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'requestAuthorization');
          expect(call.arguments, {
            'source': 'healthConnect',
            'types': ['steps', 'distance'],
          });
          return true;
        });

    final granted = await PedometerHealthClient().requestAuthorization(
      source: HealthSyncSource.healthConnect,
      types: const [HealthSyncDataType.steps, HealthSyncDataType.distance],
    );

    expect(granted, isTrue);
  });

  test('isAvailable passes the requested source', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'isAvailable');
          expect(call.arguments, {'source': 'appleHealth'});
          return true;
        });

    final available = await PedometerHealthClient().isAvailable(
      source: HealthSyncSource.appleHealth,
    );

    expect(available, isTrue);
  });
}
