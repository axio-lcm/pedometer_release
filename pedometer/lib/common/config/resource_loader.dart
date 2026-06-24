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

  static const _modules = <(String module, String assetDir)>[
    ('common', 'lib/common/resources'),
    ('home', 'lib/feature/home/resources'),
    ('mine', 'lib/feature/mine/resources'),
    ('workout', 'lib/feature/workout/resources'),
    ('phone', 'lib/products/phone/resources'),
  ];

  static String get languageCode => _languageCode;

  static Future<void> init({String languageCode = 'en'}) async {
    if (_initialized) return;
    _languageCode = _normalizeLanguageCode(languageCode);
    for (final (module, assetDir) in _modules) {
      _colors[module] = await _loadJsonMap('$assetDir/color.json');
    }
    await _loadStringsForLanguage(_languageCode);
    _initialized = true;
  }

  static Future<void> setLanguageCode(String languageCode) async {
    _ensureInit();
    final nextLanguage = _normalizeLanguageCode(languageCode);
    if (_languageCode == nextLanguage) return;
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
      final localized = await _loadJsonMap(
        '$assetDir/string_$languageCode.json',
      );
      if (localized.isNotEmpty) {
        _strings[module] = localized;
        continue;
      }
      _strings[module] = await _loadJsonMap('$assetDir/string.json');
    }
  }

  static String _normalizeLanguageCode(String languageCode) {
    final code = languageCode.toLowerCase();
    return code.startsWith('zh') ? 'zh' : 'en';
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
