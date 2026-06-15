import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/feature/home/model/health_repository.dart';
import 'package:pedometer/feature/home/model/home_model.dart';
import 'package:pedometer/feature/home/model/sport_detail_model.dart';

void main() {
  setUp(() {
    ResourceLoader.loadForTest(colors: {'common': {}}, strings: {'common': {}});
  });

  test('uses mock health data when membership is inactive', () {
    final repository = HealthRepository(
      membershipService: const FixedMembershipService(false),
      mockDataSource: const MockHealthDataSource(),
      realDataSource: _FakeRealHealthDataSource(),
    );

    final home = repository.homeSnapshot();
    final day = repository.sportPeriodData(SportPeriod.day);

    expect(home.step.steps, 5276);
    expect(home.kpis[1].value, '293');
    expect(day.progress.value, 5276);
  });

  test('uses real health data when membership is active', () {
    final repository = HealthRepository(
      membershipService: const FixedMembershipService(true),
      mockDataSource: const MockHealthDataSource(),
      realDataSource: _FakeRealHealthDataSource(),
    );

    final home = repository.homeSnapshot();
    final day = repository.sportPeriodData(SportPeriod.day);

    expect(home.step.steps, 8123);
    expect(home.kpis[1].value, '420');
    expect(day.progress.value, 8123);
    expect(day.metrics[0].value, '5.8');
  });

  test('default repository treats the current user as an active member', () {
    final repository = HealthRepository.defaultRepository();

    expect(repository.membershipService.isActive, isTrue);
  });
}

class _FakeRealHealthDataSource implements HealthDataSource {
  @override
  HealthHomeSnapshot homeSnapshot() {
    return HealthHomeSnapshot(
      step: const StepData(steps: 8123, goal: 10000),
      kpis: const [
        KpiItem(
          icon: Icons.place_rounded,
          color: Color(0xFF7A3DFF),
          title: '距离',
          value: '5.8',
          unit: 'km',
        ),
        KpiItem(
          icon: Icons.local_fire_department_rounded,
          color: Color(0xFFFF9F12),
          title: '卡路里',
          value: '420',
          unit: 'kcal',
        ),
        KpiItem(
          icon: Icons.timer_rounded,
          color: Color(0xFF0CD9FF),
          title: '活动时间',
          value: '46',
          unit: 'min',
        ),
      ],
      trend: const [TrendPoint(label: 'TUE', value: 8123, highlight: true)],
      analyses: const [],
    );
  }

  @override
  SportPeriodData sportPeriodData(SportPeriod period) {
    return SportPeriodData(
      period: period,
      dateTitle: '真实同步数据',
      progress: const SportProgressData(
        title: '今日步数',
        value: 8123,
        goal: 10000,
        goalUnit: '步',
        badgePrefix: '达成',
      ),
      metrics: const [
        SportMetricData(
          icon: Icons.place_rounded,
          color: Color(0xFF7A3DFF),
          title: '距离',
          value: '5.8',
          unit: 'km',
        ),
      ],
      summary: const SportSummaryData(
        icon: Icons.flag_rounded,
        color: Color(0xFF24F04E),
        title: '真实总结',
        primary: '已同步',
        highlight: 'Apple Health',
        secondary: '会员真实健康数据',
        assetName: 'real health data',
      ),
    );
  }
}
