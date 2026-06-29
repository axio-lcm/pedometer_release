import 'dart:io';

import 'package:in_app_review/in_app_review.dart';

import 'package:pedometer/common/config/app_config.dart';

/// 应用商店 / 应用内评价的统一入口（当前仅 iOS）。
///
/// 复用自 al_led_banner 的实现思路，按 pedometer 的 iOS-only 目标裁剪：
/// 五星好评走系统应用内评价弹窗，低分则由调用方引导到站内「建议」反馈页。
abstract final class AppMarketLauncher {
  static final InAppReview _inAppReview = InAppReview.instance;

  /// App Store 数字 ID，用于评价 API 不可用时回退到商店详情页。
  /// 与服务端 Header 使用的 App Store Connect Apple ID 保持一致。
  static const String _appStoreId = Constants.appleId;

  /// 调起 iOS 系统应用内评价弹窗（SKStoreReviewController）。
  ///
  /// 不可用时回退到 App Store 详情页（需配置 [_appStoreId]）。
  /// 注意：系统对弹窗有频控，短期内多次调用可能不展示，属正常现象。
  static Future<void> requestInAppReview() async {
    if (!Platform.isIOS) return;

    if (await _inAppReview.isAvailable()) {
      await _inAppReview.requestReview();
      return;
    }

    await openAppStore();
  }

  /// 跳转 App Store 详情页（用于五星评价引导的回退）。
  /// 仅在配置了 [_appStoreId] 时生效。
  static Future<void> openAppStore() async {
    if (!Platform.isIOS || _appStoreId.isEmpty) return;

    await _inAppReview.openStoreListing(appStoreId: _appStoreId);
  }
}
