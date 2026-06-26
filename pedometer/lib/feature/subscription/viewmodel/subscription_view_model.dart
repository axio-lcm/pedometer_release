import 'package:get/get.dart';
import 'package:pp_inapp_purchase/inapp_purchase.dart';

import 'package:pedometer/common/config/localized_text.dart';
import 'package:pedometer/feature/subscription/config/subscription_config.dart';
import 'package:pedometer/feature/subscription/service/subscription_service.dart';

class SubscriptionViewModel extends GetxController {
  final selectedIndex = 0.obs;
  final plans = <SubscriptionProductPlan>[
    SubscriptionProductPlan(
      kind: SubscriptionPlanKind.weekly,
      productId: SubscriptionConfig.inAppWeeklyId,
      fallbackTitle: lt('Weekly Plan', '周计划'),
      fallbackSubtitle: lt('3-day free trial', '免费试用 3 天'),
      fallbackPrice: r'$9.99',
    ),
    SubscriptionProductPlan(
      kind: SubscriptionPlanKind.yearly,
      productId: SubscriptionConfig.inAppYearlyId,
      fallbackTitle: lt('Annual Plan', '年度计划'),
      fallbackSubtitle: lt('Best value', '年度会员'),
      fallbackPrice: r'$39.99',
    ),
  ].obs;
  final buttonText = lt('Subscribe', '订阅').obs;
  final isEligibleForIntroOffer = false.obs;
  final weeklyIntroOfferEligible = false.obs;

  SubscriptionSource source = SubscriptionSource.subscription;
  Worker? _vipWorker;
  bool _closed = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is SubscriptionSource) source = args;
    final service = Get.find<SubscriptionService>();
    _vipWorker = ever<bool>(service.isVip, (isVip) {
      if (isVip) _closePage();
    });
  }

  @override
  void onReady() {
    super.onReady();
    _preparePage();
  }

  @override
  void onClose() {
    _vipWorker?.dispose();
    super.onClose();
  }

  Future<void> loadProducts() async {
    final service = Get.find<SubscriptionService>();
    await service.initInAppPurchase();
    final updated = <SubscriptionProductPlan>[];
    for (final plan in plans) {
      final product = service.productOf(plan.productId);
      final period = plan.kind == SubscriptionPlanKind.yearly
          ? SubscriptionPeriodType.year
          : SubscriptionPeriodType.week;
      final title = await service.titleFor(plan.productId, period);
      final subtitle = await service.subtitleFor(plan.productId, period);
      updated.add(
        SubscriptionProductPlan(
          kind: plan.kind,
          productId: plan.productId,
          fallbackTitle: title.isEmpty ? plan.fallbackTitle : title,
          fallbackSubtitle: subtitle.isEmpty ? plan.fallbackSubtitle : subtitle,
          fallbackPrice: product?.displayPrice ?? plan.fallbackPrice,
        ),
      );
    }
    plans.assignAll(updated);
    await _refreshWeeklyIntroOfferEligibility();
    await _refreshSelectedProduct();
  }

  Future<void> _preparePage() async {
    final service = Get.find<SubscriptionService>();
    await service.loadLocalVipStatus();
    if (service.isVip.value && !await service.isTrialCanceled()) {
      _closePage();
      return;
    }
    await loadProducts();
  }

  Future<void> select(int index) async {
    selectedIndex.value = index;
    await _refreshSelectedProduct();
  }

  Future<void> purchase() async {
    final plan = plans[selectedIndex.value];
    await Get.find<SubscriptionService>().purchase(plan.productId, source);
    if (Get.find<SubscriptionService>().isVip.value) _closePage();
  }

  Future<void> restore() async {
    await Get.find<SubscriptionService>().restore(source);
    if (Get.find<SubscriptionService>().isVip.value) _closePage();
  }

  Future<void> _refreshSelectedProduct() async {
    final plan = plans[selectedIndex.value];
    final service = Get.find<SubscriptionService>();
    final eligible = await service.isEligibleForIntroOffer(plan.productId);
    isEligibleForIntroOffer.value = eligible;
    if (plan.kind == SubscriptionPlanKind.weekly) {
      weeklyIntroOfferEligible.value = eligible;
    }
    final text = await service.buttonText(plan.productId);
    buttonText.value = text.isEmpty ? lt('Subscribe', '订阅') : text;
  }

  Future<void> _refreshWeeklyIntroOfferEligibility() async {
    for (final plan in plans) {
      if (plan.kind != SubscriptionPlanKind.weekly) continue;
      weeklyIntroOfferEligible.value = await Get.find<SubscriptionService>()
          .isEligibleForIntroOffer(plan.productId);
      return;
    }
  }

  void _closePage() {
    if (_closed) return;
    _closed = true;
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back(result: true);
    }
  }
}
