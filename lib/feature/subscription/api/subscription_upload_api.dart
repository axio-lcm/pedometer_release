import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pp_asa_attribution/pp_asa_attribution.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pedometer/common/config/app_config.dart';
import 'package:pedometer/common/config/prefs_keys.dart';
import 'package:pedometer/common/network/utils/aes_tool.dart';
import 'package:pedometer/common/network/utils/dio_request.dart';
import 'package:pedometer/common/network/utils/headers_manager.dart';

abstract final class SubscriptionUploadApi {
  static const int _maxRetryCount = 5;
  static const Duration _retryInterval = Duration(seconds: 60);

  static bool _asaUploading = false;
  static bool _firstSubscriptionUploading = false;
  static int _asaRetryCount = 0;
  static int _firstSubscriptionRetryCount = 0;
  static Timer? _asaRetryTimer;
  static Timer? _firstSubscriptionRetryTimer;

  static Future<void> saveAttributionJson() async {
    if (!Platform.isIOS) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(PrefsKeys.attributionJson) ?? '';
    if (saved.isNotEmpty) _extractCampaignId(saved, prefs);

    final isFirstLaunch = prefs.getBool(PrefsKeys.isFirstLaunch) ?? true;
    if (isFirstLaunch) {
      await _fetchAndSaveAttribution(prefs);
    } else {
      _fetchAndSaveAttribution(prefs);
    }
  }

  static Future<void> uploadAttributionRegister() async {
    _asaRetryTimer?.cancel();
    _asaRetryCount = 0;
    await _attemptAttributionRegisterUpload();
  }

  static Future<void> uploadFirstSubscription() async {
    _firstSubscriptionRetryTimer?.cancel();
    _firstSubscriptionRetryCount = 0;
    await _attemptFirstSubscriptionUpload();
  }

  static Future<void> _attemptAttributionRegisterUpload() async {
    if (!Platform.isIOS) return;
    if (_asaUploading || _asaRetryCount >= _maxRetryCount) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(PrefsKeys.isUploadedASAData) ?? false) return;

    _asaUploading = true;
    _asaRetryCount++;
    try {
      final token = await _attributionToken();
      final header = await HeaderManager.instance.getHeaderData();
      final data = {
        'userId': header.userId,
        'fcmId': '',
        'appVersion': header.appVersion,
        'deviceType': 'iOS',
        'devicePlatform': header.deviceModel,
        'deviceOSVersion': header.deviceOSVersion,
        'locale': header.sysLocale,
        'timezone': DateTime.now().timeZoneName,
        'attributionToken': token,
      };
      final uploaded = await _uploadEncrypted(
        endpoint: APIs.attributionRegister,
        data: data,
        uploadedKey: PrefsKeys.isUploadedASAData,
      );
      if (uploaded) {
        _asaRetryTimer?.cancel();
        _asaRetryCount = 0;
      } else {
        _scheduleAttributionRegisterRetry();
      }
    } catch (e, st) {
      debugPrint('[SubscriptionUploadApi] ASA upload failed: $e\n$st');
      _scheduleAttributionRegisterRetry();
    } finally {
      _asaUploading = false;
    }
  }

  static Future<void> _attemptFirstSubscriptionUpload() async {
    if (!Platform.isIOS) return;
    if (_firstSubscriptionUploading ||
        _firstSubscriptionRetryCount >= _maxRetryCount) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(PrefsKeys.isUploadedFirstSubsData) ?? false) return;

    _firstSubscriptionUploading = true;
    _firstSubscriptionRetryCount++;
    try {
      final token = await _attributionToken();
      final header = await HeaderManager.instance.getHeaderData();
      final data = {
        'shareGroupId': '',
        'userId': header.userId,
        'productId': prefs.getString(PrefsKeys.currentBuyProductId) ?? '',
        'originTransactionId':
            prefs.getString(PrefsKeys.sdOriginTransactionId) ?? '',
        'originalPurchaseDateMs':
            prefs.getString(PrefsKeys.sdOriginalPurchaseDateMs) ?? '',
        'fcmId': '',
        'appVersion': header.appVersion,
        'deviceType': 'iOS',
        'devicePlatform': header.deviceModel,
        'deviceOSVersion': header.deviceOSVersion,
        'locale': header.sysLocale,
        'timezone': DateTime.now().timeZoneName,
        'attributionToken': token,
      };
      final uploaded = await _uploadEncrypted(
        endpoint: APIs.firstSubscription,
        data: data,
        uploadedKey: PrefsKeys.isUploadedFirstSubsData,
      );
      if (uploaded) {
        _firstSubscriptionRetryTimer?.cancel();
        _firstSubscriptionRetryCount = 0;
      } else {
        _scheduleFirstSubscriptionRetry();
      }
    } catch (e, st) {
      debugPrint(
        '[SubscriptionUploadApi] first subscription upload failed: $e\n$st',
      );
      _scheduleFirstSubscriptionRetry();
    } finally {
      _firstSubscriptionUploading = false;
    }
  }

  static Future<void> _fetchAndSaveAttribution(SharedPreferences prefs) async {
    try {
      final details = await PPAsaAttribution().requestAttributionDetails();
      if (details == null || details.isEmpty) return;
      final raw = jsonEncode(details);
      await prefs.setString(PrefsKeys.attributionJson, raw);
      _extractCampaignId(raw, prefs);
    } catch (e, st) {
      debugPrint('[SubscriptionUploadApi] attribution failed: $e\n$st');
    }
  }

  static void _extractCampaignId(String raw, SharedPreferences prefs) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || !decoded.containsKey('campaignId')) return;
      final campaignId = int.tryParse('${decoded['campaignId']}') ?? 0;
      if (campaignId > 0) {
        prefs.setInt(PrefsKeys.campaignId, campaignId);
      }
    } catch (_) {}
  }

  static Future<String> _attributionToken() async {
    try {
      return await PPAsaAttribution().attributionToken() ?? '';
    } catch (_) {
      return '';
    }
  }

  static void _scheduleAttributionRegisterRetry() {
    if (_asaRetryCount >= _maxRetryCount) return;
    _asaRetryTimer?.cancel();
    _asaRetryTimer = Timer(_retryInterval, _attemptAttributionRegisterUpload);
  }

  static void _scheduleFirstSubscriptionRetry() {
    if (_firstSubscriptionRetryCount >= _maxRetryCount) return;
    _firstSubscriptionRetryTimer?.cancel();
    _firstSubscriptionRetryTimer = Timer(
      _retryInterval,
      _attemptFirstSubscriptionUpload,
    );
  }

  static Future<bool> _uploadEncrypted({
    required String endpoint,
    required Map<String, dynamic> data,
    required String uploadedKey,
  }) async {
    final encrypted = AesTool.encrypt(jsonEncode(data));
    if (encrypted.isEmpty) return false;
    final headerData = await HeaderManager.instance.getHeaderData();
    final response = await dioRequest.postJson(
      endpoint,
      parameters: {'data': encrypted},
      headers: {...headerData.toApiToolMap(), 'sct': AesTool.kSctToken},
      logEnabled: false,
    );
    final success =
        response != null &&
        (response['code'] == 200 ||
            response['code'] == 0 ||
            response['success'] == true);
    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(uploadedKey, true);
    }
    return success;
  }
}
