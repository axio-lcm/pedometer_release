/// Apple 内购订阅配置。
///
/// 商品 ID 对齐线上 Pedometer App 订阅产品表：
/// - 引导页周订阅：pedometer_weekly_pro，$9.99，免费 3 天，韩国无优惠
/// - 应用内周订阅：pedometer_weekly_pro_ia，$9.99，免费 3 天，韩国无优惠
/// - 应用内年订阅：pedometer_yearly_pro，$39.99，韩国无优惠
abstract final class SubscriptionConfig {
  static const String onboardingWeeklyId = 'pedometer_weekly_pro';
  static const String inAppWeeklyId = 'pedometer_weekly_pro_ia';
  static const String inAppYearlyId = 'pedometer_yearly_pro';

  static const List<String> subscriptionProductIds = [
    onboardingWeeklyId,
    inAppWeeklyId,
    inAppYearlyId,
  ];

  static bool hasIntroOfferLoading(String productId) =>
      productId == onboardingWeeklyId || productId == inAppWeeklyId;

  static const List<String> oneTimeProductIds = [];
}

enum SubscriptionSource {
  startLoading('start_loading_page', '启动加载页'),
  onboarding('guide_iap_page', '引导订阅页'),
  subscription('subscription_page', '应用内订阅页'),
  mine('mine_page', '我的页');

  final String code;
  final String text;

  const SubscriptionSource(this.code, this.text);
}

enum SubscriptionPlanKind { weekly, yearly }

class SubscriptionProductPlan {
  final SubscriptionPlanKind kind;
  final String productId;
  final String fallbackTitle;
  final String fallbackSubtitle;
  final String fallbackPrice;

  const SubscriptionProductPlan({
    required this.kind,
    required this.productId,
    required this.fallbackTitle,
    required this.fallbackSubtitle,
    required this.fallbackPrice,
  });
}
