import 'package:pedometer/common/config/resource_loader.dart';

/// 订阅模块静态文案资源。
class SubscriptionResource {
  SubscriptionResource._();

  static String get startFreeTrial =>
      _string('start_free_trial', SubscriptionText.startFreeTrial);
  static String get subscribe =>
      _string('subscribe', SubscriptionText.subscribe);
  static String get weeklyPlan =>
      _string('weekly_plan', SubscriptionText.weeklyPlan);
  static String get weeklyTrialSubtitle =>
      _string('weekly_trial_subtitle', SubscriptionText.weeklyTrialSubtitle);
  static String get annualPlan =>
      _string('annual_plan', SubscriptionText.annualPlan);
  static String get annualBestValue =>
      _string('annual_best_value', SubscriptionText.annualBestValue);
  static String get goalsRewards =>
      _string('goals_rewards', SubscriptionText.goalsRewards);
  static String get routeTracking =>
      _string('route_tracking', SubscriptionText.routeTracking);
  static String get healthDataSync =>
      _string('health_data_sync', SubscriptionText.healthDataSync);
  static String get workoutTrends =>
      _string('workout_trends', SubscriptionText.workoutTrends);
  static String get unlockPremium =>
      _string('unlock_premium', SubscriptionText.unlockPremium);
  static String get threeDaysFreeTrial =>
      _string('three_days_free_trial', SubscriptionText.threeDaysFreeTrial);
  static String get bestBadge =>
      _string('best_badge', SubscriptionText.bestBadge);
  static String get privacyPolicy =>
      _string('privacy_policy', SubscriptionText.privacyPolicy);
  static String get terms => _string('terms', SubscriptionText.terms);
  static String get subscription =>
      _string('subscription', SubscriptionText.subscription);
  static String get restore => _string('restore', SubscriptionText.restore);
  static String get upgrade => _string('upgrade', SubscriptionText.upgrade);
  static String get premium => _string('premium', SubscriptionText.premium);

  static String introOfferDescription(String price) {
    return _template(
      'intro_offer_description',
      SubscriptionText.introOfferDescription,
      {'price': price},
    );
  }

  static String yearlyDescription(String price) {
    return _template('yearly_description', SubscriptionText.yearlyDescription, {
      'price': price,
    });
  }

  static String weeklyDescription(String price) {
    return _template('weekly_description', SubscriptionText.weeklyDescription, {
      'price': price,
    });
  }

  static String _string(String key, String fallback) {
    return ResourceLoader.string('subscription', key, fallback: fallback);
  }

  static String _template(
    String key,
    String fallback,
    Map<String, String> values,
  ) {
    final template = _string(key, fallback);
    return values.entries.fold<String>(
      template,
      (value, entry) => value.replaceAll('{{${entry.key}}}', entry.value),
    );
  }
}

/// 订阅模块默认英文文案。动态读取请走 [SubscriptionResource]。
class SubscriptionText {
  SubscriptionText._();

  static const startFreeTrial = 'Start Free Trial';
  static const subscribe = 'Subscribe';
  static const weeklyPlan = 'Weekly Plan';
  static const weeklyTrialSubtitle = '3-day free trial';
  static const annualPlan = 'Annual Plan';
  static const annualBestValue = 'Best value';
  static const goalsRewards = 'Goals & Rewards';
  static const routeTracking = 'Route Tracking';
  static const healthDataSync = 'Health Data Sync';
  static const workoutTrends = 'Workout Trends';
  static const unlockPremium = 'Unlock Premium';
  static const threeDaysFreeTrial = '3 Days Free Trial';
  static const bestBadge = 'BEST';
  static const privacyPolicy = 'Privacy Policy';
  static const terms = 'Terms';
  static const subscription = 'Subscription';
  static const restore = 'Restore';
  static const upgrade = 'Upgrade';
  static const premium = 'Premium';
  static const introOfferDescription =
      '3-day free trial, then weekly {{price}}. Cancel anytime.';
  static const yearlyDescription = '{{price}} per year, cancel anytime.';
  static const weeklyDescription = '{{price}} per weekly, cancel anytime.';
}
