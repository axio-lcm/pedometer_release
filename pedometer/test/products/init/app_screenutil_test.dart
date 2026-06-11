import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_screen.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/products/init/app.dart';

void main() {
  testWidgets('initializes flutter_screenutil with 375x812 design size', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(Get.reset);

    ResourceLoader.loadForTest(
      colors: {'common': {}, 'home': {}, 'phone': {}},
      strings: {'common': {}, 'home': {}, 'phone': {}},
    );

    await tester.pumpWidget(const PedometerApp());
    await tester.pump();

    expect(AppScreenDesign.size, const Size(375, 812));
    expect(ScreenUtil().scaleWidth, moreOrLessEquals(390 / 375));
    expect(ScreenUtil().scaleHeight, moreOrLessEquals(844 / 812));
  });
}
