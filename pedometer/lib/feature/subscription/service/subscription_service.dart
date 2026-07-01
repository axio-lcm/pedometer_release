import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:pp_inapp_purchase/inapp_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pedometer/common/config/localized_text.dart';
import 'package:pedometer/common/config/prefs_keys.dart';
import 'package:pedometer/feature/subscription/api/subscription_upload_api.dart';
import 'package:pedometer/feature/subscription/components/purchase_loading.dart';
import 'package:pedometer/feature/subscription/config/subscription_config.dart';
import 'package:pedometer/feature/subscription/resources/subscription_resource.dart';
import 'package:pedometer/feature/subscription/views/subscription_page.dart';

class SubscriptionService extends GetxService with WidgetsBindingObserver {
  final InappPurchase _purchaser = InappPurchase.instance;

  final RxBool isVip = false.obs;
  final RxBool isTrialCanceled = false.obs;
  final RxBool isInitialized = false.obs;
  final RxList<Product> products = <Product>[].obs;
  final RxMap<String, int> introOfferDaysByProductId = <String, int>{}.obs;

  /// 商品是否已从 StoreKit 真正加载（非空）。为 false 时页面价格 / 试用不可信，
  /// 不应展示可购买的 CTA（TestFlight 生产目录未就绪时会出现）。
  final RxBool productsLoaded = false.obs;

  /// 是否首订（true=首订，可享试用）。综合「交易历史 + StoreKit 资格」判断，
  /// 每次 [syncSubscriptionStatus]（refreshPurchases 之后）刷新，避免仅凭单一
  /// 原生资格标志在 TestFlight/沙盒下误判。
  final RxBool isFirstPurchase = true.obs;

  StreamSubscription<Map<String, dynamic>>? _stateSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _productsSubscription;
  StreamSubscription<Map<String, dynamic>>? _transactionsSubscription;

  bool _isInitializing = false;
  bool _isSyncing = false;
  bool _didInitialSync = false;
  Future<void>? _initFuture;
  SubscriptionSource _source = SubscriptionSource.startLoading;

  Future<SubscriptionService> init() async {
    await loadLocalVipStatus();
    return this;
  }

  @override
  void onInit() {
    super.onInit();
    if (Platform.isIOS) WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 回到前台复检会员状态：订阅可能在后台过期/变更（对齐分贝 checkVip on foreground）。
    if (state == AppLifecycleState.resumed &&
        Platform.isIOS &&
        isInitialized.value) {
      unawaited(syncSubscriptionStatus());
    }
  }

  bool get _isAndroidVipMode => Platform.isAndroid;

  // 启动编排唯一入口为 StartupLoadingViewModel：串行执行会话准备 / 归因准备 /
  // 本地会员检查，StoreKit 初始化、商品预热和远端会员同步按分贝模式后台执行。
  // 原 runStartupTasks() 与其重复且无调用者，已删除以避免两处启动顺序漂移。

  /// 启动页阶段 1：恢复本地会员缓存，并重置本会话订阅页展示标记。
  Future<void> prepareStartupSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.isShowedSubOnThisSession, false);
    if (_isAndroidVipMode) {
      isVip.value = true;
      isTrialCanceled.value = false;
      isInitialized.value = true;
      await markStartupFinished();
      return;
    }
    await loadLocalVipStatus();
  }

  /// 启动页阶段 2：预热商品和首订资格查询，给引导页/订阅页准备 StoreKit 数据。
  Future<void> prewarmStartupProducts() async {
    if (!Platform.isIOS) return;
    await getAllProducts();
    // 交易历史已由 initInAppPurchase 内的 syncSubscriptionStatus 刷新，
    // 这里直接综合判断首订并缓存，供引导页/订阅页读取。
    await checkIsFirstPurchase();
  }

  /// 启动页阶段 3：准备归因数据；不包含埋点事件。
  Future<void> prepareStartupAttribution() async {
    if (!Platform.isIOS) return;
    await SubscriptionUploadApi.saveAttributionJson();
    unawaited(SubscriptionUploadApi.uploadAttributionRegister());
  }

  /// 启动页阶段 4：刷新 StoreKit 交易与本地会员状态。
  Future<void> refreshStartupMembership() async {
    if (_isAndroidVipMode) {
      await loadLocalVipStatus();
      return;
    }
    await syncSubscriptionStatus();
    await loadLocalVipStatus();
  }

  Future<void> markStartupFinished() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.isFirstLaunch, false);
  }

  Future<void> loadLocalVipStatus() async {
    if (_isAndroidVipMode) {
      isVip.value = true;
      isTrialCanceled.value = false;
      isInitialized.value = true;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final savedVip = prefs.getBool(PrefsKeys.isVip) ?? false;
    final expireTime = prefs.getInt(PrefsKeys.vipExpireTime) ?? 0;
    final active =
        savedVip && expireTime > DateTime.now().millisecondsSinceEpoch;
    if (savedVip && !active) {
      await _clearVip();
      return;
    }
    isVip.value = active;
    isTrialCanceled.value =
        active && (prefs.getBool(PrefsKeys.isTrialCanceled) ?? false);
  }

  Future<void> initInAppPurchase() async {
    if (!Platform.isIOS) return;
    if (isInitialized.value) return;
    final existing = _initFuture;
    if (existing != null) return existing;
    _initFuture = _performInitInAppPurchase();
    try {
      await _initFuture;
    } finally {
      _initFuture = null;
    }
  }

  Future<void> _performInitInAppPurchase() async {
    if (_isInitializing || isInitialized.value) return;
    _isInitializing = true;
    try {
      await _purchaser.configure(
        productIds: SubscriptionConfig.subscriptionProductIds,
        lifetimeIds: SubscriptionConfig.oneTimeProductIds,
        showLog: false,
      );
      await getAllProducts();
      _listenPurchaseStreams();
      isInitialized.value = true;
      await syncSubscriptionStatus();
    } catch (e, st) {
      debugPrint('[SubscriptionService] init failed: $e\n$st');
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> getAllProducts() async {
    if (!Platform.isIOS) return;
    try {
      final items = await _purchaser.getAllProducts();
      products.assignAll(items);
      _cacheIntroOfferDays(items);
      productsLoaded.value = products.isNotEmpty;
    } catch (e, st) {
      debugPrint('[SubscriptionService] getAllProducts failed: $e\n$st');
    }
  }

  /// 确保商品已真正加载（价格 / 试用信息可用）。
  ///
  /// TestFlight/生产目录首拉可能返回空（付费协议未生效、IAP 未就绪、传播延迟等），
  /// 此时 [products] 为空、页面会退回写死的 fallback 价、且无法发起购买。原生
  /// `getAllProducts` 在列表为空时会重新拉取，故这里对空列表再重试一次，尽量恢复。
  /// 返回是否已拿到商品。
  Future<bool> ensureProductsLoaded() async {
    if (!Platform.isIOS) return false;
    await initInAppPurchase();
    if (products.isEmpty) await getAllProducts();
    return products.isNotEmpty;
  }

  Product? productOf(String productId) {
    for (final product in products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  int introOfferDaysFor(String productId) {
    final fromProduct = _introOfferDaysFromProduct(productOf(productId));
    if (fromProduct != null) return fromProduct;
    return introOfferDaysByProductId[productId] ??
        SubscriptionResource.defaultIntroOfferDays;
  }

  Future<String> buttonText(String productId) async {
    if (!Platform.isIOS) return 'Subscribe';
    try {
      return await _purchaser.getProductForVipButtonText(
        productId: productId,
        langCode: _languageCode,
      );
    } catch (_) {
      return 'Subscribe';
    }
  }

  Future<String> titleFor(
    String productId,
    SubscriptionPeriodType periodType,
  ) async {
    if (!Platform.isIOS) return '';
    try {
      return await _purchaser.getProductForVipTitle(
        productId: productId,
        periodType: periodType,
        langCode: _languageCode,
      );
    } catch (_) {
      return '';
    }
  }

  Future<String> subtitleFor(
    String productId,
    SubscriptionPeriodType periodType,
  ) async {
    if (!Platform.isIOS) return '';
    try {
      return await _purchaser.getProductForVipSubtitle(
        productId: productId,
        periodType: periodType,
        langCode: _languageCode,
      );
    } catch (_) {
      return '';
    }
  }

  /// 确保内购已初始化且交易历史至少完整同步过一次。
  ///
  /// [isFirstPurchase] / VIP 状态均以「最近一次 syncSubscriptionStatus」的结果为准，
  /// 之后交易变更由监听流自动重新同步，故此处只需保证首次同步已完成，避免每次
  /// 查询都重复 refreshPurchases。
  Future<void> ensureSubscriptionSynced() async {
    if (!Platform.isIOS) return;
    await initInAppPurchase();
    if (!_didInitialSync) await syncSubscriptionStatus();
  }

  /// 查询指定订阅商品是否可享首订试用（= 是否首订）。
  ///
  /// 单一数据源：统一返回 [isFirstPurchase]（由 [checkIsFirstPurchase] 在每次同步后
  /// 综合「交易历史 + StoreKit 资格」算得），确保引导页与应用内订阅页对同一用户判断
  /// 完全一致。本 App 两个订阅 ID 同属一个订阅组，按订阅组维度判断即可覆盖。
  Future<bool> isEligibleForIntroOffer(String productId) async {
    if (!Platform.isIOS) return false;
    await ensureSubscriptionSynced();
    return isFirstPurchase.value;
  }

  /// 综合判断当前用户是否首订（默认 true，命中任一「已订阅」证据即置 false）：
  /// 1) 已是本地会员；
  /// 2) 有效交易 / 最新交易中出现订阅组商品 → 确凿的非首订；
  /// 3) 任一订阅商品的原生资格为 false。
  ///
  /// 必须在 `refreshPurchases()` 之后调用：交易列表由原生刷新后缓存，未刷新时为空，
  /// 否则会把老用户误判成首订。可传入已获取的交易列表以避免重复的原生调用。
  Future<bool> checkIsFirstPurchase({
    List<Transaction>? valid,
    List<Transaction>? latest,
  }) async {
    if (!Platform.isIOS) {
      isFirstPurchase.value = false;
      return false;
    }
    if (isVip.value) {
      isFirstPurchase.value = false;
      return false;
    }
    var first = true;
    try {
      final validTx = valid ?? await _purchaser.getValidPurchasedTransactions();
      final latestTx = latest ?? await _purchaser.getLatestTransactions();
      for (final tx in [...validTx, ...latestTx]) {
        if (SubscriptionConfig.subscriptionProductIds.contains(tx.productID)) {
          first = false;
          break;
        }
      }
      if (first) {
        for (final product in products) {
          final subscription = product.subscription;
          if (subscription == null || subscription.introductoryOffer == null) {
            continue;
          }
          if (subscription.isEligibleForIntroOffer == false) {
            first = false;
            break;
          }
        }
      }
    } catch (e, st) {
      debugPrint('[SubscriptionService] checkIsFirstPurchase failed: $e\n$st');
    }
    isFirstPurchase.value = first;
    return first;
  }

  Future<void> purchase(String productId, SubscriptionSource source) async {
    if (!Platform.isIOS) return;
    _source = source;
    await initInAppPurchase();
    // 商品未就绪时先重试加载；仍拿不到就不弹假 loading（原生找不到商品也不会拉起
    // 支付弹窗，只会空转），直接提示并返回，避免用户点了没反应。
    if (productOf(productId) == null) await ensureProductsLoaded();
    if (productOf(productId) == null) {
      debugPrint(
        '[SubscriptionService] purchase aborted, product not loaded: $productId',
      );
      _notifyProductsUnavailable();
      return;
    }
    final hasTrial =
        SubscriptionConfig.hasIntroOfferLoading(productId) &&
        await isEligibleForIntroOffer(productId);
    unawaited(
      PurchaseLoading.show(
        type: hasTrial ? 0 : 1,
        trialDays: introOfferDaysFor(productId),
      ),
    );
    try {
      await _purchaser.purchase(productId: productId);
    } catch (e, st) {
      debugPrint('[SubscriptionService] purchase failed: $e\n$st');
    } finally {
      unawaited(
        Future<void>.delayed(
          const Duration(milliseconds: 500),
          PurchaseLoading.dismiss,
        ),
      );
    }
  }

  /// 商品未加载导致无法购买时的用户提示（避免静默失败）。
  void _notifyProductsUnavailable() {
    if (Get.isSnackbarOpen) return;
    Get.snackbar(
      lt('Store unavailable', '商店暂不可用'),
      lt(
        'Subscription products are still loading. Please check your network and try again in a moment.',
        '订阅商品仍在加载，请检查网络稍后重试。',
      ),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> restore(SubscriptionSource source) async {
    if (!Platform.isIOS) return;
    _source = source;
    await initInAppPurchase();
    // 复用购买流程的 loading 动画（普通样式，无试用）。
    unawaited(PurchaseLoading.show(type: 1));
    try {
      await _purchaser.restorePurchases();
      // 恢复完成后立即同步会员状态，确保调用方读到的 isVip 为最新值。
      await syncSubscriptionStatus();
    } catch (e, st) {
      debugPrint('[SubscriptionService] restore failed: $e\n$st');
    } finally {
      unawaited(
        Future<void>.delayed(
          const Duration(milliseconds: 500),
          PurchaseLoading.dismiss,
        ),
      );
    }
  }

  /// 打开系统订阅管理界面（StoreKit 的「管理订阅」面板，可在此查看 / 取消订阅）。
  Future<void> manageSubscriptions() async {
    if (!Platform.isIOS) return;
    await initInAppPurchase();
    try {
      await _purchaser.showManageSubscriptionsSheet();
    } catch (e, st) {
      debugPrint('[SubscriptionService] manage subscriptions failed: $e\n$st');
    }
  }

  /// 订阅页展示规则：
  ///
  /// - 非会员：展示订阅页。
  /// - 试用期内已取消续订的会员：仍是会员，但再次触发会员功能时展示非首订页。
  /// - 正常会员：不展示订阅页。
  Future<bool> shouldShowSubscriptionPage() async {
    if (_isAndroidVipMode) return false;
    await loadLocalVipStatus();
    return !isVip.value || isTrialCanceled.value;
  }

  /// 应用内订阅页展示的统一收口（对齐分贝 showSubscriptionPage）。
  ///
  /// 所有「应用内触发订阅」的入口都应走这里，保证一致的展示规则与会话去重：
  /// - 正常会员（非试用取消）：不展示；
  /// - 试用期内已取消续订的会员：本会话仅展示一次（[isShowedSubOnThisSession] 去重）；
  /// - 非会员：展示。
  ///
  /// 返回展示流程结束后最新的 [isVip]（供调用方决定是否放行受限功能）。
  Future<bool> presentSubscriptionIfNeeded({
    SubscriptionSource source = SubscriptionSource.subscription,
  }) async {
    if (_isAndroidVipMode) return true;
    await syncSubscriptionStatus();
    await loadLocalVipStatus();
    // 正常会员：无需展示。
    if (isVip.value && !isTrialCanceled.value) return true;
    final prefs = await SharedPreferences.getInstance();
    // 试用期内取消续订的会员：本会话已展示过则不再打扰。
    if (isVip.value && isTrialCanceled.value) {
      final showed = prefs.getBool(PrefsKeys.isShowedSubOnThisSession) ?? false;
      if (showed) return true;
      await prefs.setBool(PrefsKeys.isShowedSubOnThisSession, true);
    }
    await Get.toNamed(SubscriptionPage.routeName, arguments: source);
    await loadLocalVipStatus();
    return isVip.value;
  }

  @visibleForTesting
  Future<void> handleStateChangedForTest(Map<String, dynamic> stateMap) {
    return _handleStateChanged(stateMap);
  }

  Future<void> syncSubscriptionStatus() async {
    if (!Platform.isIOS || _isSyncing) return;
    _isSyncing = true;
    try {
      await _purchaser.refreshPurchases();
      final valid = await _purchaser.getValidPurchasedTransactions();
      final latest = await _purchaser.getLatestTransactions();
      var updated = false;
      for (final transaction in [...valid, ...latest]) {
        updated = await _updateVipStatus(transaction);
        if (updated) break;
      }
      if (!updated) await loadLocalVipStatus();
      // 交易历史已刷新、VIP 状态已判定，此时综合判断首订最可靠。
      await checkIsFirstPurchase(valid: valid, latest: latest);
      _didInitialSync = true;
    } catch (e, st) {
      debugPrint('[SubscriptionService] sync failed: $e\n$st');
    } finally {
      _isSyncing = false;
    }
  }

  void _listenPurchaseStreams() {
    _stateSubscription?.cancel();
    _stateSubscription = _purchaser.onStateChanged.listen(_handleStateChanged);

    _productsSubscription?.cancel();
    _productsSubscription = _purchaser.onProductsLoaded.listen((items) {
      final loadedProducts = items.map(Product.fromMap).toList();
      products.assignAll(loadedProducts);
      _cacheIntroOfferDays(loadedProducts);
    });

    _transactionsSubscription?.cancel();
    _transactionsSubscription = _purchaser.onPurchasedTransactionsUpdated
        .listen((_) => unawaited(syncSubscriptionStatus()));
  }

  Future<void> _handleStateChanged(Map<String, dynamic> stateMap) async {
    final type = stateMap['type']?.toString() ?? '';
    switch (type) {
      case StoreKitState.purchaseSuccess:
        await PurchaseLoading.dismiss();
        final raw = stateMap['transaction'];
        if (raw is Map) {
          final transaction = Transaction.fromMap(
            Map<String, dynamic>.from(raw),
          );
          // 先置会员状态，尽快触发跳转；缓存与归因/首订上传放到后台异步执行，不阻塞进入首页。
          await _updateVipStatus(transaction);
          unawaited(_cacheFirstSubscription(transaction));
        }
        break;
      case StoreKitState.purchaseCancelled:
      case StoreKitState.purchaseFailed:
        await PurchaseLoading.dismiss();
        break;
      case StoreKitState.restorePurchasesSuccess:
      case StoreKitState.purchaseRefunded:
      case StoreKitState.purchaseRevoked:
        await syncSubscriptionStatus();
        break;
      case StoreKitState.subscriptionCancelled:
        await _handleSubscriptionCancelled(stateMap);
        break;
      default:
        break;
    }
  }

  Future<void> _handleSubscriptionCancelled(
    Map<String, dynamic> stateMap,
  ) async {
    debugPrint('[SubscriptionService] subscription cancelled: $stateMap');
    final trialCanceled =
        stateMap['isSubscribedButFreeTrailCancelled'] as bool? ?? false;
    final productId = stateMap['productId']?.toString() ?? '';

    await syncSubscriptionStatus();
    await loadLocalVipStatus();

    if (!trialCanceled) return;

    final prefs = await SharedPreferences.getInstance();
    final savedProductId = prefs.getString(PrefsKeys.vipProductId) ?? '';
    final sameProduct =
        productId.isEmpty ||
        savedProductId.isEmpty ||
        productId == savedProductId;
    if (!sameProduct) {
      debugPrint(
        '[SubscriptionService] ignored trial cancellation for product: '
        '$productId, current: $savedProductId',
      );
      return;
    }

    final expireTime = prefs.getInt(PrefsKeys.vipExpireTime) ?? 0;
    final active =
        (prefs.getBool(PrefsKeys.isVip) ?? false) &&
        expireTime > DateTime.now().millisecondsSinceEpoch;
    if (!active) return;

    await prefs.setBool(PrefsKeys.isTrialCanceled, true);
    await prefs.setBool(PrefsKeys.isShowedSubOnThisSession, false);
    isVip.value = true;
    isTrialCanceled.value = true;
  }

  Future<void> _cacheFirstSubscription(Transaction transaction) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      PrefsKeys.currentBuyProductId,
      transaction.productID ?? '',
    );
    await prefs.setString(
      PrefsKeys.sdOriginTransactionId,
      transaction.originalID ?? '',
    );
    await prefs.setString(
      PrefsKeys.sdOriginalPurchaseDateMs,
      '${transaction.originalPurchaseDate ?? 0}',
    );
    unawaited(SubscriptionUploadApi.uploadFirstSubscription());
  }

  Future<bool> _updateVipStatus(Transaction transaction) async {
    final productId = transaction.productID;
    final expireTime = transaction.expirationDate;
    if (productId == null ||
        !SubscriptionConfig.subscriptionProductIds.contains(productId) ||
        expireTime == null ||
        expireTime <= DateTime.now().millisecondsSinceEpoch) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.isVip, true);
    await prefs.setString(PrefsKeys.vipProductId, productId);
    await prefs.setInt(
      PrefsKeys.lastPurchaseTime,
      transaction.purchaseDate ?? 0,
    );
    await prefs.setInt(PrefsKeys.vipExpireTime, expireTime);
    final trialCanceled = transaction.isSubscribedButFreeTrailCancelled;
    await prefs.setBool(PrefsKeys.isTrialCanceled, trialCanceled);
    isVip.value = true;
    isTrialCanceled.value = trialCanceled;
    return true;
  }

  void _cacheIntroOfferDays(Iterable<Product> items) {
    final updated = Map<String, int>.of(introOfferDaysByProductId);
    for (final product in items) {
      final id = product.id;
      final days = _introOfferDaysFromProduct(product);
      if (id != null && id.isNotEmpty && days != null) {
        updated[id] = days;
      }
    }
    introOfferDaysByProductId.assignAll(updated);
  }

  int? _introOfferDaysFromProduct(Product? product) {
    final offer = product?.subscription?.introductoryOffer;
    final count = offer?.periodCount;
    final unit = offer?.periodUnit;
    if (count == null || count <= 0) return null;
    return switch (unit) {
      SubscriptionPeriodUnit.day => count,
      SubscriptionPeriodUnit.week => count * 7,
      SubscriptionPeriodUnit.month => count * 30,
      SubscriptionPeriodUnit.year => count * 365,
      _ => null,
    };
  }

  Future<void> _clearVip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.isVip, false);
    await prefs.setString(PrefsKeys.vipProductId, '');
    await prefs.setInt(PrefsKeys.lastPurchaseTime, 0);
    await prefs.setInt(PrefsKeys.vipExpireTime, 0);
    await prefs.setBool(PrefsKeys.isTrialCanceled, false);
    // 会员权益清除后，允许下个会话重新展示订阅页（对齐分贝 _clearVip）。
    await prefs.setBool(PrefsKeys.isShowedSubOnThisSession, false);
    isVip.value = false;
    isTrialCanceled.value = false;
  }

  /// VIP 导航门控。
  ///
  /// - 非会员：弹出订阅页，关闭后**不**跳转目标页。
  /// - 试用期内已取消续订的会员：先弹出非首订页，关闭后仍可进入目标页。
  /// - 会员：直接跳转目标页。
  Future<void> navigateWithVipGate({
    required String destination,
    dynamic arguments,
    SubscriptionSource source = SubscriptionSource.subscription,
  }) async {
    if (_isAndroidVipMode) {
      Get.toNamed(destination, arguments: arguments);
      return;
    }
    await syncSubscriptionStatus();
    await loadLocalVipStatus();
    final wasVip = isVip.value;
    if (await shouldShowSubscriptionPage()) {
      if (wasVip && isTrialCanceled.value) {
        final prefs = await SharedPreferences.getInstance();
        final showed =
            prefs.getBool(PrefsKeys.isShowedSubOnThisSession) ?? false;
        if (!showed) {
          await prefs.setBool(PrefsKeys.isShowedSubOnThisSession, true);
          await Get.toNamed(SubscriptionPage.routeName, arguments: source);
          await loadLocalVipStatus();
        }
        if (isVip.value) Get.toNamed(destination, arguments: arguments);
        return;
      }
      await Get.toNamed(SubscriptionPage.routeName, arguments: source);
      await loadLocalVipStatus();
      if (!wasVip) return;
    }
    if (isVip.value) Get.toNamed(destination, arguments: arguments);
  }

  String get _languageCode {
    final locale = Get.locale;
    if (locale == null) return 'en';
    if (locale.languageCode == 'zh') return 'zh_Hans';
    return locale.languageCode;
  }

  @override
  void onClose() {
    if (Platform.isIOS) WidgetsBinding.instance.removeObserver(this);
    _stateSubscription?.cancel();
    _productsSubscription?.cancel();
    _transactionsSubscription?.cancel();
    super.onClose();
  }

  SubscriptionSource get lastSource => _source;
}
