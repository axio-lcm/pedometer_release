import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/config/app_screen.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/feature/home/components/sport_detail_components.dart';
import 'package:pedometer/feature/home/model/health_repository.dart';
import 'package:pedometer/feature/home/model/home_model.dart';
import 'package:pedometer/feature/home/model/sport_detail_model.dart';
import 'package:pedometer/feature/home/views/sport_detail_page.dart';

void main() {
  setUp(() {
    ResourceLoader.loadForTest(
      colors: {'common': {}, 'home': {}, 'phone': {}},
      strings: {'common': {}, 'home': {}, 'phone': {}},
    );
  });

  tearDown(Get.reset);

  Widget wrap(Widget child) {
    return AppScreenAdapter(
      builder: (_) =>
          GetMaterialApp(locale: const Locale('zh', 'CN'), home: child),
    );
  }

  testWidgets('renders day detail content and switches periods', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const SportDetailPage()));
    await tester.pump();

    expect(find.text('6月10日 周二'), findsOneWidget);
    expect(find.text('今日步数'), findsOneWidget);
    expect(find.text('小时步数趋势'), findsOneWidget);
    expect(find.text('晨间步行'), findsOneWidget);
    expect(find.text('目标建议'), findsOneWidget);

    await tester.tap(find.text('周'));
    await tester.pumpAndSettle();

    expect(find.text('6月8日 - 6月14日'), findsOneWidget);
    expect(find.text('本周步数'), findsOneWidget);
    expect(find.text('本周趋势'), findsOneWidget);
    expect(find.text('周总结'), findsOneWidget);

    await tester.tap(find.text('月'));
    await tester.pumpAndSettle();

    expect(find.text('2026年6月'), findsOneWidget);
    expect(find.text('本月步数'), findsOneWidget);
    expect(find.text('月度热力'), findsOneWidget);
    expect(find.text('月度总结'), findsOneWidget);
  });

  testWidgets('renders sport detail data from the health repository', (
    tester,
  ) async {
    final repository = HealthRepository(
      membershipService: const FixedMembershipService(true),
      mockDataSource: const MockHealthDataSource(),
      realDataSource: _FakeSportHealthDataSource(),
    );

    await tester.pumpWidget(wrap(SportDetailPage(repository: repository)));
    await tester.pump();

    expect(find.text('真实同步数据'), findsOneWidget);
    expect(find.text('8,123'), findsOneWidget);
    expect(find.text('5.8'), findsOneWidget);
  });

  testWidgets('uses home hero proportions for the detail period area', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      wrap(const SportDetailPage(initialPeriod: SportPeriod.month)),
    );
    await tester.pump();

    final heroSize = tester.getSize(find.byType(StepProgressHeroCard));
    final metricSize = tester.getSize(find.byType(MetricCard).first);

    expect(heroSize.width / metricSize.width, closeTo(5 / 4, 0.05));
    expect(heroSize.height / heroSize.width, closeTo(1.28, 0.05));
  });

  testWidgets('matches home ring colors and uses a smaller progress badge', (
    tester,
  ) async {
    expect(NeonRingProgress.progressGradientColors, const [
      Color(0xFF00B956),
      Color(0xFF24F04E),
      Color(0xFF6CFF3D),
    ]);

    await tester.pumpWidget(
      wrap(const SportDetailPage(initialPeriod: SportPeriod.month)),
    );
    await tester.pump();

    final percent = tester.widget<Text>(find.text('完成 90%'));
    expect(percent.style?.fontSize, lessThanOrEqualTo(11));
  });

  testWidgets('uses the home bottom tab switching style', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      wrap(const SportDetailPage(initialPeriod: SportPeriod.month)),
    );
    await tester.pump();

    final tabSize = tester.getSize(find.byType(SportPeriodTabBar));
    expect(tabSize.width, 300);
    expect(tabSize.height, 62);

    final selectedTab = find.ancestor(
      of: find.text('月'),
      matching: find.byType(AnimatedContainer),
    );
    final selectedSize = tester.getSize(selectedTab);
    expect(selectedSize.width, 64);
    expect(selectedSize.height, 44);

    final selectedLabel = tester.widget<Text>(find.text('月'));
    expect(selectedLabel.style?.color, AppColors.bgPrimary);
  });

  testWidgets(
    'top navigation keeps only back fixed and accepts optional slots',
    (tester) async {
      var backTapped = 0;
      var rightTapped = 0;

      await tester.pumpWidget(
        wrap(
          AppTopNavigationBar(
            title: '自定义标题',
            rightIcon: Icons.more_horiz_rounded,
            onBack: () => backTapped++,
            onRightTap: () => rightTapped++,
          ),
        ),
      );

      expect(find.text('自定义标题'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));

      expect(backTapped, 1);
      expect(rightTapped, 1);

      await tester.pumpWidget(
        wrap(AppTopNavigationBar(onBack: () => backTapped++)),
      );

      expect(find.text('自定义标题'), findsNothing);
      expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
    },
  );

  testWidgets('caps displayed progress percent at 100', (tester) async {
    const overGoal = SportProgressData(
      title: '本周步数',
      value: 42380,
      goal: 42000,
      goalUnit: '目标',
      badgePrefix: '完成',
    );
    expect(overGoal.percent, 100);

    await tester.pumpWidget(
      wrap(const SportDetailPage(initialPeriod: SportPeriod.week)),
    );
    await tester.pump();

    expect(find.text('完成 100%'), findsOneWidget);
    expect(find.text('完成 101%'), findsNothing);
  });
}

class _FakeSportHealthDataSource implements HealthDataSource {
  @override
  HealthHomeSnapshot homeSnapshot() {
    return const HealthHomeSnapshot(
      step: StepData(steps: 8123, goal: 10000),
      kpis: [],
      trend: [],
      analyses: [],
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
        SportMetricData(
          icon: Icons.local_fire_department_rounded,
          color: Color(0xFFFF9F12),
          title: '卡路里',
          value: '420',
          unit: 'kcal',
        ),
        SportMetricData(
          icon: Icons.timer_rounded,
          color: Color(0xFF0CD9FF),
          title: '活动时间',
          value: '46',
          unit: 'min',
        ),
      ],
      hourly: const [HourlyStepData('12:00', 8123)],
      segments: const [],
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
