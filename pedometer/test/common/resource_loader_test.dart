import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer/common/config/resource_loader.dart';

void main() {
  // 场景：手机系统语言是中文，App 切到其它语言。
  // 已翻译的 key 显示目标语言；译文恰好等于英文（会被占位剔除）的 key
  // 必须回退到「英文」，而不是回退到中文系统语言（否则会串中文）。
  testWidgets(
    'English-identical keys fall back to English, not the Chinese system language',
    (tester) async {
      tester.binding.platformDispatcher.localeTestValue = const Locale(
        'zh',
        'CN',
      );
      addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);

      await ResourceLoader.init(languageCode: 'fr');
      expect(ResourceLoader.systemFallbackLanguageCode, 'zh_Hans');

      // 回归：这几个 key 的法语译文与英文字面相同，曾被误当占位剔除而串中文。
      // 现应回退到英文（与法语译文一致），绝不能是中文。
      expect(ResourceLoader.string('workout', 'achievement_badge'), 'Badges');
      expect(ResourceLoader.string('workout', 'badge_200km'), '200 km');
      expect(ResourceLoader.string('workout', 'badge_500km'), '500 km');

      // 已正常翻译的 key 仍显示目标语言（法语）。
      expect(ResourceLoader.string('home', 'trend'), 'Tendance');

      // pl 的 tracking_start_hint 与英文同为 'Start'：回退英文而非中文「开始」。
      await ResourceLoader.setLanguageCode('pl');
      expect(ResourceLoader.string('workout', 'tracking_start_hint'), 'Start');

      // de 的 edit_body_data 不会受影响，但确认目标语言优先生效。
      await ResourceLoader.setLanguageCode('id');
      expect(ResourceLoader.string('mine', 'edit_body_data'), 'Ubah');
    },
  );
}
