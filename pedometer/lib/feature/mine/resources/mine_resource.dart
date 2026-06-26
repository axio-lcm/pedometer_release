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
  static String get bmiLow => _string('bmi_low', MineText.bmiLow);
  static String get bmiHigh => _string('bmi_high', MineText.bmiHigh);
  static String get bmiObese => _string('bmi_obese', MineText.bmiObese);
  static String get age => _string('age', MineText.age);
  static String get ageUnit => _string('age_unit', MineText.ageUnit);
  static String get bodyData => _string('body_data', MineText.bodyData);
  static String get editBodyData =>
      _string('edit_body_data', MineText.editBodyData);
  static String get subscribeTitle =>
      _string('subscribe_title', MineText.subscribeTitle);
  static String get subscribeSubtitle =>
      _string('subscribe_subtitle', MineText.subscribeSubtitle);
  static String get themeSetting =>
      _string('theme_setting', MineText.themeSetting);
  static String get language => _string('language', MineText.language);
  static String get languageTitle =>
      _string('language_title', MineText.languageTitle);
  static String get languageEnglish =>
      _string('language_english', MineText.languageEnglish);
  static String get languageEnglishSubtitle =>
      _string('language_english_subtitle', MineText.languageEnglishSubtitle);
  static String get languageChinese =>
      _string('language_chinese', MineText.languageChinese);
  static String get languageChineseSubtitle =>
      _string('language_chinese_subtitle', MineText.languageChineseSubtitle);
  static String get followSystem =>
      _string('follow_system', MineText.followSystem);
  static String get followSystemSubtitle =>
      _string('follow_system_subtitle', MineText.followSystemSubtitle);
  static String languageOptionSubtitle(String code, String fallback) {
    final key = 'language_option_${code.toLowerCase().replaceAll('-', '_')}';
    return _string(key, fallback);
  }

  static String get shareApp => _string('share_app', MineText.shareApp);
  static String get shareAppContent =>
      _string('share_app_content', MineText.shareAppContent);
  static String get shareAppSubject =>
      _string('share_app_subject', MineText.shareAppSubject);
  static String get rateUs => _string('rate_us', MineText.rateUs);
  static String get suggestion => _string('suggestion', MineText.suggestion);
  static String get rateDialogTitle =>
      _string('rate_dialog_title', MineText.rateDialogTitle);
  static String get rateDialogMessage =>
      _string('rate_dialog_message', MineText.rateDialogMessage);
  static String get rateDialogSubmit =>
      _string('rate_dialog_submit', MineText.rateDialogSubmit);
  static String get suggestionTitle =>
      _string('suggestion_title', MineText.suggestionTitle);
  static String get suggestionEmailLabel =>
      _string('suggestion_email_label', MineText.suggestionEmailLabel);
  static String get suggestionEmailHint =>
      _string('suggestion_email_hint', MineText.suggestionEmailHint);
  static String get suggestionSubjectLabel =>
      _string('suggestion_subject_label', MineText.suggestionSubjectLabel);
  static String get suggestionSubjectHint =>
      _string('suggestion_subject_hint', MineText.suggestionSubjectHint);
  static String get suggestionMessageLabel =>
      _string('suggestion_message_label', MineText.suggestionMessageLabel);
  static String get suggestionMessageHint =>
      _string('suggestion_message_hint', MineText.suggestionMessageHint);
  static String get suggestionSend =>
      _string('suggestion_send', MineText.suggestionSend);
  static String get suggestionSuccess =>
      _string('suggestion_success', MineText.suggestionSuccess);
  static String get suggestionFieldRequired =>
      _string('suggestion_field_required', MineText.suggestionFieldRequired);
  static String get suggestionInvalidEmail =>
      _string('suggestion_invalid_email', MineText.suggestionInvalidEmail);
  static String get suggestionSendFailed =>
      _string('suggestion_send_failed', MineText.suggestionSendFailed);
  static String get userAgreement =>
      _string('user_agreement', MineText.userAgreement);
  static String get privacyPolicy =>
      _string('privacy_policy', MineText.privacyPolicy);
  static String get aboutUs => _string('about_us', MineText.aboutUs);
  static String get version => _string('version', MineText.version);

  static String _string(String key, String fallback) {
    return ResourceLoader.string('mine', key, fallback: fallback);
  }

  static const membershipCrownIcon = 'assets/membership_crown.svg';
  static const membershipArrowIcon = 'assets/membership_arrow.svg';
  static const rateIllustration = 'assets/rate_illustration.png';
  static const rateStarFilled = 'assets/rate_star_filled.png';
  static const rateStarEmpty = 'assets/rate_star_empty.png';
}

/// 我的页模块 const 文案。供 const mock / 默认数据使用；动态读取请走 [MineResource]。
class MineText {
  MineText._();

  static const height = 'Height';
  static const heightUnit = 'cm';
  static const weight = 'Weight';
  static const weightUnit = 'kg';
  static const bmi = 'BMI';
  static const bmiNormal = 'Normal';
  static const bmiLow = 'Low';
  static const bmiHigh = 'High';
  static const bmiObese = 'Obese';
  static const age = 'Age';
  static const ageUnit = 'yrs';
  static const bodyData = 'Body Data';
  static const editBodyData = 'Edit';
  static const subscribeTitle = 'Membership';
  static const subscribeSubtitle = 'Unlock all premium features';
  static const themeSetting = 'Theme';
  static const language = 'Language';
  static const languageTitle = 'Language';
  static const languageEnglish = 'English';
  static const languageEnglishSubtitle = 'Use English by default';
  static const languageChinese = '简体中文';
  static const languageChineseSubtitle = '使用中文显示';
  static const followSystem = 'Follow system';
  static const followSystemSubtitle = 'Use your device language';
  static const shareApp = 'Share App';
  static const shareAppSubject = 'A useful pedometer app';
  static const shareAppContent =
      'I am using this pedometer app to track steps and workouts every day. Join me!';
  static const rateUs = 'Rate Us';
  static const suggestion = 'Suggestion';
  static const rateDialogTitle = 'Enjoying the app?';
  static const rateDialogMessage =
      'Your rating is our biggest motivation. Tap the stars to rate us.';
  static const rateDialogSubmit = 'Submit';
  static const suggestionTitle = 'Suggestion';
  static const suggestionEmailLabel = 'Email';
  static const suggestionEmailHint = 'Enter your email';
  static const suggestionSubjectLabel = 'Subject';
  static const suggestionSubjectHint = 'Enter a subject';
  static const suggestionMessageLabel = 'Details';
  static const suggestionMessageHint =
      'Describe your suggestion or the issue you ran into';
  static const suggestionSend = 'Send';
  static const suggestionSuccess = 'Thanks for your feedback!';
  static const suggestionFieldRequired = 'Please fill in all fields';
  static const suggestionInvalidEmail = 'Please enter a valid email';
  static const suggestionSendFailed = 'Failed to send, please try again';
  static const userAgreement = 'User Agreement';
  static const privacyPolicy = 'Privacy Policy';
  static const aboutUs = 'About Us';
  static const version = 'Version';
}
