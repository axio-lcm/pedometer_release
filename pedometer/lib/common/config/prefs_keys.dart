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
  static const String subscriptionProductDisplayCache =
      'subscriptionProductDisplayCache';

  /// 身体数据
  static const String bodyHeight = 'bodyHeight';
  static const String bodyWeight = 'bodyWeight';
  static const String bodyAge = 'bodyAge';

  /// 每日步数目标（编辑目标页设置，首页圆环 / 日周月目标统一读取）。
  static const String dailyStepGoal = 'dailyStepGoal';

  /// 户外 GPS 自校准步长（米），安卓室内运动按步数估算距离时使用。
  static const String calibratedStepLength = 'calibratedStepLength';

  /// 运动音乐已导入曲目列表（JSON：文件名 + 展示名，文件在文档目录副本）。
  static const String workoutMusicTracks = 'workoutMusicTracks';

  /// 运动音乐上次播放到的曲目下标（冷启动恢复后从该曲目继续）。
  static const String workoutMusicCurrentIndex = 'workoutMusicCurrentIndex';

  static const String attributionJson = 'attributionJson';
  static const String campaignId = 'campaignId';
  static const String isUploadedASAData = 'isUploadedASAData';
  static const String isUploadedFirstSubsData = 'isUploadedFirstSubsData';
}
