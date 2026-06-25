import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer/common/config/resource_loader.dart';

void main() {
  testWidgets('falls back to system language for untranslated placeholders', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale(
      'zh',
      'CN',
    );
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);

    await ResourceLoader.init(languageCode: 'ar');

    expect(ResourceLoader.languageCode, 'ar');
    expect(ResourceLoader.systemFallbackLanguageCode, 'zh_Hans');
    expect(ResourceLoader.string('common', 'lt_sync_history'), '同步历史');

    await ResourceLoader.setLanguageCode('id');
    expect(ResourceLoader.string('mine', 'edit_body_data'), '编辑');

    await ResourceLoader.setLanguageCode('pl');
    expect(ResourceLoader.string('workout', 'tracking_start_hint'), '开始');

    await ResourceLoader.setLanguageCode('de');
    expect(ResourceLoader.string('home', 'trend'), '趋势');
  });
}
