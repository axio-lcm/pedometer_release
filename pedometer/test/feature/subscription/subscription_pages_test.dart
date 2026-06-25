import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_screen.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/feature/subscription/service/subscription_service.dart';
import 'package:pedometer/feature/subscription/viewmodel/onboarding_view_model.dart';
import 'package:pedometer/feature/subscription/viewmodel/subscription_view_model.dart';
import 'package:pedometer/feature/subscription/views/onboarding_page.dart';
import 'package:pedometer/feature/subscription/views/subscription_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    await ResourceLoader.init(languageCode: 'en');
    final service = SubscriptionService();
    await service.init();
    Get.put<SubscriptionService>(service);
  });

  tearDown(Get.reset);

  testWidgets('onboarding page renders on compact iPhone size', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Get.put(OnboardingViewModel());
    await tester.pumpWidget(
      AppScreenAdapter(
        builder: (_) => const GetMaterialApp(home: OnboardingPage()),
      ),
    );
    await tester.pump();

    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('subscription page renders on compact iPhone size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Get.put(SubscriptionViewModel());
    await tester.pumpWidget(
      AppScreenAdapter(
        builder: (_) => const GetMaterialApp(home: SubscriptionPage()),
      ),
    );
    await tester.pump();

    expect(find.byType(SubscriptionPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
