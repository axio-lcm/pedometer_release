import 'dart:io';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:pedometer/common/config/app_config.dart';
import 'package:pedometer/common/config/prefs_keys.dart';
import 'package:pedometer/common/network/models/header_data.dart';
import 'package:pedometer/common/network/utils/dio_factory.dart';
import 'package:pedometer/common/storage/language_service.dart';

/// 公共 Header 管理器：安全获取并缓存所有公共请求参数（移植自 al_led_banner）。
class HeaderManager {
  HeaderManager._internal();

  static final HeaderManager _instance = HeaderManager._internal();
  static HeaderManager get instance => _instance;
  factory HeaderManager() => _instance;

  HeaderData? _cachedHeaderData;
  bool _isInitialized = false;

  static final Dio _publicIpDio = DioFactory.createPublicIpDio();

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _cachedHeaderData = await _buildHeaderData();
    } catch (_) {
      _cachedHeaderData = await _getDefaultHeaderData();
    }
    _isInitialized = true;
  }

  Future<HeaderData> getHeaderData() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _cachedHeaderData ?? await _getDefaultHeaderData();
  }

  Future<void> refresh() async {
    _isInitialized = false;
    await initialize();
  }

  Future<HeaderData> _buildHeaderData() async {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();
    final connectivity = await Connectivity().checkConnectivity();
    final cip = await _resolvePublicIp();
    final systemLocale = PlatformDispatcher.instance.locale;

    return HeaderData(
      userId: await _resolveDeviceUserId(prefs),
      deviceType: Platform.isIOS ? 'iOS' : 'android',
      deviceModel: await _resolveDeviceModel(deviceInfo),
      deviceOSVersion: await _resolveOsVersion(deviceInfo),
      screenWH: _resolveScreenSize(),
      sysLocale: _formatLocale(systemLocale),
      appLangCode: _resolveAppLangCode(systemLocale),
      cip: cip,
      netType: _mapNetType(connectivity),
      appId: Constants.appleId,
      appVersion: packageInfo.version,
      sct: Constants.sct,
      xForwardedFor: cip,
    );
  }

  Future<String> _resolveDeviceUserId(SharedPreferences prefs) async {
    final saved = prefs.getString(PrefsKeys.deviceUserId);
    if (saved != null && saved.isNotEmpty) return saved;

    final generated = const Uuid().v4();
    await prefs.setString(PrefsKeys.deviceUserId, generated);
    return generated;
  }

  Future<String> _resolvePublicIp() async {
    try {
      final response = await _publicIpDio.get<Map<String, dynamic>>(
        'https://api.ipify.org?format=json',
      );
      return response.data?['ip']?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  String _resolveScreenSize() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return '0x0';

    final view = views.first;
    final logicalSize = view.physicalSize / view.devicePixelRatio;
    return '${logicalSize.width.round()}x${logicalSize.height.round()}';
  }

  Future<String> _resolveDeviceModel(DeviceInfoPlugin deviceInfo) async {
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return info.model;
    }
    if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return info.utsname.machine;
    }
    return 'unknown';
  }

  Future<String> _resolveOsVersion(DeviceInfoPlugin deviceInfo) async {
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return 'Android ${info.version.release}';
    }
    if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return 'iOS ${info.systemVersion}';
    }
    return Platform.operatingSystemVersion;
  }

  String _formatLocale(Locale locale) {
    final countryCode = locale.countryCode;
    if (countryCode == null || countryCode.isEmpty) {
      return locale.languageCode;
    }
    return '${locale.languageCode}_$countryCode';
  }

  /// 应用语言优先取应用内设置（LanguageService），否则回退系统语言。
  String _resolveAppLangCode(Locale systemLocale) {
    if (Get.isRegistered<LanguageService>()) {
      return Get.find<LanguageService>().resourceLanguageCode;
    }
    return systemLocale.languageCode == 'zh' ? 'zh' : systemLocale.languageCode;
  }

  String _mapNetType(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return 'NONE';
    }
    if (results.contains(ConnectivityResult.wifi)) return 'WIFI';
    if (results.contains(ConnectivityResult.ethernet)) return 'ETHERNET';
    if (results.contains(ConnectivityResult.vpn)) return 'VPN';
    if (results.contains(ConnectivityResult.bluetooth)) return 'BLUETOOTH';
    return 'MOBILE';
  }

  Future<HeaderData> _getDefaultHeaderData() async {
    final prefs = await SharedPreferences.getInstance();
    return HeaderData(
      userId: await _resolveDeviceUserId(prefs),
      deviceType: Platform.isIOS ? 'iOS' : 'android',
      deviceModel: 'Unknown',
      deviceOSVersion: 'Unknown',
      screenWH: '-',
      sysLocale: _formatLocale(PlatformDispatcher.instance.locale),
      appLangCode: _resolveAppLangCode(PlatformDispatcher.instance.locale),
      cip: 'Unknown',
      netType: 'Unknown',
      appId: Constants.appleId,
      appVersion: 'Unknown',
      sct: Constants.sct,
      xForwardedFor: 'Unknown',
    );
  }
}
