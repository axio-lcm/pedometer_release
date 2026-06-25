import 'dart:ui';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pedometer/feature/mine/model/language_catalog.dart';

/// 解析并持久化用户语言偏好。
///
/// [languageCode] 保存用户所选：`sys`（跟随系统）或资源码（`en` / `zh_Hans` / `ja` …）；
/// [resourceLanguageCode] 为解析后实际生效的资源码（永不为 `sys`）。
class LanguageService extends GetxService {
  static const _prefsKey = 'language_code';

  SharedPreferences? _prefs;

  /// 用户所选语言码：`sys` 或受支持的资源码。
  final languageCode = 'sys'.obs;
  final localeRevision = 0.obs;

  /// 实际生效的资源码：`sys` 时按系统语言解析，不支持回退 `en`。
  String get resourceLanguageCode {
    final code = languageCode.value;
    if (code == 'sys') {
      return LanguageCatalog.resolveSystem(PlatformDispatcher.instance.locale);
    }
    return LanguageCatalog.normalizeCode(code);
  }

  Locale get locale => LanguageCatalog.localeForCode(resourceLanguageCode);

  Future<LanguageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    final stored = _prefs?.getString(_prefsKey);
    languageCode.value = (stored == null || stored.isEmpty)
        ? 'sys'
        : _normalize(stored);
    return this;
  }

  Future<void> setLanguageCode(String code) async {
    final normalized = _normalize(code);
    languageCode.value = normalized;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setString(_prefsKey, normalized);
  }

  void markLocaleChanged() {
    localeRevision.value++;
  }

  /// `sys` 原样保留，其余兼容旧值后归一化到受支持资源码。
  String _normalize(String code) {
    final value = code.trim();
    if (value == 'sys') return 'sys';
    return LanguageCatalog.tryNormalizeCode(value) ?? 'sys';
  }
}
