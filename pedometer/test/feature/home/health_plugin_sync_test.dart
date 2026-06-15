import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/feature/home/model/health_repository.dart';
import 'package:pedometer/feature/home/model/sport_detail_model.dart';
import 'package:pedometer_health/pedometer_health.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(PedometerHealthClient.channelName);

  setUp(() {
    ResourceLoader.loadForTest(colors: {'common': {}}, strings: {'common': {}});
    HealthSyncRuntime.resetForTest();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('synced plugin summaries feed dashboard and period data', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'fetchDailySummaries');
          return [
            {
              'date': '2026-06-14',
              'steps': 3900,
              'distanceKm': 2.7,
              'caloriesKcal': 180.0,
              'activeMinutes': 25,
              'source': 'appleHealth',
            },
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

    final service = HealthPluginSyncService(client: PedometerHealthClient());
    final syncedSource = await service.sync(
      source: HealthSyncSource.appleHealth,
      startDate: DateTime(2026, 6, 14),
      endDate: DateTime(2026, 6, 15),
    );
    final repository = HealthRepository(
      membershipService: const FixedMembershipService(true),
      mockDataSource: const MockHealthDataSource(),
      realDataSource: syncedSource,
    );

    final home = repository.homeSnapshot();
    final day = repository.sportPeriodData(SportPeriod.day);
    final week = repository.sportPeriodData(SportPeriod.week);

    expect(home.step.steps, 8123);
    expect(home.kpis[0].value, '5.8');
    expect(home.kpis[1].value, '420');
    expect(day.progress.value, 8123);
    expect(week.progress.value, 12023);
  });

  test(
    'default member repository reads the latest synced health data',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'fetchDailySummaries') {
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
            }
            return true;
          });

      final service = HealthPluginSyncService(client: PedometerHealthClient());
      final syncedSource = await service.sync(
        source: HealthSyncSource.appleHealth,
        startDate: DateTime(2026, 6, 15),
        endDate: DateTime(2026, 6, 15),
      );

      HealthSyncRuntime.replaceRealDataSource(syncedSource);
      final home = HealthRepository.defaultRepository().homeSnapshot();

      expect(home.step.steps, 8123);
      expect(home.kpis[1].value, '420');
    },
  );
}
