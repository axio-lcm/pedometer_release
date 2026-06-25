import 'dart:async';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pedometer/common/config/prefs_keys.dart';
import 'package:pedometer/feature/subscription/api/subscription_upload_api.dart';
import 'package:pedometer/feature/subscription/service/subscription_service.dart';
import 'package:pedometer/products/phone/views/main_page.dart';
import 'package:pedometer/feature/subscription/views/onboarding_page.dart';

class StartLoadViewModel extends GetxController {
  final progress = 0.0.obs;
  final statusText = 'Loading...'.obs;

  Timer? _progressTimer;
  double _targetProgress = 0;
  double _currentProgress = 0;
  bool _completed = false;

  @override
  void onReady() {
    super.onReady();
    unawaited(start());
  }

  @override
  void onClose() {
    _progressTimer?.cancel();
    super.onClose();
  }

  Future<void> start() async {
    if (_completed) return;
    _startSmoothProgress();
    try {
      statusText.value = 'Loading products...';
      await _runPhase(35, () async {
        await Get.find<SubscriptionService>().initInAppPurchase();
      });

      statusText.value = 'Preparing data...';
      await _runPhase(65, () async {
        await SubscriptionUploadApi.saveAttributionJson();
        unawaited(SubscriptionUploadApi.uploadAttributionRegister());
      });

      statusText.value = 'Checking membership...';
      await _runPhase(90, () async {
        await Get.find<SubscriptionService>().loadLocalVipStatus();
      });
    } finally {
      _complete();
    }
  }

  Future<void> _runPhase(double target, Future<void> Function() task) async {
    _targetProgress = target;
    await task().timeout(const Duration(seconds: 8), onTimeout: () {});
  }

  void _startSmoothProgress() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 25), (_) {
      if (_currentProgress >= _targetProgress) return;
      _currentProgress += (_targetProgress - _currentProgress) * 0.12;
      progress.value = _currentProgress.clamp(0, 100);
    });
  }

  Future<void> _complete() async {
    if (_completed) return;
    _completed = true;
    _targetProgress = 100;
    progress.value = 100;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final service = Get.find<SubscriptionService>();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.isShowedSubOnThisSession, false);
    await prefs.setBool(PrefsKeys.isFirstLaunch, false);
    if (service.isVip.value) {
      Get.offAllNamed(MainPage.routeName);
    } else {
      Get.offAllNamed(OnboardingPage.routeName);
    }
  }
}
