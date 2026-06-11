import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_screen.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/feature/home/components/sport_detail_components.dart';
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
