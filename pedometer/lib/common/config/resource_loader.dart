import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 从各模块 resources 目录下的 color.json / string.json 加载静态资源。
class ResourceLoader {
  ResourceLoader._();

  static final Map<String, Map<String, String>> _colors = {};
  static final Map<String, Map<String, String>> _strings = {};
  static bool _initialized = false;
  static String _languageCode = 'en';
  static String _systemFallbackLanguageCode = 'en';

  static const _modules = <(String module, String assetDir)>[
    ('common', 'lib/common/resources'),
    ('home', 'lib/feature/home/resources'),
    ('mine', 'lib/feature/mine/resources'),
    ('workout', 'lib/feature/workout/resources'),
    ('phone', 'lib/products/phone/resources'),
  ];

  static String get languageCode => _languageCode;
  static String get systemFallbackLanguageCode => _systemFallbackLanguageCode;

  static Future<void> init({String languageCode = 'en'}) async {
    if (_initialized) return;
    _systemFallbackLanguageCode = _resolveSystemLanguageCode();
    _languageCode = _normalizeLanguageCode(languageCode);
    for (final (module, assetDir) in _modules) {
      _colors[module] = await _loadJsonMap('$assetDir/color.json');
    }
    await _loadStringsForLanguage(_languageCode);
    _initialized = true;
  }

  static Future<void> setLanguageCode(String languageCode) async {
    _ensureInit();
    _systemFallbackLanguageCode = _resolveSystemLanguageCode();
    final nextLanguage = _normalizeLanguageCode(languageCode);
    if (_languageCode == nextLanguage) {
      await _loadStringsForLanguage(_languageCode);
      return;
    }
    _languageCode = nextLanguage;
    await _loadStringsForLanguage(_languageCode);
  }

  /// 仅供测试：用内存数据直接装载，跳过 rootBundle。
  @visibleForTesting
  static void loadForTest({
    Map<String, Map<String, String>> colors = const {},
    Map<String, Map<String, String>> strings = const {},
  }) {
    _colors
      ..clear()
      ..addAll(colors);
    _strings
      ..clear()
      ..addAll(strings);
    _initialized = true;
  }

  static Future<Map<String, String>> _loadJsonMap(String assetPath) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map((key, value) => MapEntry('$key', '$value'));
    } catch (_) {
      return {};
    }
  }

  static Future<void> _loadStringsForLanguage(String languageCode) async {
    for (final (module, assetDir) in _modules) {
      _strings[module] = await _resolveModuleStrings(
        module,
        assetDir,
        languageCode,
      );
    }
  }

  /// 取某模块某语言的译文：目标语言 → 系统语言 → 英文安全兜底 → 简体默认。
  /// 简体中文沿用既有的 `string.json`，其余语言用 `string_<code>.json`。
  static Future<Map<String, String>> _resolveModuleStrings(
    String module,
    String assetDir,
    String code,
  ) async {
    final english = await _loadLanguageMap(assetDir, 'en');
    final chain = <(String code, Map<String, String> strings)>[
      ('zh_Hans', await _loadLanguageMap(assetDir, 'zh_Hans')),
      ('en', english),
      (
        _systemFallbackLanguageCode,
        await _loadLanguageMap(assetDir, _systemFallbackLanguageCode),
      ),
      (code, await _loadLanguageMap(assetDir, code)),
    ];
    final merged = <String, String>{};
    for (final (fallbackCode, strings) in chain) {
      merged.addAll(
        _removeEnglishPlaceholders(module, fallbackCode, strings, english),
      );
    }
    return merged;
  }

  static Future<Map<String, String>> _loadLanguageMap(
    String assetDir,
    String code,
  ) {
    final fileName = code == 'zh_Hans' ? 'string.json' : 'string_$code.json';
    return _loadJsonMap('$assetDir/$fileName');
  }

  static Map<String, String> _removeEnglishPlaceholders(
    String module,
    String code,
    Map<String, String> strings,
    Map<String, String> english,
  ) {
    if (code == 'en' || code == 'zh_Hans' || strings.isEmpty) return strings;
    final placeholderKeys = strings.keys.where((key) {
      final value = strings[key];
      final englishValue = english[key];
      return value != null &&
          value == englishValue &&
          !_isLanguageNeutralKey(module, key) &&
          RegExp('[A-Za-z]').hasMatch(value);
    }).toList();
    if (placeholderKeys.isEmpty) return strings;
    return Map<String, String>.of(strings)
      ..removeWhere((key, _) => placeholderKeys.contains(key));
  }

  static bool _isLanguageNeutralKey(String module, String key) {
    return switch ((module, key)) {
      ('common', 'app_name') => true,
      ('mine', 'height_unit') => true,
      ('mine', 'weight_unit') => true,
      ('mine', 'bmi') => true,
      ('mine', 'language_english') => true,
      ('workout', 'distance_unit') => true,
      ('workout', 'duration_unit') => true,
      ('workout', 'hundred_km') => true,
      ('workout', 'metric_calorie_kcal') => true,
      ('workout', 'metric_pace_min_km') => true,
      _ => false,
    };
  }

  /// 入参一般已是解析后的资源码；这里仅兜底处理空值与旧版 `zh` 写法。
  static String _normalizeLanguageCode(String languageCode) {
    final code = languageCode.trim();
    if (code.isEmpty) return 'en';
    if (code == 'zh' || code.toLowerCase() == 'zh_cn') return 'zh_Hans';
    return code;
  }

  static String _resolveSystemLanguageCode() {
    final system = WidgetsBinding.instance.platformDispatcher.locale;
    final lang = system.languageCode;
    if (lang == 'zh') {
      if (system.scriptCode == 'Hant') return 'zh_Hant';
      final region = system.countryCode;
      if (region == 'TW' || region == 'HK' || region == 'MO') return 'zh_Hant';
      return 'zh_Hans';
    }
    return lang.isEmpty ? 'en' : lang;
  }

  static Color color(
    String module,
    String key, {
    String? fallbackModule,
    Color fallback = Colors.transparent,
  }) {
    _ensureInit();
    var value = _colors[module]?[key];
    if ((value == null || value.isEmpty) && fallbackModule != null) {
      value = _colors[fallbackModule]?[key];
    }
    if (value == null || value.isEmpty) return fallback;
    return _parseColor(value);
  }

  static String string(
    String module,
    String key, {
    String? fallbackModule,
    String fallback = '',
  }) {
    _ensureInit();
    var value = _strings[module]?[key];
    if ((value == null || value.isEmpty) && fallbackModule != null) {
      value = _strings[fallbackModule]?[key];
    }
    return value ?? fallback;
  }

  static Color _parseColor(String value) {
    if (value == 'transparent') return Colors.transparent;
    final hex = value.replaceFirst('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
    return Colors.transparent;
  }

  static void _ensureInit() {
    assert(
      _initialized,
      'ResourceLoader.init() must be called before using module resources.',
    );
  }
}
