import 'dart:async';

import 'package:get/get.dart';
import 'package:pp_inapp_purchase/inapp_purchase.dart';

import 'package:pedometer/common/storage/language_service.dart';
import 'package:pedometer/feature/home/service/health_auto_sync_service.dart';
import 'package:pedometer/feature/subscription/components/purchase_loading.dart';
import 'package:pedometer/feature/subscription/config/subscription_config.dart';
import 'package:pedometer/feature/subscription/resources/subscription_resource.dart';
import 'package:pedometer/feature/subscription/service/subscription_service.dart';

class SubscriptionViewModel extends GetxController {
  final selectedIndex = 0.obs;
  final plans = <SubscriptionProductPlan>[
    SubscriptionProductPlan(
      kind: SubscriptionPlanKind.weekly,
      productId: SubscriptionConfig.inAppWeeklyId,
      fallbackTitle: SubscriptionResource.weeklyPlan,
      fallbackSubtitle: SubscriptionResource.weeklyTrialSubtitle,
      fallbackPrice: r'$9.99',
    ),
    SubscriptionProductPlan(
      kind: SubscriptionPlanKind.yearly,
      productId: SubscriptionConfig.inAppYearlyId,
      fallbackTitle: SubscriptionResource.annualPlan,
      fallbackSubtitle: SubscriptionResource.annualBestValue,
      fallbackPrice: r'$39.99',
    ),
  ].obs;
  final buttonText = SubscriptionResource.subscribe.obs;
  final isEligibleForIntroOffer = false.obs;
  final weeklyIntroOfferEligible = false.obs;

  SubscriptionSource source = SubscriptionSource.subscription;
  Worker? _vipWorker;
  Worker? _trialCanceledWorker;
  Worker? _languageWorker;
  bool _closed = false;
  bool _closing = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is SubscriptionSource) source = args;
    final service = Get.find<SubscriptionService>();
    // 订阅成功且不是“试用期内取消续订”状态时才关页。
    _vipWorker = ever<bool>(service.isVip, (isVip) {
      if (isVip && !service.isTrialCanceled.value) unawaited(_closePage());
    });
    _trialCanceledWorker = ever<bool>(service.isTrialCanceled, (isCanceled) {
      if (!isCanceled && service.isVip.value) unawaited(_closePage());
    });
    if (Get.isRegistered<LanguageService>()) {
      _languageWorker = ever<int>(
        Get.find<LanguageService>().localeRevision,
        (_) => unawaited(_refreshLocalizedText()),
      );
    }
  }

  @override
  void onReady() {
    super.onReady();
    _preparePage();
  }

  @override
  void onClose() {
    _vipWorker?.dispose();
    _trialCanceledWorker?.dispose();
    _languageWorker?.dispose();
    super.onClose();
  }

  Future<void> _refreshLocalizedText() async {
    plans.assignAll([
      for (final plan in plans)
        SubscriptionProductPlan(
          kind: plan.kind,
          productId: plan.productId,
          fallbackTitle: plan.kind == SubscriptionPlanKind.yearly
              ? SubscriptionResource.annualPlan
              : SubscriptionResource.weeklyPlan,
          fallbackSubtitle: plan.kind == SubscriptionPlanKind.yearly
              ? SubscriptionResource.annualBestValue
              : SubscriptionResource.weeklyTrialSubtitle,
          fallbackPrice: plan.fallbackPrice,
        ),
    ]);
    await _refreshSelectedProduct();
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
    // 正常会员不展示订阅页；试用期内已取消续订的会员需要展示非首订页。
    if (service.isVip.value && !service.isTrialCanceled.value) {
      await _closePage();
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
    final service = Get.find<SubscriptionService>();
    await service.purchase(plan.productId, source);
    if (service.isVip.value && !service.isTrialCanceled.value) {
      await _closePage();
    }
  }

  Future<void> restore() async {
    final service = Get.find<SubscriptionService>();
    await service.restore(source);
    if (service.isVip.value && !service.isTrialCanceled.value) {
      await _closePage();
    }
  }

  Future<void> manageSubscriptions() async {
    await Get.find<SubscriptionService>().manageSubscriptions();
  }

  Future<void> _refreshSelectedProduct() async {
    final plan = plans[selectedIndex.value];
    final service = Get.find<SubscriptionService>();
    final forceNonIntroOffer =
        service.isVip.value && service.isTrialCanceled.value;
    final eligible = forceNonIntroOffer
        ? false
        : await service.isEligibleForIntroOffer(plan.productId);
    isEligibleForIntroOffer.value = eligible;
    if (plan.kind == SubscriptionPlanKind.weekly) {
      weeklyIntroOfferEligible.value = eligible;
    }
    if (forceNonIntroOffer) {
      buttonText.value = SubscriptionResource.subscribe;
      return;
    }
    final text = await service.buttonText(plan.productId);
    buttonText.value = text.isEmpty ? SubscriptionResource.subscribe : text;
  }

  Future<void> _refreshWeeklyIntroOfferEligibility() async {
    final service = Get.find<SubscriptionService>();
    if (service.isVip.value && service.isTrialCanceled.value) {
      weeklyIntroOfferEligible.value = false;
      return;
    }
    for (final plan in plans) {
      if (plan.kind != SubscriptionPlanKind.weekly) continue;
      weeklyIntroOfferEligible.value = await service.isEligibleForIntroOffer(
        plan.productId,
      );
      return;
    }
  }

  Future<void> _closePage() async {
    if (_closed || _closing) return;
    _closing = true;
    try {
      await PurchaseLoading.dismiss();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      // 不可 pop 时（如导航过渡态）先不置位，留待后续会员状态回调重试，避免被永久拦截。
      if (!(Get.key.currentState?.canPop() ?? false)) return;
      _closed = true;
      Get.back(result: true);
      unawaited(_syncHealthDataAfterClose());
    } finally {
      if (!_closed) _closing = false;
    }
  }

  Future<void> _syncHealthDataAfterClose() async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!Get.isRegistered<SubscriptionService>() ||
        !Get.find<SubscriptionService>().isVip.value ||
        !Get.isRegistered<HealthAutoSyncService>()) {
      return;
    }
    await Get.find<HealthAutoSyncService>().syncMemberHealthData();
  }
}
