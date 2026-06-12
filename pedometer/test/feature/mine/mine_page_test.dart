import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_screen.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/feature/mine/components/mine_components.dart';
import 'package:pedometer/feature/mine/views/mine_page.dart';

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
      'mine page renders without exception at '
      '${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrap(const MinePage()));
        await tester.pump();

        expect(tester.takeException(), isNull);
        // 身体指标四列完整展示。
        expect(find.text('身高'), findsOneWidget);
        expect(find.text('175'), findsOneWidget);
        expect(find.text('体重'), findsOneWidget);
        expect(find.text('68.0'), findsOneWidget);
        expect(find.text('BMI'), findsOneWidget);
        expect(find.text('22.2'), findsOneWidget);
        expect(find.text('正常'), findsOneWidget);
        expect(find.text('年龄'), findsOneWidget);
        expect(find.text('28'), findsOneWidget);
        expect(find.byType(BodyStatItem), findsNWidgets(4));
      },
    );
  }

  testWidgets('settings list shows all entries with version trailing text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(wrap(const MinePage()));
    await tester.pump();

    for (final title in const [
      '主题设置',
      '语言',
      '分享应用',
      '给我们评分',
      '用户协议',
      '隐私政策',
      '关于我们',
      '版本号',
    ]) {
      await tester.scrollUntilVisible(find.text(title), 200);
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('1.0.0'), findsOneWidget);
    expect(find.byType(MineEntryRow), findsNWidgets(8));
    // 版本号行展示文字而非箭头：箭头数 = 行数 - 1。
    expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(7));
  });
}
