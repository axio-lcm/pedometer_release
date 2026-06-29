import 'dart:io';

import 'package:in_app_review/in_app_review.dart';

import 'package:pedometer/common/config/app_config.dart';

/// 应用商店评价入口（当前仅 iOS）。
abstract final class AppMarketLauncher {
  static final InAppReview _inAppReview = InAppReview.instance;

  /// App Store 数字 ID，用于评价 API 不可用时回退到商店详情页。
  /// 与服务端 Header 使用的 App Store Connect Apple ID 保持一致。
  static const String _appStoreId = Constants.appleId;

  /// 点击「评价」时直接跳转 App Store 商店评价入口。
  static Future<void> openAppStoreReview() => openAppStore();

  /// 跳转 App Store 详情页。
  /// 仅在配置了 [_appStoreId] 时生效。
  static Future<void> openAppStore() async {
    if (!Platform.isIOS || _appStoreId.isEmpty) return;

    await _inAppReview.openStoreListing(appStoreId: _appStoreId);
  }
}
