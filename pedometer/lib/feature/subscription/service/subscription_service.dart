import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:pp_inapp_purchase/inapp_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pedometer/common/config/prefs_keys.dart';
import 'package:pedometer/feature/subscription/api/subscription_upload_api.dart';
import 'package:pedometer/feature/subscription/config/subscription_config.dart';

class SubscriptionService extends GetxService {
  final InappPurchase _purchaser = InappPurchase.instance;

  final RxBool isVip = false.obs;
  final RxBool isInitialized = false.obs;
  final RxList<Product> products = <Product>[].obs;

  StreamSubscription<Map<String, dynamic>>? _stateSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _productsSubscription;
  StreamSubscription<Map<String, dynamic>>? _transactionsSubscription;

  bool _isInitializing = false;
  bool _isSyncing = false;
  SubscriptionSource _source = SubscriptionSource.startLoading;

  Future<SubscriptionService> init() async {
    await loadLocalVipStatus();
    return this;
  }

  Future<void> loadLocalVipStatus() async {
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
  }

  Future<void> initInAppPurchase() async {
    if (!Platform.isIOS) return;
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
      products.assignAll(await _purchaser.getAllProducts());
    } catch (e, st) {
      debugPrint('[SubscriptionService] getAllProducts failed: $e\n$st');
    }
  }

  Product? productOf(String productId) {
    for (final product in products) {
      if (product.id == productId) return product;
    }
    return null;
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

  Future<bool> isEligibleForIntroOffer(String productId) async {
    if (!Platform.isIOS) return false;
    try {
      return await _purchaser.isEligibleForIntroOffer(productId: productId);
    } catch (_) {
      return productOf(productId)?.subscription?.isEligibleForIntroOffer ??
          false;
    }
  }

  Future<void> purchase(String productId, SubscriptionSource source) async {
    if (!Platform.isIOS) return;
    _source = source;
    await initInAppPurchase();
    try {
      await _purchaser.purchase(productId: productId);
    } catch (e, st) {
      debugPrint('[SubscriptionService] purchase failed: $e\n$st');
    }
  }

  Future<void> restore(SubscriptionSource source) async {
    if (!Platform.isIOS) return;
    _source = source;
    await initInAppPurchase();
    try {
      await _purchaser.restorePurchases();
    } catch (e, st) {
      debugPrint('[SubscriptionService] restore failed: $e\n$st');
    }
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
      products.assignAll(items.map(Product.fromMap));
    });

    _transactionsSubscription?.cancel();
    _transactionsSubscription = _purchaser.onPurchasedTransactionsUpdated
        .listen((_) => unawaited(syncSubscriptionStatus()));
  }

  Future<void> _handleStateChanged(Map<String, dynamic> stateMap) async {
    final type = stateMap['type']?.toString() ?? '';
    switch (type) {
      case StoreKitState.purchaseSuccess:
        final raw = stateMap['transaction'];
        if (raw is Map) {
          final transaction = Transaction.fromMap(
            Map<String, dynamic>.from(raw),
          );
          await _cacheFirstSubscription(transaction);
          await _updateVipStatus(transaction);
        }
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
    await prefs.setBool(
      PrefsKeys.isTrialCanceled,
      transaction.isSubscribedButFreeTrailCancelled,
    );
    isVip.value = true;
    return true;
  }

  Future<void> _handleSubscriptionCancelled(
    Map<String, dynamic> stateMap,
  ) async {
    final isTrialCancelled =
        stateMap['isSubscribedButFreeTrailCancelled'] == true;
    final productId = stateMap['productId']?.toString();
    if (productId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final currentProductId = prefs.getString(PrefsKeys.vipProductId);
    if (currentProductId != productId) return;
    await prefs.setBool(PrefsKeys.isTrialCanceled, isTrialCancelled);
  }

  Future<void> _clearVip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.isVip, false);
    await prefs.setString(PrefsKeys.vipProductId, '');
    await prefs.setInt(PrefsKeys.lastPurchaseTime, 0);
    await prefs.setInt(PrefsKeys.vipExpireTime, 0);
    isVip.value = false;
  }

  String get _languageCode {
    final locale = Get.locale;
    if (locale == null) return 'en';
    if (locale.languageCode == 'zh') return 'zh_Hans';
    return locale.languageCode;
  }

  @override
  void onClose() {
    _stateSubscription?.cancel();
    _productsSubscription?.cancel();
    _transactionsSubscription?.cancel();
    super.onClose();
  }

  SubscriptionSource get lastSource => _source;
}
