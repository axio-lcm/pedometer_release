import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_screen.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/feature/workout/components/workout_components.dart';
import 'package:pedometer/feature/workout/views/workout_page.dart';

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

  for (final size in const [
    Size(320, 568), // 小屏
    Size(360, 740), // 常见安卓
    Size(375, 812), // iPhone 标准
  ]) {
    testWidgets(
      'workout page renders without exception at '
      '${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrap(const WorkoutPage()));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('准备开始今天的训练'), findsOneWidget);
        expect(find.text('运动目标与成就'), findsOneWidget);
      },
    );
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
}
