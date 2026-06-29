import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:pedometer/feature/subscription/service/subscription_service.dart';
import 'package:pedometer/feature/subscription/views/onboarding_page.dart';
import 'package:pedometer/products/phone/views/main_page.dart';

class StartupLoadingViewModel extends GetxController {
  Future<void>? _startupFuture;
  bool _completed = false;

  @override
  void onInit() {
    super.onInit();
    _startupFuture = Get.find<SubscriptionService>()
        .runStartupTasks()
        .catchError((_) {});
  }

  Future<void> onLoadingFinished() async {
    if (_completed) return;
    _completed = true;

    try {
      await _startupFuture?.timeout(const Duration(milliseconds: 600));
    } catch (_) {
      // Startup sync keeps running silently; do not hold the first screen.
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      Get.offAllNamed(MainPage.routeName);
      return;
    }

    final service = Get.find<SubscriptionService>();
    final route = service.isVip.value
        ? MainPage.routeName
        : OnboardingPage.routeName;
    Get.offAllNamed(route);
  }
}
