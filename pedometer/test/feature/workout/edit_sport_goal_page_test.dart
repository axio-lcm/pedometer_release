import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_screen.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/feature/workout/views/edit_sport_goal_page.dart';

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
      'edit goal page renders without exception at '
      '${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrap(const EditSportGoalPage()));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('编辑运动目标'), findsOneWidget);
        expect(find.text('目标距离'), findsOneWidget);
        expect(find.text('8.00'), findsWidgets); // 左侧当前值 + 右侧调节值
      },
    );
  }

  testWidgets('increase/decrease adjusts distance within bounds', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(wrap(const EditSportGoalPage()));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pump();
    expect(find.text('8.50'), findsWidgets);

    await tester.tap(find.byIcon(Icons.remove_rounded).first);
    await tester.tap(find.byIcon(Icons.remove_rounded).first);
    await tester.pump();
    expect(find.text('7.50'), findsWidgets);
  });

  testWidgets('free-training switch toggles on', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(wrap(const EditSportGoalPage()));
    await tester.pump();

    expect(tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).value,
        isFalse);
    await tester.tap(find.byType(CupertinoSwitch));
    await tester.pump();
    expect(tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).value,
        isTrue);
  });

  testWidgets('restore default resets an adjusted value', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(wrap(const EditSportGoalPage()));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pump();
    expect(find.text('8.50'), findsWidgets);

    // 「恢复默认」位于一屏之下，需先滚动到可见区域再点击。
    await tester.ensureVisible(find.text('恢复默认'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('恢复默认'));
    await tester.pump();
    expect(find.text('8.00'), findsWidgets);
    expect(find.text('8.50'), findsNothing);
  });
}
