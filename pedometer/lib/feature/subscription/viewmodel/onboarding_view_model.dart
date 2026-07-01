import 'dart:async';

import 'package:get/get.dart';

import 'package:pedometer/common/config/localized_text.dart';
import 'package:pedometer/common/storage/language_service.dart';
import 'package:pedometer/feature/subscription/config/subscription_config.dart';
import 'package:pedometer/feature/subscription/model/subscription_assets.dart';
import 'package:pedometer/feature/subscription/resources/subscription_resource.dart';
import 'package:pedometer/feature/subscription/service/subscription_service.dart';
import 'package:pedometer/products/phone/views/main_page.dart';

class OnboardingViewModel extends GetxController {
  static const int guidePageCount = 3;

  final index = 0.obs;
  final buttonText = lt('Continue', '继续').obs;
  final productDescription = ''.obs;
  final productPrice = r'$9.99'.obs;
  final isEligibleForIntroOffer = false.obs;
  final introOfferDays = SubscriptionResource.defaultIntroOfferDays.obs;
  final showFreeTrialSwitchIntro = false.obs;
  Worker? _vipWorker;
  Worker? _languageWorker;
  bool _completed = false;
  bool _trialSwitchIntroShown = false;
  bool _showSubscriptionAfterIntro = false;

  static const images = [
    SubscriptionAssets.onboarding1,
    SubscriptionAssets.onboarding2,
    SubscriptionAssets.onboarding3,
  ];

  // 标题用 `*` 包裹需绿色高亮的关键词，[_GuideTitle] 解析后渲染。
  List<String> get titles => [
    lt('Make Every *Step* Count', '让每一*步*都有意义'),
    lt('Stay *Motivated*', '保持*动力*'),
    lt('Sync with *Health*', '*同步*健康数据'),
    lt('Unlock *Pedometer Pro*', '解锁 *Pedometer Pro*'),
  ];

  List<String> get subtitles => [
    lt(
      'Track daily steps, distance, and calories in one clear view.',
      '清晰查看每日步数、距离和卡路里。',
    ),
    lt(
      'Set goals, close, and earn achievement badges every day.',
      '设定目标，每天收获成就徽章。',
    ),
    lt(
      'Keep steps and workouts connected with your health data in seconds.',
      '快速连接步数、运动和健康数据。',
    ),
  ];

  bool get _isMember => Get.find<SubscriptionService>().isVip.value;

  static const int _subscriptionPageIndex = guidePageCount;

  /// 订阅页（最后一页）只对非会员展示；会员只走引导页，不展示订阅页。
  bool get isLast => !_isMember && index.value == _subscriptionPageIndex;

  bool get isGuidePage => index.value < guidePageCount;

  /// 引导阶段最大可翻页索引：
  /// - 会员到倒数第二页（跳过订阅页）；
  /// - 非会员到最后一页（订阅页）。
  int get _maxIndex => _isMember ? guidePageCount - 1 : _subscriptionPageIndex;

  @override
  void onInit() {
    super.onInit();
    final service = Get.find<SubscriptionService>();
    _vipWorker = ever<bool>(service.isVip, (isVip) {
      if (isVip) _enterApp();
    });
    if (Get.isRegistered<LanguageService>()) {
      _languageWorker = ever<int>(
        Get.find<LanguageService>().localeRevision,
        (_) => _refreshLocalizedProductText(),
      );
    }
  }

  @override
  void onReady() {
    super.onReady();
    // 会员不展示订阅页，无需加载订阅产品信息。
    if (!_isMember) _loadProductInfo();
  }

  @override
  void onClose() {
    _vipWorker?.dispose();
    _languageWorker?.dispose();
    super.onClose();
  }

  Future<void> next() async {
    // 引导阶段未到末页：先翻页，绝不在翻页前 await StoreKit 网络请求，
    // 否则商品查询慢或挂起会导致翻页卡顿甚至跳不过去。
    if (index.value < _maxIndex) {
      final nextIndex = index.value + 1;
      if (!_isMember && nextIndex == _subscriptionPageIndex) {
        // onReady 已预载产品信息：若资格已就绪且符合条件，沿用原交互——
        // 先弹试用切换说明，关闭后再进订阅页（hideFreeTrialSwitchIntro 负责跳转）。
        if (isEligibleForIntroOffer.value && !_trialSwitchIntroShown) {
          _trialSwitchIntroShown = true;
          _showSubscriptionAfterIntro = true;
          showFreeTrialSwitchIntro.value = true;
          return;
        }
        // 资格尚未就绪也不阻塞：直接进订阅页；产品信息与（如符合）试用弹窗
        // 由 _loadProductInfo 就绪后通过响应式变量异步补齐。
        unawaited(_loadProductInfo());
      }
      index.value = nextIndex;
      return;
    }
    // 会员：走完引导直接进首页，不展示订阅页。
    if (_isMember) {
      _enterApp();
      return;
    }
    // 非会员：在订阅页发起购买，成功后进首页（isVip 变更也会经 worker 触发跳转）。
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

  Future<void> manageSubscriptions() async {
    await Get.find<SubscriptionService>().manageSubscriptions();
  }

  Future<void> _loadProductInfo() async {
    final service = Get.find<SubscriptionService>();
    // 初始化内购并确保商品真正加载（空时会重试），与订阅页保持一致，
    // 避免未配置 / TestFlight 首拉为空时读到空商品退回 fallback 价。
    await service.ensureProductsLoaded();
    final product = service.productOf(SubscriptionConfig.onboardingWeeklyId);
    final eligible = await service.isEligibleForIntroOffer(
      SubscriptionConfig.onboardingWeeklyId,
    );
    final action = await service.buttonText(
      SubscriptionConfig.onboardingWeeklyId,
    );
    isEligibleForIntroOffer.value = eligible;
    introOfferDays.value = service.introOfferDaysFor(
      SubscriptionConfig.onboardingWeeklyId,
    );
    buttonText.value = action.isEmpty ? lt('Continue', '继续') : action;
    final price = product?.displayPrice?.isNotEmpty == true
        ? product!.displayPrice!
        : r'$9.99';
    productPrice.value = price;
    _refreshLocalizedProductText();
    if (isLast && eligible && !_trialSwitchIntroShown) {
      _trialSwitchIntroShown = true;
      showFreeTrialSwitchIntro.value = true;
    }
  }

  void _refreshLocalizedProductText() {
    final price = productPrice.value;
    productDescription.value = isEligibleForIntroOffer.value
        ? SubscriptionResource.introOfferDescription(
            price,
            trialDays: introOfferDays.value,
          )
        : lt(
            'Subscribe to unlock goals, rewards, route tracking, health sync, and training insights. Weekly $price. Cancel anytime.',
            '订阅即可解锁目标、奖励、路线记录、健康同步和训练洞察。每周 $price，可随时取消。',
          );
  }

  void hideFreeTrialSwitchIntro() {
    showFreeTrialSwitchIntro.value = false;
    if (_showSubscriptionAfterIntro) {
      _showSubscriptionAfterIntro = false;
      index.value = _subscriptionPageIndex;
    }
  }

  void _enterApp() {
    if (_completed) return;
    _completed = true;
    Get.offAllNamed(MainPage.routeName);
  }
}
