import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/feature/home/components/sync_data_detail_components.dart';
import 'package:pedometer/feature/home/resources/home_resource.dart';
import 'package:pedometer/products/init/app.dart';

/// 多档屏宽下首页（含右侧 KPI 与主圆环）均不应溢出。
void main() {
  for (final size in const [
    Size(320, 568), // iPhone SE / 小屏
    Size(360, 740), // 常见安卓
    Size(375, 812), // iPhone 标准
  ]) {
    testWidgets('no overflow at ${size.width.toInt()}x${size.height.toInt()}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      ResourceLoader.loadForTest(
        colors: {'common': {}, 'home': {}, 'phone': {}},
        strings: {'common': {}, 'home': {}, 'phone': {}},
      );
      addTearDown(Get.reset);
      await tester.pumpWidget(const PedometerApp());
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('5,276'), findsOneWidget);
    });
  }

  testWidgets('sync detail has no first-frame overflow at 375x812', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    ResourceLoader.loadForTest(
      colors: {'common': {}, 'home': {}, 'phone': {}},
      strings: {'common': {}, 'home': {}, 'phone': {}},
    );
    addTearDown(Get.reset);

    await tester.pumpWidget(const PedometerApp());
    await tester.pump();
    await tester.tap(find.text(HomeResource.entryHealthSync));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('同步成功'), findsOneWidget);
    expect(find.text('同步历史'), findsOneWidget);
  });

  testWidgets('sync history detail has no first-frame overflow at 375x812', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    ResourceLoader.loadForTest(
      colors: {'common': {}, 'home': {}, 'phone': {}},
      strings: {'common': {}, 'home': {}, 'phone': {}},
    );
    addTearDown(Get.reset);

    await tester.pumpWidget(const PedometerApp());
    await tester.pump();
    await tester.tap(find.text(HomeResource.entryHealthSync));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('今天 09:41'), 260);
    await tester.pumpAndSettle();
    await tester.tap(find.text('今天 09:41'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('同步历史详情'), findsOneWidget);
    expect(find.text('本次同步数据'), findsOneWidget);
  });

  testWidgets('sync source detail has no first-frame overflow at 375x812', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    ResourceLoader.loadForTest(
      colors: {'common': {}, 'home': {}, 'phone': {}},
      strings: {'common': {}, 'home': {}, 'phone': {}},
    );
    addTearDown(Get.reset);

    await tester.pumpWidget(const PedometerApp());
    await tester.pump();
    await tester.tap(find.text(HomeResource.entryHealthSync));
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看').first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Health 同步权限'), findsOneWidget);
    expect(find.text('同步方式'), findsOneWidget);
    final sourceIcon = tester.widget<SyncSourceIcon>(
      find.byType(SyncSourceIcon),
    );
    expect(sourceIcon.size, lessThanOrEqualTo(64));
    final connectionTitle = tester.widget<Text>(
      find.text('已连接 Apple Health'),
    );
    expect(connectionTitle.style?.fontSize, lessThanOrEqualTo(20));
  });
}
