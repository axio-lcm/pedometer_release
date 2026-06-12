import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_screen.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/feature/workout/components/exercise_result_components.dart';
import 'package:pedometer/feature/workout/views/exercise_result_page.dart';

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
    Size(320, 568),
    Size(360, 740),
    Size(375, 812),
  ]) {
    testWidgets(
      'result page renders without exception at '
      '${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrap(const ExerciseResultPage()));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('运动完成！'), findsOneWidget);
        expect(find.text('2.35'), findsOneWidget);
        expect(find.text('00:18:36'), findsOneWidget);
        expect(find.text('186'), findsOneWidget);
        expect(find.text('3,256'), findsOneWidget);
        expect(find.text('累计爬升 (m)'), findsOneWidget);
        expect(find.byType(ResultMetricItem), findsNWidgets(6));
        expect(find.text('完成'), findsOneWidget);
        expect(find.text('分享'), findsOneWidget);
      },
    );
  }
}
