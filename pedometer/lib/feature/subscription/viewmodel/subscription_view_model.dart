import 'dart:async';

import 'package:get/get.dart';
import 'package:pp_inapp_purchase/inapp_purchase.dart';

import 'package:pedometer/feature/home/service/health_auto_sync_service.dart';
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
  bool _closed = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is SubscriptionSource) source = args;
    final service = Get.find<SubscriptionService>();
    // 订阅成功（拿到有效会员）即关页，不做试用取消的挽留判断。
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
    // 已是会员则不展示订阅页，直接关闭。
    if (service.isVip.value) {
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
    final service = Get.find<SubscriptionService>();
    await service.purchase(plan.productId, source);
    if (service.isVip.value) _closePage();
  }

  Future<void> restore() async {
    final service = Get.find<SubscriptionService>();
    await service.restore(source);
    if (service.isVip.value) _closePage();
  }

  Future<void> manageSubscriptions() async {
    await Get.find<SubscriptionService>().manageSubscriptions();
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
    buttonText.value = text.isEmpty ? SubscriptionResource.subscribe : text;
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
    // 不可 pop 时（如导航过渡态）先不置位，留待后续会员状态回调重试，避免被永久拦截。
    if (!(Get.key.currentState?.canPop() ?? false)) return;
    _closed = true;
    Get.back(result: true);
    unawaited(_syncHealthDataAfterClose());
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
