import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends GetxService {
  static const _prefsKey = 'language_code';

  SharedPreferences? _prefs;

  final languageCode = 'en'.obs;
  final localeRevision = 0.obs;

  Locale get locale => languageCode.value == 'zh'
      ? const Locale('zh', 'CN')
      : const Locale('en', 'US');

  String get resourceLanguageCode => languageCode.value == 'zh' ? 'zh' : 'en';

  Future<LanguageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    languageCode.value = _normalize(_prefs?.getString(_prefsKey));
    return this;
  }

  Future<void> setLanguageCode(String code) async {
    final normalized = _normalize(code);
    if (languageCode.value == normalized) return;
    languageCode.value = normalized;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setString(_prefsKey, normalized);
  }

  void markLocaleChanged() {
    localeRevision.value++;
  }

  String _normalize(String? code) {
    final value = code?.trim().toLowerCase();
    return value == 'zh' || value == 'zh_cn' || value == 'zh-cn' ? 'zh' : 'en';
  }
}
