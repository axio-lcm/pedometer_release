import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_screen.dart';
import 'package:pedometer/common/config/prefs_keys.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/feature/subscription/components/purchase_loading.dart';
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

  testWidgets('purchase loading dismiss without dialog does not pop route', (
    tester,
  ) async {
    await tester.pumpWidget(
      AppScreenAdapter(
        builder: (_) =>
            const GetMaterialApp(home: Scaffold(body: Text('root'))),
      ),
    );
    Get.to<void>(() => const Scaffold(body: Text('subscription route')));
    await tester.pumpAndSettle();

    PurchaseLoading.dismiss();
    await tester.pumpAndSettle();

    expect(find.text('subscription route'), findsOneWidget);
    expect(find.text('root'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cancelled trial member purchase return keeps subscription page',
    (tester) async {
      Get.reset();
      Get.testMode = true;
      SharedPreferences.setMockInitialValues({
        PrefsKeys.isVip: true,
        PrefsKeys.isTrialCanceled: true,
        PrefsKeys.vipExpireTime: DateTime.now()
            .add(const Duration(days: 3))
            .millisecondsSinceEpoch,
      });
      final service = SubscriptionService();
      await service.init();
      Get.put<SubscriptionService>(service);
      Get.put(SubscriptionViewModel());

      await tester.pumpWidget(
        AppScreenAdapter(
          builder: (_) =>
              const GetMaterialApp(home: Scaffold(body: Text('root'))),
        ),
      );
      Get.to<void>(() => const SubscriptionPage());
      await tester.pumpAndSettle();

      await Get.find<SubscriptionViewModel>().purchase();
      await tester.pumpAndSettle();

      expect(find.byType(SubscriptionPage), findsOneWidget);
      expect(find.text('root'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
