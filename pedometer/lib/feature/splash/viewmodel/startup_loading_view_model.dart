import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:pedometer/feature/subscription/service/subscription_service.dart';
import 'package:pedometer/feature/subscription/views/onboarding_page.dart';
import 'package:pedometer/products/phone/views/main_page.dart';

enum StartupNetworkStatus { checking, connected, disconnected }

class StartupLoadingViewModel extends GetxController {
  static const _networkRetryInterval = Duration(seconds: 5);
  // 首启宽限期：系统网络授权弹窗弹出、网络栈尚未就绪时，先保持 loading，
  // 而不是立刻显示“网络不可用+重试”。宽限期结束仍无网络才切到 disconnected。
  static const _networkGracePeriod = Duration(seconds: 4);
  static const _maxTotalLoadingTime = Duration(seconds: 15);
  static const _purchaseTimeout = Duration(seconds: 10);
  static const _productsTimeout = Duration(seconds: 6);
  static const _attributionTimeout = Duration(seconds: 5);
  static const _membershipTimeout = Duration(seconds: 3);

  final Connectivity _connectivity = Connectivity();
  final progress = 0.0.obs;
  final networkStatus = StartupNetworkStatus.checking.obs;

  final Map<String, double> _phaseWeights = const {
    'session_prepare': 10,
    'attribution_prepare': 15,
    'purchase_init': 20,
    'products_prewarm': 20,
    'membership_check': 20,
    'background_tasks': 15,
  };
  final Set<String> _completedPhases = {};

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _networkRetryTimer;
  Timer? _networkGraceTimer;
  Timer? _progressTimer;
  Timer? _maxLoadingTimer;
  double _targetProgress = 0;
  double _currentProgress = 0;
  bool _graceElapsed = false;
  bool _startupStarted = false;
  bool _isCompleting = false;
  bool _completed = false;

  @override
  void onInit() {
    super.onInit();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChanged,
    );
    _startNetworkGraceTimer();
    unawaited(checkConnectivity());
  }

  void _startNetworkGraceTimer() {
    _networkGraceTimer = Timer(_networkGracePeriod, () {
      _graceElapsed = true;
      // 宽限期结束仍未连上网络，且尚未开始启动流程 → 此时才展示重试。
      if (!_startupStarted &&
          networkStatus.value != StartupNetworkStatus.connected) {
        networkStatus.value = StartupNetworkStatus.disconnected;
      }
    });
  }

  Future<void> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _handleConnectivityChanged(results);
    } catch (e, st) {
      debugPrint('[StartupLoading] connectivity check failed: $e\n$st');
      _handleConnectivityChanged(const [ConnectivityResult.none]);
    }
  }

  Future<void> retryNetwork() => checkConnectivity();

  void _handleConnectivityChanged(List<ConnectivityResult> results) {
    if (_completed) return;
    final connected = _hasUsableNetwork(results);

    if (connected) {
      networkStatus.value = StartupNetworkStatus.connected;
      _networkGraceTimer?.cancel();
      _networkGraceTimer = null;
      _networkRetryTimer?.cancel();
      _networkRetryTimer = null;
      _startStartupFlow();
      return;
    }

    // 未连上网络：宽限期内仍在等待授权/网络就绪，保持 loading 而非弹重试。
    if (!_graceElapsed && !_startupStarted) {
      networkStatus.value = StartupNetworkStatus.checking;
      _startNetworkRetryTimer();
      return;
    }

    networkStatus.value = StartupNetworkStatus.disconnected;
    if (!_startupStarted) {
      _startNetworkRetryTimer();
    }
  }

  bool _hasUsableNetwork(List<ConnectivityResult> results) {
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }

  void _startNetworkRetryTimer() {
    _networkRetryTimer ??= Timer.periodic(
      _networkRetryInterval,
      (_) => unawaited(checkConnectivity()),
    );
  }

  void _startStartupFlow() {
    if (_startupStarted) return;
    _startupStarted = true;
    _startMaxLoadingProtection();
    _startSmoothProgress();
    unawaited(_executeStartupFlow());
  }

  Future<void> _executeStartupFlow() async {
    final service = Get.find<SubscriptionService>();
    try {
      await _runPhase('session_prepare', service.prepareStartupSession);

      if (defaultTargetPlatform == TargetPlatform.android) {
        _forceCompleteProgress();
        return;
      }

      await _runPhase(
        'attribution_prepare',
        () => service.prepareStartupAttribution().timeout(_attributionTimeout),
      );
      _startStoreKitWarmup(service);
      await _runPhase(
        'membership_check',
        () => service.loadLocalVipStatus().timeout(_membershipTimeout),
      );
      await service.markStartupFinished();

      if (service.isVip.value) {
        _forceCompleteProgress();
        return;
      }

      _runBackgroundTasks();
    } catch (e, st) {
      debugPrint('[StartupLoading] startup flow failed: $e\n$st');
      _forceCompleteProgress();
    }
  }

  void _startStoreKitWarmup(SubscriptionService service) {
    unawaited(_executeStoreKitWarmup(service));
  }

  Future<void> _executeStoreKitWarmup(SubscriptionService service) async {
    await _runPhase(
      'purchase_init',
      () => service.initInAppPurchase().timeout(_purchaseTimeout),
    );
    await _runPhase(
      'products_prewarm',
      () => service.prewarmStartupProducts().timeout(_productsTimeout),
    );
    await service
        .refreshStartupMembership()
        .timeout(_membershipTimeout)
        .catchError((Object e, StackTrace st) {
          debugPrint(
            '[StartupLoading] background membership sync failed: $e\n$st',
          );
        });
  }

  void _runBackgroundTasks() {
    try {
      _markPhaseComplete('background_tasks');
    } finally {
      _forceCompleteProgress();
    }
  }

  Future<void> _runPhase(String phase, Future<void> Function() task) async {
    if (_isCompleting) return;
    try {
      await task();
    } catch (e, st) {
      debugPrint('[StartupLoading] phase $phase failed: $e\n$st');
    } finally {
      _markPhaseComplete(phase);
    }
  }

  void _startMaxLoadingProtection() {
    _maxLoadingTimer?.cancel();
    _maxLoadingTimer = Timer(_maxTotalLoadingTime, _forceCompleteProgress);
  }

  void _startSmoothProgress() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final upperBound = _isCompleting ? 100.0 : 96.0;
      final diff = _targetProgress - _currentProgress;
      if (diff.abs() <= 0.1) return;
      _currentProgress += diff * 0.16;
      if (_currentProgress > upperBound) _currentProgress = upperBound;
      progress.value = _currentProgress;
    });
  }

  void _markPhaseComplete(String phase) {
    if (_isCompleting) return;
    if (!_completedPhases.add(phase)) return;
    final weight = _phaseWeights[phase] ?? 0;
    _targetProgress = (_targetProgress + weight).clamp(0, 96);
  }

  void _forceCompleteProgress() {
    if (_completed || _isCompleting) return;
    _isCompleting = true;
    _maxLoadingTimer?.cancel();
    _networkRetryTimer?.cancel();
    _targetProgress = 100;
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      final diff = 100 - _currentProgress;
      if (diff <= 0.6) {
        timer.cancel();
        _currentProgress = 100;
        progress.value = 100;
        _completeStartup();
        return;
      }
      _currentProgress += diff * 0.18;
      progress.value = _currentProgress;
    });
  }

  void _completeStartup() {
    if (_completed) return;
    _completed = true;
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

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    _networkRetryTimer?.cancel();
    _networkGraceTimer?.cancel();
    _progressTimer?.cancel();
    _maxLoadingTimer?.cancel();
    super.onClose();
  }
}
