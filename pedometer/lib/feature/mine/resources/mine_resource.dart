import 'package:flutter/material.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/resource_loader.dart';

/// 我的页模块静态资源（对齐 HomeResource / WorkoutResource 写法）。
class MineResource {
  MineResource._();

  static Color get background => ResourceLoader.color(
    'mine',
    'mine_bg',
    fallbackModule: 'common',
    fallback: AppColors.bgPrimary,
  );

  static String get height => _string('height', MineText.height);
  static String get heightUnit => _string('height_unit', MineText.heightUnit);
  static String get weight => _string('weight', MineText.weight);
  static String get weightUnit => _string('weight_unit', MineText.weightUnit);
  static String get bmi => _string('bmi', MineText.bmi);
  static String get bmiNormal => _string('bmi_normal', MineText.bmiNormal);
  static String get age => _string('age', MineText.age);
  static String get ageUnit => _string('age_unit', MineText.ageUnit);
  static String get themeSetting =>
      _string('theme_setting', MineText.themeSetting);
  static String get language => _string('language', MineText.language);
  static String get shareApp => _string('share_app', MineText.shareApp);
  static String get shareAppContent =>
      _string('share_app_content', MineText.shareAppContent);
  static String get shareAppSubject =>
      _string('share_app_subject', MineText.shareAppSubject);
  static String get rateUs => _string('rate_us', MineText.rateUs);
  static String get userAgreement =>
      _string('user_agreement', MineText.userAgreement);
  static String get privacyPolicy =>
      _string('privacy_policy', MineText.privacyPolicy);
  static String get aboutUs => _string('about_us', MineText.aboutUs);
  static String get version => _string('version', MineText.version);

  static String _string(String key, String fallback) {
    return ResourceLoader.string('mine', key, fallback: fallback);
  }
}

/// 我的页模块 const 文案。供 const mock / 默认数据使用；动态读取请走 [MineResource]。
class MineText {
  MineText._();

  static const height = '身高';
  static const heightUnit = 'cm';
  static const weight = '体重';
  static const weightUnit = 'kg';
  static const bmi = 'BMI';
  static const bmiNormal = '正常';
  static const age = '年龄';
  static const ageUnit = '岁';
  static const themeSetting = '主题设置';
  static const language = '语言';
  static const shareApp = '分享应用';
  static const shareAppSubject = '推荐一款好用的计步运动 App';  //这个是应用分享的宣传语
  static const shareAppContent =
      '我正在用这款计步运动 App 记录每天的步数和锻炼，一起来打卡运动吧！';
  static const rateUs = '给我们评分';
  static const userAgreement = '用户协议';
  static const privacyPolicy = '隐私政策';
  static const aboutUs = '关于我们';
  static const version = '版本号';
}
