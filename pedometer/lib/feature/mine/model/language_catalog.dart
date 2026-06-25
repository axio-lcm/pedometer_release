import 'package:flutter/widgets.dart';

/// 语言设置页的单个选项。
class LanguageOption {
  const LanguageOption({
    required this.code,
    required this.title,
    required this.subtitle,
  });

  /// 存储码：`sys`（跟随系统）或资源码（如 `en` / `zh_Hans` / `ja`）。
  final String code;

  /// 主标题：语言的母语名（`sys` 行由页面用本地化文案填充）。
  final String title;

  /// 副标题兜底文本；实际展示优先使用当前语言的资源翻译。
  final String subtitle;
}

/// 受支持语言目录：母语名、系统解析、Locale 映射集中维护。
abstract final class LanguageCatalog {
  /// 18 种实际语言。语言选择页在其前再加「跟随系统」行。
  static const languages = <LanguageOption>[
    LanguageOption(code: 'en', title: 'English', subtitle: 'English'),
    LanguageOption(
      code: 'zh_Hans',
      title: '中文(简体)',
      subtitle: 'Chinese (Simplified)',
    ),
    LanguageOption(
      code: 'zh_Hant',
      title: '中文(繁體)',
      subtitle: 'Chinese (Traditional)',
    ),
    LanguageOption(code: 'ar', title: 'العربية', subtitle: 'Arabic'),
    LanguageOption(code: 'de', title: 'Deutsch', subtitle: 'German'),
    LanguageOption(code: 'es', title: 'Español', subtitle: 'Spanish'),
    LanguageOption(code: 'fr', title: 'Français', subtitle: 'French'),
    LanguageOption(code: 'id', title: 'Indonesia', subtitle: 'Indonesian'),
    LanguageOption(code: 'it', title: 'Italiano', subtitle: 'Italian'),
    LanguageOption(code: 'ja', title: '日本語', subtitle: 'Japanese'),
    LanguageOption(code: 'kk', title: 'Қазақша', subtitle: 'Kazakh'),
    LanguageOption(code: 'ko', title: '한국어', subtitle: 'Korean'),
    LanguageOption(code: 'pl', title: 'Polski', subtitle: 'Polish'),
    LanguageOption(code: 'pt', title: 'Português', subtitle: 'Portuguese'),
    LanguageOption(code: 'ru', title: 'Русский', subtitle: 'Russian'),
    LanguageOption(code: 'th', title: 'ภาษาไทย', subtitle: 'Thai'),
    LanguageOption(code: 'tr', title: 'Türkçe', subtitle: 'Turkish'),
    LanguageOption(code: 'vi', title: 'Tiếng Việt', subtitle: 'Vietnamese'),
  ];

  /// ResourceLoader 选择译文文件用的资源码（永不为 `sys`）。
  static const supportedResourceCodes = <String>{
    'en',
    'zh_Hans',
    'zh_Hant',
    'ar',
    'de',
    'es',
    'fr',
    'id',
    'it',
    'ja',
    'kk',
    'ko',
    'pl',
    'pt',
    'ru',
    'th',
    'tr',
    'vi',
  };

  /// 跟随系统时可被识别的系统语言码（zh 再细分简繁）。
  static const supportedSystemLanguageCodes = <String>{
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'id',
    'it',
    'ja',
    'kk',
    'ko',
    'pl',
    'pt',
    'ru',
    'th',
    'tr',
    'vi',
    'zh',
  };

  /// 提供给 GetMaterialApp 的 supportedLocales。
  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW'),
    Locale('ar'),
    Locale('de'),
    Locale('es'),
    Locale('fr'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('kk'),
    Locale('ko'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('th'),
    Locale('tr'),
    Locale('vi'),
  ];

  /// 资源码 → Locale。
  static Locale localeForCode(String code) {
    switch (code) {
      case 'zh_Hans':
        return const Locale('zh', 'CN');
      case 'zh_Hant':
        return const Locale('zh', 'TW');
      default:
        return Locale(code);
    }
  }

  /// 把系统 Locale 解析为受支持的资源码，不支持则回退 `en`。
  static String resolveSystem(Locale system) {
    final lang = system.languageCode;
    if (lang == 'zh') {
      if (system.scriptCode == 'Hant') return 'zh_Hant';
      final region = system.countryCode;
      if (region == 'TW' || region == 'HK' || region == 'MO') return 'zh_Hant';
      return 'zh_Hans';
    }
    if (supportedSystemLanguageCodes.contains(lang)) return lang;
    return 'en';
  }

  /// 兼容旧值 / 任意输入 → 受支持资源码。
  static String normalizeCode(String code) {
    return tryNormalizeCode(code) ?? 'en';
  }

  /// 兼容旧值 / 任意输入 → 受支持资源码；未知输入返回 null。
  static String? tryNormalizeCode(String code) {
    final value = code.trim();
    if (supportedResourceCodes.contains(value)) return value;
    final lower = value.toLowerCase();
    if (lower.startsWith('zh')) {
      final isHant =
          lower.contains('hant') ||
          lower.contains('tw') ||
          lower.contains('hk') ||
          lower.contains('mo');
      return isHant ? 'zh_Hant' : 'zh_Hans';
    }
    final base = lower.split(RegExp('[_-]')).first;
    if (supportedResourceCodes.contains(base)) return base;
    return null;
  }
}
