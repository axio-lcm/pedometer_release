import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/feature/home/components/step_ring_hero_card.dart';
import 'package:pedometer/feature/home/resources/home_resource.dart';
import 'package:pedometer/feature/home/views/sync_history_detail_page.dart';
import 'package:pedometer/feature/home/views/sync_data_detail_page.dart';
import 'package:pedometer/feature/home/views/sync_source_detail_page.dart';
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

  testWidgets(
    'opens sync data detail through the registered GetX named route',
    (tester) async {
      await tester.pumpWidget(const PedometerApp());
      await tester.pump();

      await tester.tap(find.text(HomeResource.entryHealthSync));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, SyncDataDetailPage.routeName);
      expect(find.byType(SyncDataDetailPage), findsOneWidget);
      expect(find.text('同步数据详情'), findsOneWidget);
      expect(find.text('同步成功'), findsOneWidget);
      expect(find.text('数据来源'), findsOneWidget);
      expect(find.text('同步数据总览'), findsNothing);
      expect(find.text('查看'), findsNWidgets(2));
      expect(find.text('数据类型'), findsOneWidget);
      expect(find.text('同步历史'), findsOneWidget);
      expect(find.text('您的数据安全受保护，所有数据均已加密传输。'), findsOneWidget);
    },
  );

  testWidgets('aligns sync detail data type rows to fixed columns', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const PedometerApp());
    await tester.pump();
    await tester.tap(find.text(HomeResource.entryHealthSync));
    await tester.pumpAndSettle();

    final labelLefts = [
      '步数',
      '卡路里',
      '活动时间',
      '距离',
    ].map((text) => tester.getTopLeft(find.text(text)).dx).toList();
    final valueLefts = [
      '12,856 步',
      '1,256 kcal',
      '98 min',
      '8.34 km',
    ].map((text) => tester.getTopLeft(find.text(text)).dx).toList();

    for (final left in labelLefts.skip(1)) {
      expect(left, closeTo(labelLefts.first, 1));
    }
    for (final left in valueLefts.skip(1)) {
      expect(left, closeTo(valueLefts.first, 1));
    }
    expect(valueLefts.first - labelLefts.first, greaterThanOrEqualTo(130));
  });

  testWidgets('opens sync history detail from a sync history row', (
    tester,
  ) async {
    await tester.pumpWidget(const PedometerApp());
    await tester.pump();

    await tester.tap(find.text(HomeResource.entryHealthSync));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('今天 09:41'), 260);
    await tester.pumpAndSettle();
    await tester.tap(find.text('今天 09:41'));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, SyncHistoryDetailPage.routeName);
    expect(find.byType(SyncHistoryDetailPage), findsOneWidget);
    expect(find.text('同步历史详情'), findsOneWidget);
    expect(find.text('本次同步数据'), findsOneWidget);
    expect(find.text('同步信息'), findsOneWidget);
    expect(find.text('SYNC-2026-0513-0941'), findsOneWidget);
    expect(find.byIcon(Icons.sync_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsNothing);
  });

  testWidgets('opens source detail from sync data source view button', (
    tester,
  ) async {
    await tester.pumpWidget(const PedometerApp());
    await tester.pump();

    await tester.tap(find.text(HomeResource.entryHealthSync));
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看').first);
    await tester.pumpAndSettle();

    expect(Get.currentRoute, SyncSourceDetailPage.routeName);
    expect(find.byType(SyncSourceDetailPage), findsOneWidget);
    expect(find.text('Apple Health'), findsWidgets);
    expect(find.text('已连接 Apple Health'), findsOneWidget);
    expect(find.text('Health 同步权限'), findsOneWidget);
    expect(find.text('同步方式'), findsOneWidget);
    expect(find.text('手动同步数据选择'), findsNothing);
    expect(find.text('断开连接'), findsOneWidget);
    expect(find.text('保存设置'), findsOneWidget);
  });

  testWidgets('shows manual sync selection only after selecting manual mode', (
    tester,
  ) async {
    await tester.pumpWidget(const PedometerApp());
    await tester.pump();

    await tester.tap(find.text(HomeResource.entryHealthSync));
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看').first);
    await tester.pumpAndSettle();

    expect(find.text('手动同步数据选择'), findsNothing);

    await tester.scrollUntilVisible(find.text('手动同步'), 260);
    await tester.pumpAndSettle();
    await tester.tap(find.text('手动同步'));
    await tester.pumpAndSettle();

    expect(find.text('手动同步数据选择'), findsOneWidget);
    expect(find.byIcon(Icons.check_box_rounded), findsNWidgets(3));
    expect(find.byIcon(Icons.check_box_outline_blank_rounded), findsOneWidget);

    await tester.tap(find.text('活动时间').last);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_box_rounded), findsNWidgets(4));
    expect(find.byIcon(Icons.check_box_outline_blank_rounded), findsNothing);
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
