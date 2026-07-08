import 'dart:io';

import 'package:in_app_review/in_app_review.dart';

import 'package:pedometer/common/config/app_config.dart';

/// 应用商店评价入口。
abstract final class AppMarketLauncher {
  static final InAppReview _inAppReview = InAppReview.instance;

  /// App Store 数字 ID，用于 iOS 跳转商店评价页。
  /// 与服务端 Header 使用的 App Store Connect Apple ID 保持一致。
  static const String _appStoreId = Constants.appleId;

  /// 点击「评价」时按系统跳转对应应用商店评价入口。
  ///
  /// Android 由 in_app_review 原生侧使用当前 applicationId 打开 Google Play。
  /// iOS 需要传入 App Store 数字 ID 才能定位到当前应用。
  static Future<void> openStoreReview() async {
    if (Platform.isAndroid) {
      await _inAppReview.openStoreListing();
      return;
    }

    if (Platform.isIOS) {
      await openAppStore();
    }
  }

  /// 兼容旧调用名。
  static Future<void> openAppStoreReview() => openStoreReview();

  /// 跳转 App Store 详情页。
  /// 仅在配置了 [_appStoreId] 时生效。
  static Future<void> openAppStore() async {
    if (!Platform.isIOS || _appStoreId.isEmpty) return;

    await _inAppReview.openStoreListing(appStoreId: _appStoreId);
  }
}
