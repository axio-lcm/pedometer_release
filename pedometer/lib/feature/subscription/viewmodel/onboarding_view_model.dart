import 'package:get/get.dart';
import 'package:pp_inapp_purchase/inapp_purchase.dart';

import 'package:pedometer/common/config/localized_text.dart';
import 'package:pedometer/feature/subscription/config/subscription_config.dart';
import 'package:pedometer/feature/subscription/model/subscription_assets.dart';
import 'package:pedometer/feature/subscription/service/subscription_service.dart';
import 'package:pedometer/products/phone/views/main_page.dart';

class OnboardingViewModel extends GetxController {
  final index = 0.obs;
  final buttonText = lt('Continue', '继续').obs;
  final productDescription = ''.obs;
  Worker? _vipWorker;
  bool _completed = false;

  static const images = [
    SubscriptionAssets.onboarding1,
    SubscriptionAssets.onboarding2,
    SubscriptionAssets.onboarding3,
    SubscriptionAssets.onboarding4,
  ];

  List<String> get titles => [
    lt('Track every step', '记录每一步'),
    lt('Understand your activity', '了解你的活动'),
    lt('Reach goals daily', '每天达成目标'),
    lt('Unlock Pedometer Pro', '解锁 Pedometer Pro'),
  ];

  List<String> get subtitles => [
    lt(
      'See steps, distance, calories, and active time in one place.',
      '集中查看步数、距离、卡路里和活动时间。',
    ),
    lt(
      'Sync Health data and review daily, weekly, and monthly trends.',
      '同步健康数据，查看日、周、月趋势。',
    ),
    lt(
      'Set workout targets and keep your route history organized.',
      '设置运动目标，保存并管理历史轨迹。',
    ),
    lt(
      r'Start a 3-day free trial, then $9.99/week. Cancel anytime.',
      r'免费试用 3 天，之后每周 $9.99，可随时取消。',
    ),
  ];

  bool get isLast => index.value == images.length - 1;

  @override
  void onInit() {
    super.onInit();
    final service = Get.find<SubscriptionService>();
    _vipWorker = ever<bool>(service.isVip, (isVip) {
      if (isVip) _enterApp();
    });
  }

  @override
  void onReady() {
    super.onReady();
    _loadProductInfo();
  }

  @override
  void onClose() {
    _vipWorker?.dispose();
    super.onClose();
  }

  Future<void> next() async {
    if (!isLast) {
      index.value++;
      if (isLast) await _loadProductInfo();
      return;
    }
    await Get.find<SubscriptionService>().purchase(
      SubscriptionConfig.onboardingWeeklyId,
      SubscriptionSource.onboarding,
    );
    if (Get.find<SubscriptionService>().isVip.value) _enterApp();
  }

  void close() {
    _enterApp();
  }

  Future<void> restore() async {
    await Get.find<SubscriptionService>().restore(
      SubscriptionSource.onboarding,
    );
    if (Get.find<SubscriptionService>().isVip.value) _enterApp();
  }

  Future<void> _loadProductInfo() async {
    final service = Get.find<SubscriptionService>();
    await service.getAllProducts();
    final product = service.productOf(SubscriptionConfig.onboardingWeeklyId);
    final title = await service.titleFor(
      SubscriptionConfig.onboardingWeeklyId,
      SubscriptionPeriodType.week,
    );
    final subtitle = await service.subtitleFor(
      SubscriptionConfig.onboardingWeeklyId,
      SubscriptionPeriodType.week,
    );
    final action = await service.buttonText(
      SubscriptionConfig.onboardingWeeklyId,
    );
    buttonText.value = action.isEmpty ? lt('Continue', '继续') : action;
    productDescription.value = [
      if (title.isNotEmpty) title,
      if (subtitle.isNotEmpty) subtitle,
      if (product?.displayPrice?.isNotEmpty == true)
        product?.displayPrice ?? '',
    ].join(' · ');
  }

  void _enterApp() {
    if (_completed) return;
    _completed = true;
    Get.offAllNamed(MainPage.routeName);
  }
}
