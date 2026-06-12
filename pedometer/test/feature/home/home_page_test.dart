import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/feature/home/components/step_ring_hero_card.dart';
import 'package:pedometer/feature/home/resources/home_resource.dart';
import 'package:pedometer/feature/home/views/sport_detail_page.dart';
import 'package:pedometer/products/init/app.dart';
import 'package:pedometer/products/phone/components/glass_bottom_nav_bar.dart';

void main() {
  setUp(() {
    ResourceLoader.loadForTest(
      colors: {'common': {}, 'home': {}, 'phone': {}},
      strings: {'common': {}, 'home': {}, 'phone': {}},
    );
  });

  tearDown(Get.reset);

  testWidgets('renders key home data', (tester) async {
    await tester.pumpWidget(const PedometerApp());
    await tester.pump();

    expect(find.text('5,276'), findsOneWidget);
    expect(find.text(HomeResource.todaySteps), findsOneWidget);
    expect(find.text('卡路里分析'), findsOneWidget);
    expect(find.textContaining('达成'), findsOneWidget);
  });

  testWidgets('opens sport detail through the registered GetX named route', (
    tester,
  ) async {
    await tester.pumpWidget(const PedometerApp());
    await tester.pump();

    await tester.tap(find.text(HomeResource.entryOverview));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, SportDetailPage.routeName);
    expect(find.byType(SportDetailPage), findsOneWidget);
  });

  testWidgets('renders the step ring as an extended open arc', (tester) async {
    await tester.pumpWidget(const PedometerApp());
    await tester.pump();

    final arc = tester.widget<StepRingArc>(find.byType(StepRingArc));

    expect(arc.sweepDegrees, greaterThan(300));
    expect(arc.sweepDegrees, lessThan(360));
    expect(arc.gapDegrees, lessThan(60));
  });

  testWidgets('renders smoother rounded line charts', (tester) async {
    await tester.pumpWidget(const PedometerApp());
    await tester.pump();

    final charts = tester.widgetList<LineChart>(find.byType(LineChart));
    expect(charts, hasLength(3));

    for (final chart in charts) {
      final bar = chart.data.lineBarsData.single;
      expect(bar.isCurved, isTrue);
      expect(bar.curveSmoothness, greaterThanOrEqualTo(0.5));
      expect(bar.preventCurveOverShooting, isTrue);
      expect(bar.isStrokeCapRound, isTrue);
    }
  });

  testWidgets('uses the shared period tab height and bottom position', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const PedometerApp());
    await tester.pump();

    final navSize = tester.getSize(find.byType(GlassBottomNavBar));
    expect(
      navSize.height,
      AppBottomTabBarMetrics.height + AppBottomTabBarMetrics.bottomOffset,
    );

    final navRect = tester.getRect(find.byType(GlassBottomNavBar));
    final capsuleRect = tester.getRect(
      find.byKey(const ValueKey('shared_bottom_tab_capsule')),
    );
    expect(
      navRect.bottom - capsuleRect.bottom,
      AppBottomTabBarMetrics.bottomOffset,
    );
  });
}
