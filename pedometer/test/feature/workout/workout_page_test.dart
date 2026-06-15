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
    // 指标由控制器提供（初始值），不再使用 widget.data 静态 mock 值。
    expect(find.text('0.00'), findsWidgets); // 距离初始值
    expect(find.text('目标 8.00 公里'), findsOneWidget);
    expect(find.text('00:00:00'), findsOneWidget); // 时长初始值
    expect(find.text('0'), findsWidgets); // 卡路里初始值
    expect(find.text("--'--''"), findsOneWidget); // 配速初始值
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
    // 指标由控制器提供，初始距离为 '0.00'。容器 rect 用于位置对比；距离数值文本
    // 用 overlay 内 descendant 定位，避免 '0.00' 在多个子组件中出现造成 finder 歧义。
    final readyOverlayRect = tester.getRect(find.byType(WorkoutDistanceOverlay));
    final overlayDistanceValue = find.descendant(
      of: find.byType(WorkoutDistanceOverlay),
      matching: find.text('0.00'),
    );
    final readyValueRect = tester.getRect(overlayDistanceValue);
    final readyLabelCenterY = tester.getCenter(find.text('累计距离（公里）')).dy;
    final readyTargetCenterY = tester.getCenter(find.text('目标 8.00 公里')).dy;
    expect((readyTargetCenterY - readyLabelCenterY).abs(), greaterThan(40));
    final musicTopBeforeStart = tester
        .getTopLeft(find.byType(WorkoutMusicCard))
        .dy;

    // 点击 → togglePrimary() → start() → 启动 periodic 计时器。
    // 先 pump() 处理点击（状态变 running、Obx 重建、隐式动画起步），
    // 再 pump(250ms) 把 AnimatedPositioned 动画推进过 220ms。不用 pumpAndSettle()
    // （periodic timer 永不 settle）。
    await tester.tap(find.byType(NeonPauseButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      tester
          .widget<NeonPauseButton>(find.byType(NeonPauseButton))
          .showStartIcon,
      isFalse,
    );
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(find.text('开始'), findsNothing);
    expect(find.text('长按结束'), findsOneWidget);
    // running 时 overlay 移到地图底部（AnimatedPositioned top: 360），Y 大于 ready。
    final runningOverlayRect = tester.getRect(
      find.byType(WorkoutDistanceOverlay),
    );
    expect(runningOverlayRect.top, greaterThan(readyOverlayRect.top));
    expect(runningOverlayRect.top, greaterThan(400));
    final metricPanelRect = tester.getRect(find.byType(WorkoutMetricPanel));
    expect(metricPanelRect.top - runningOverlayRect.bottom, greaterThan(0));
    expect(
      metricPanelRect.top - runningOverlayRect.bottom,
      lessThanOrEqualTo(24),
    );
    // compact 数值字号(25)远小于 ready 英雄数字(78)，故数值文本变窄。
    final runningValueRect = tester.getRect(overlayDistanceValue);
    expect(runningValueRect.width, lessThan(readyValueRect.width));
    // 验证 compact overlay 内 label / target / value 字号紧凑关系。
    final runningLabelText = tester.widget<Text>(find.text('累计距离（公里）'));
    final runningTargetText = tester.widget<Text>(find.text('目标 8.00 公里'));
    final runningValueText = tester.widget<Text>(overlayDistanceValue);
    expect(
      runningValueText.style?.fontSize,
      runningLabelText.style!.fontSize! + 10,
    );
    expect(
      runningValueText.style?.fontSize,
      runningTargetText.style!.fontSize! + 10,
    );
    final runningValueCenterY = tester.getCenter(overlayDistanceValue).dy;
    final runningLabelCenterY = tester.getCenter(find.text('累计距离（公里）')).dy;
    final runningTargetCenterY = tester.getCenter(find.text('目标 8.00 公里')).dy;
    expect((runningLabelCenterY - runningValueCenterY).abs(), lessThan(16));
    expect((runningTargetCenterY - runningValueCenterY).abs(), lessThan(16));
    final musicTopAfterStart = tester
        .getTopLeft(find.byType(WorkoutMusicCard))
        .dy;
    expect(musicTopAfterStart, musicTopBeforeStart);

    // 第二次点击 → pause() → 停止计时器；先 pump() 处理状态变更，再推进动画。
    await tester.tap(find.byType(NeonPauseButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      tester
          .widget<NeonPauseButton>(find.byType(NeonPauseButton))
          .showStartIcon,
      isTrue,
    );
    // paused 态（修正后的状态机：running→paused，而非旧 bug 的 running→ready）：
    // 按钮恢复开始图标，但仍显示「长按结束」提示（暂停时可长按结束）。
    expect(find.text('开始'), findsNothing);
    expect(find.text('长按结束'), findsOneWidget);
    expect(find.text('继续'), findsNothing);
    expect(find.byIcon(Icons.pause_rounded), findsNothing);
    // paused 时 overlay 回到与 ready 相同的上方位置。
    final pausedOverlayRect = tester.getRect(
      find.byType(WorkoutDistanceOverlay),
    );
    expect(pausedOverlayRect.top, lessThan(runningOverlayRect.top));
    // paused 回到 ready 布局：数值恢复英雄字号，文本宽度大于 running 紧凑态。
    final pausedValueRect = tester.getRect(overlayDistanceValue);
    expect(pausedValueRect.width, greaterThan(runningValueRect.width));
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
    expect(find.byKey(const Key('workout-google-map')), findsOneWidget);
    // 定位状态徽标已移除。
    expect(find.byKey(const Key('workout-location-status')), findsNothing);
    expect(find.byType(RoutePolylineLayer), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_MapDarkOverlay',
      ),
      findsNothing,
    );
    expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsNothing);
    expect(find.byIcon(Icons.remove_rounded), findsNothing);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
    expect(find.text('累计距离（公里）'), findsOneWidget);
  });
}
