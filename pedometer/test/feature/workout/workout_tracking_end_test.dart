import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_screen.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/feature/workout/components/workout_tracking_components.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';
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

  Widget runningPage() => const WorkoutTrackingPage(
    data: WorkoutTrackingData(
      workoutTitle: WorkoutText.outdoorRun,
      status: WorkoutStatus.running,
      gpsLabel: 'GPS',
      gpsStatus: WorkoutText.trackingGpsGood,
      distanceKm: '2.35',
      targetKm: '8.00',
      duration: '00:18:36',
      calories: '186',
      pace: "07'54''",
      endHint: WorkoutText.trackingEndHint,
      musicTitle: WorkoutText.trackingMusicTitle,
      musicStatus: WorkoutText.trackingMusicStatus,
    ),
  );

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
