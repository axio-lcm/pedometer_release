import 'package:flutter/material.dart';
import 'package:pedometer/common/config/resource_loader.dart';

/// 全局颜色令牌（common/resources/color.json）
class AppColors {
  AppColors._();

  static Color get bgPrimary => ResourceLoader.color('common', 'bgPrimary', fallback: const Color(0xFF00050A));
  static Color get bgRadialBlue => ResourceLoader.color('common', 'bgRadialBlue', fallback: const Color(0xFF03131C));
  static Color get bgRadialGreen => ResourceLoader.color('common', 'bgRadialGreen', fallback: const Color(0xFF022414));
  static Color get surfaceCardTop => ResourceLoader.color('common', 'surfaceCardTop', fallback: const Color(0xD10C262E));
  static Color get surfaceCardBottom => ResourceLoader.color('common', 'surfaceCardBottom', fallback: const Color(0xE1020B10));
  static Color get surfaceIcon => ResourceLoader.color('common', 'surfaceIcon', fallback: const Color(0xD1081F26));
  static Color get strokeCard => ResourceLoader.color('common', 'strokeCard', fallback: const Color(0x1FFFFFFF));
  static Color get strokeGreen => ResourceLoader.color('common', 'strokeGreen', fallback: const Color(0x8C26FF52));
  static Color get divider => ResourceLoader.color('common', 'divider', fallback: const Color(0x1AFFFFFF));
  static Color get gridLine => ResourceLoader.color('common', 'gridLine', fallback: const Color(0x1FFFFFFF));
  static Color get brandGreen => ResourceLoader.color('common', 'brandGreen', fallback: const Color(0xFF24F04E));
  static Color get brandGreenLight => ResourceLoader.color('common', 'brandGreenLight', fallback: const Color(0xFF6CFF3D));
  static Color get brandGreenMid => ResourceLoader.color('common', 'brandGreenMid', fallback: const Color(0xFF00B956));
  static Color get brandGreenShade => ResourceLoader.color('common', 'brandGreenShade', fallback: const Color(0xFF0A7739));
  static Color get brandGreenDark => ResourceLoader.color('common', 'brandGreenDark', fallback: const Color(0xFF063F22));
  static Color get brandLime => ResourceLoader.color('common', 'brandLime', fallback: const Color(0xFFB7FF24));
  static Color get pillGreenStart => ResourceLoader.color('common', 'pillGreenStart', fallback: const Color(0xFF0C682D));
  static Color get pillGreenEnd => ResourceLoader.color('common', 'pillGreenEnd', fallback: const Color(0xFF0E8E37));
  static Color get surfaceCapsule => ResourceLoader.color('common', 'surfaceCapsule', fallback: const Color(0xDB030F14));
  static Color get tabInactive => ResourceLoader.color('common', 'tabInactive', fallback: const Color(0xB3A5A5A5));
  static Color get accentOrange => ResourceLoader.color('common', 'accentOrange', fallback: const Color(0xFFFF9F12));
  static Color get accentCyan => ResourceLoader.color('common', 'accentCyan', fallback: const Color(0xFF0CD9FF));
  static Color get accentPurple => ResourceLoader.color('common', 'accentPurple', fallback: const Color(0xFF7A3DFF));
  static Color get accentPink => ResourceLoader.color('common', 'accentPink', fallback: const Color(0xFFFF4770));
  static Color get statusSuccess => ResourceLoader.color('common', 'statusSuccess', fallback: const Color(0xFF43F56B));
  static Color get textPrimary => ResourceLoader.color('common', 'textPrimary', fallback: const Color(0xFFF7F8F4));
  static Color get textSecondary => ResourceLoader.color('common', 'textSecondary', fallback: const Color(0xFFC9C4BA));
  static Color get textTertiary => ResourceLoader.color('common', 'textTertiary', fallback: const Color(0xFF8A918E));
  static Color get textDisabled => ResourceLoader.color('common', 'textDisabled', fallback: const Color(0xFF5E6663));
  static Color get white => ResourceLoader.color('common', 'white', fallback: Colors.white);
}

/// 全局文案令牌（common/resources/string.json）
class AppStrings {
  AppStrings._();

  static String get appName => ResourceLoader.string('common', 'app_name', fallback: 'Pedometer');
  static String get loading => ResourceLoader.string('common', 'loading', fallback: '加载中...');
  static String get error => ResourceLoader.string('common', 'error', fallback: '加载失败');

  static String comingSoon(String label) {
    final tpl = ResourceLoader.string('common', 'coming_soon', fallback: '{{label}}：敬请期待');
    return tpl.replaceAll('{{label}}', label);
  }
}
