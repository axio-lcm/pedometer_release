import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_screen.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/feature/workout/components/workout_components.dart';
import 'package:pedometer/feature/workout/components/workout_tracking_components.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';
import 'package:pedometer/feature/workout/views/workout_page.dart';
import 'package:pedometer/feature/workout/views/workout_tracking_page.dart';

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
      builder: (_) => GetMaterialApp(
        locale: const Locale('zh', 'CN'),
        home: child,
        getPages: [
          GetPage(
            name: WorkoutRouteTable.pathTracking,
            page: () => const WorkoutTrackingPage(),
          ),
        ],
      ),
    );
  }

  for (final size in const [
    Size(320, 568), // 小屏
    Size(360, 740), // 常见安卓
    Size(375, 812), // iPhone 标准
  ]) {
    testWidgets('workout page renders without exception at '
        '${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrap(const WorkoutPage()));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('准备开始今天的训练'), findsOneWidget);
      expect(find.text('运动目标与成就'), findsOneWidget);
    });
  }

  testWidgets('tapping a workout type switches the selected card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(wrap(const WorkoutPage()));
    await tester.pump();

    // 默认选中「户外跑步」：仅一个选中勾。
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.tap(find.text('徒步'));
    await tester.pump();

    // 切换后仍只有一个选中勾，且页面无异常。
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.byType(WorkoutTypeCard), findsNWidgets(4));
  });

  testWidgets('tapping start opens workout tracking page through GetX', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(wrap(const WorkoutPage()));
    await tester.pump();

    await tester.tap(find.text('开始运动'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(Get.currentRoute, WorkoutTrackingPage.routeName);
    expect(find.byType(WorkoutMapView), findsOneWidget);
    expect(find.text('户外跑步'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
    expect(find.text('GPS'), findsOneWidget);
    expect(find.text('累计距离（公里）'), findsOneWidget);
    expect(find.text('2.35'), findsOneWidget);
    expect(find.text('目标 8.00 公里'), findsOneWidget);
    expect(find.text('00:18:36'), findsOneWidget);
    expect(find.text('186'), findsOneWidget);
    expect(find.text("07'54''"), findsOneWidget);
    expect(
      tester
          .widget<NeonPauseButton>(find.byType(NeonPauseButton))
          .showStartIcon,
      isTrue,
    );
    expect(find.byIcon(Icons.pause_rounded), findsNothing);
    expect(find.text('开始'), findsOneWidget);
    expect(find.text('长按结束'), findsNothing);
    expect(find.text('运动音乐'), findsOneWidget);
    expect(find.text('播放中'), findsOneWidget);
  });

  testWidgets('start control switches from ready to running on tap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(wrap(const WorkoutTrackingPage()));
    await tester.pump();

    expect(
      tester
          .widget<NeonPauseButton>(find.byType(NeonPauseButton))
          .showStartIcon,
      isTrue,
    );
    expect(find.text('开始'), findsOneWidget);
    expect(find.text('长按结束'), findsNothing);
    final readyDistanceRect = tester.getRect(find.text('2.35'));
    final readyLabelCenterY = tester.getCenter(find.text('累计距离（公里）')).dy;
    final readyTargetCenterY = tester.getCenter(find.text('目标 8.00 公里')).dy;
    expect((readyTargetCenterY - readyLabelCenterY).abs(), greaterThan(40));
    final musicTopBeforeStart = tester
        .getTopLeft(find.byType(WorkoutMusicCard))
        .dy;

    await tester.tap(find.byType(NeonPauseButton));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<NeonPauseButton>(find.byType(NeonPauseButton))
          .showStartIcon,
      isFalse,
    );
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(find.text('开始'), findsNothing);
    expect(find.text('长按结束'), findsOneWidget);
    final runningDistanceRect = tester.getRect(find.text('2.35'));
    expect(runningDistanceRect.top, greaterThan(readyDistanceRect.top));
    expect(runningDistanceRect.top, greaterThan(400));
    final metricPanelRect = tester.getRect(find.byType(WorkoutMetricPanel));
    expect(metricPanelRect.top - runningDistanceRect.bottom, greaterThan(0));
    expect(
      metricPanelRect.top - runningDistanceRect.bottom,
      lessThanOrEqualTo(24),
    );
    expect(runningDistanceRect.width, lessThan(readyDistanceRect.width));
    final runningLabelText = tester.widget<Text>(find.text('累计距离（公里）'));
    final runningValueText = tester.widget<Text>(find.text('2.35'));
    final runningTargetText = tester.widget<Text>(find.text('目标 8.00 公里'));
    expect(
      runningValueText.style?.fontSize,
      runningLabelText.style!.fontSize! + 5,
    );
    expect(
      runningValueText.style?.fontSize,
      runningTargetText.style!.fontSize! + 5,
    );
    final runningValueCenterY = tester.getCenter(find.text('2.35')).dy;
    final runningLabelCenterY = tester.getCenter(find.text('累计距离（公里）')).dy;
    final runningTargetCenterY = tester.getCenter(find.text('目标 8.00 公里')).dy;
    expect((runningLabelCenterY - runningValueCenterY).abs(), lessThan(16));
    expect((runningTargetCenterY - runningValueCenterY).abs(), lessThan(16));
    final musicTopAfterStart = tester
        .getTopLeft(find.byType(WorkoutMusicCard))
        .dy;
    expect(musicTopAfterStart, musicTopBeforeStart);

    await tester.tap(find.byType(NeonPauseButton));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<NeonPauseButton>(find.byType(NeonPauseButton))
          .showStartIcon,
      isTrue,
    );
    expect(find.text('开始'), findsOneWidget);
    expect(find.text('长按结束'), findsNothing);
    expect(find.text('继续'), findsNothing);
    expect(find.byIcon(Icons.pause_rounded), findsNothing);
    final pausedDistanceRect = tester.getRect(find.text('2.35'));
    expect(pausedDistanceRect.top, lessThan(runningDistanceRect.top));
    expect(pausedDistanceRect.width, greaterThan(runningDistanceRect.width));
    final musicTopAfterPause = tester
        .getTopLeft(find.byType(WorkoutMusicCard))
        .dy;
    expect(musicTopAfterPause, musicTopBeforeStart);
  });

  testWidgets('music card uses shared bottom tab offset from controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(wrap(const WorkoutTrackingPage()));
    await tester.pump();

    final controlRect = tester.getRect(find.byType(WorkoutControlPanel));
    final musicRect = tester.getRect(find.byType(WorkoutMusicCard));

    expect(
      musicRect.top - controlRect.bottom,
      AppBottomTabBarMetrics.bottomOffset,
    );
  });

  testWidgets('workout tracking page has no first-frame overflow at 375x812', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(wrap(const WorkoutTrackingPage()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(WorkoutMapView), findsOneWidget);
    final mapRect = tester.getRect(find.byType(WorkoutMapView));
    expect(mapRect.left, 0);
    expect(mapRect.width, 375);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
    expect(find.text('累计距离（公里）'), findsOneWidget);
  });
}
