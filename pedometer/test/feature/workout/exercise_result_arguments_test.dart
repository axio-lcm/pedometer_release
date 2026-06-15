import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_screen.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';
import 'package:pedometer/feature/workout/views/exercise_result_page.dart';

void main() {
  setUp(() {
    ResourceLoader.loadForTest(
      colors: {'common': {}, 'home': {}, 'phone': {}},
      strings: {'common': {}, 'home': {}, 'phone': {}},
    );
  });

  tearDown(Get.reset);

  testWidgets('uses ExerciseResultData from Get.arguments over the default mock',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    const real = ExerciseResultData(
      sportType: '户外跑步',
      dateText: '今天',
      distance: '3.33',
      distanceUnit: '公里',
      metrics: [],
    );

    await tester.pumpWidget(
      AppScreenAdapter(
        builder: (_) => GetMaterialApp(
          locale: const Locale('zh', 'CN'),
          home: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();

    // 通过 Get.arguments 进入结果页（模拟运动结束跳转）。
    Get.to(() => const ExerciseResultPage(), arguments: real);
    await tester.pump(); // 构建页面
    await tester.pump(); // 渲染一帧（不用 pumpAndSettle：礼花动画含计时器）

    expect(find.text('3.33'), findsOneWidget); // 真实距离
    expect(find.text('2.35'), findsNothing); // 不再用 mock 距离
  });
}
