import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_screen.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/feature/workout/components/workout_tracking_components.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';
import 'package:pedometer/feature/workout/viewmodel/workout_tracking_controller.dart';
import 'package:pedometer/feature/workout/views/exercise_result_page.dart';
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
            name: WorkoutRouteTable.pathResult,
            page: () => const ExerciseResultPage(),
          ),
        ],
      ),
    );
  }

  Widget runningPage() {
    // 控制器接管状态后，widget.data 的 status / 指标字段由控制器覆写；
    // 测试需要控制器预置 running 状态，页面才能渲染「长按结束」按钮。
    final ctrl = Get.put(WorkoutTrackingController());
    ctrl.status.value = WorkoutStatus.running;
    return const WorkoutTrackingPage();
  }

  testWidgets('holding the main button for 3s ends and opens result page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(wrap(runningPage()));
    await tester.pump();
    expect(find.text('长按结束'), findsOneWidget);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(NeonPauseButton)),
    );
    await tester.pump(); // 派发 pointer down
    await tester.pump(const Duration(milliseconds: 120)); // 触发 onTapDown → 开始蓄力
    await tester.pumpAndSettle(); // 推进 3 秒蓄力动画至完成（按住期间）
    await gesture.up();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(Get.currentRoute, ExerciseResultPage.routeName);
    expect(find.text('运动完成！'), findsOneWidget);
  });

  testWidgets('a short press does not end the workout', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(wrap(runningPage()));
    await tester.pump();

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(NeonPauseButton)),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(Get.currentRoute, isNot(ExerciseResultPage.routeName));
    expect(find.text('运动完成！'), findsNothing);
  });
}
