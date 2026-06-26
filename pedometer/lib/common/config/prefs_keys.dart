/// 跨模块使用的 SharedPreferences key 常量。
abstract final class PrefsKeys {
  /// 设备维度的匿名用户标识（uuid，首启生成后持久化）。
  static const String deviceUserId = 'deviceUserId';

  /// 是否第一次启动，用于 ASA 首启归因与引导流程。
  static const String isFirstLaunch = 'isFirstLaunch';

  /// 本地会员状态与订阅交易缓存。
  static const String isVip = 'isVip';
  static const String vipProductId = 'vipProductId';
  static const String vipExpireTime = 'vipExpireTime';
  static const String lastPurchaseTime = 'lastPurchaseTime';
  static const String isTrialCanceled = 'isTrialCanceled';
  static const String isShowedSubOnThisSession = 'isShowedSubOnThisSession';
  static const String currentBuyProductId = 'currentBuyProductId';
  static const String sdOriginTransactionId = 'sdOriginTransactionId';
  static const String sdOriginalPurchaseDateMs = 'sdOriginalPurchaseDateMs';
  /// 身体数据
  static const String bodyHeight = 'bodyHeight';
  static const String bodyWeight = 'bodyWeight';
  static const String bodyAge = 'bodyAge';

  /// 每日步数目标（编辑目标页设置，首页圆环 / 日周月目标统一读取）。
  static const String dailyStepGoal = 'dailyStepGoal';

  static const String attributionJson = 'attributionJson';
  static const String campaignId = 'campaignId';
  static const String isUploadedASAData = 'isUploadedASAData';
  static const String isUploadedFirstSubsData = 'isUploadedFirstSubsData';
}
