import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/common/config/localized_text.dart';
import 'package:pedometer/feature/subscription/config/subscription_config.dart';
import 'package:pedometer/feature/subscription/model/subscription_assets.dart';
import 'package:pedometer/feature/subscription/viewmodel/subscription_view_model.dart';

class SubscriptionPage extends GetView<SubscriptionViewModel> {
  static const String routeName = '/subscription';

  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000F14),
      body: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: const Color(0xFF000F14))),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 310.h,
            child: Image.asset(
              SubscriptionAssets.onboardingPremiumBackground,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          const Positioned.fill(child: _SubscriptionScrim()),
          SafeArea(
            child: Obx(() {
              final plans = controller.plans;
              final selectedIndex = controller.selectedIndex.value;
              final selectedPlan = plans[selectedIndex];
              final weeklyHasIntroOffer =
                  controller.weeklyIntroOfferEligible.value;
              final selectedHasIntroOffer =
                  controller.isEligibleForIntroOffer.value;
              final isIntroOffer =
                  selectedHasIntroOffer &&
                  selectedPlan.kind == SubscriptionPlanKind.weekly;
              final selectedPrice = selectedPlan.fallbackPrice;
              final description = isIntroOffer
                  ? lt(
                      '3-day free trial, then weekly $selectedPrice. Cancel anytime.',
                      '免费试用 3 天，之后每周 $selectedPrice，可随时取消。',
                    )
                  : _descriptionFor(selectedPlan);
              final buttonText = isIntroOffer
                  ? (controller.buttonText.value.isEmpty
                        ? lt('Start Free Trial', '开始免费试用')
                        : controller.buttonText.value)
                  : lt('Subscribe', '订阅');

              return LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 750;
                  final veryCompact = constraints.maxHeight < 700;
                  final topPadding = veryCompact ? 0.0 : (compact ? 6.h : 14.h);
                  final titleGap = veryCompact ? 10.h : (compact ? 14.h : 18.h);
                  final panelGap = veryCompact ? 14.h : (compact ? 18.h : 22.h);
                  final planGap = veryCompact ? 12.h : (compact ? 14.h : 18.h);
                  final descriptionGap = veryCompact ? 12.h : 16.h;
                  final fixedActionHeight = veryCompact ? 112.h : 126.h;

                  return Stack(
                    children: [
                      ListView(
                        padding: EdgeInsets.fromLTRB(
                          23.w,
                          topPadding,
                          23.w,
                          fixedActionHeight + 18.h,
                        ),
                        children: [
                          const Center(child: _PremiumTitle()),
                          SizedBox(height: titleGap),
                          _BenefitPanel(compact: compact),
                          SizedBox(height: panelGap),
                          for (var i = 0; i < plans.length; i++) ...[
                            _SubscriptionPlanTile(
                              plan: plans[i],
                              selected: selectedIndex == i,
                              compact: compact,
                              showFreeTrialBadge:
                                  weeklyHasIntroOffer &&
                                  plans[i].kind == SubscriptionPlanKind.weekly,
                              showBestBadge:
                                  plans[i].kind == SubscriptionPlanKind.yearly,
                              onTap: () => controller.select(i),
                            ),
                            if (i != plans.length - 1)
                              SizedBox(height: planGap),
                          ],
                          SizedBox(height: descriptionGap),
                          Text(
                            description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.84),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              height: 1.22,
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: _FixedSubscriptionAction(
                          compact: compact,
                          buttonText: buttonText,
                          onSubscribe: controller.purchase,
                          onRestore: controller.restore,
                        ),
                      ),
                    ],
                  );
                },
              );
            }),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 8.w, top: 2.h),
                child: IconButton(
                  onPressed: Get.back,
                  color: Colors.white.withValues(alpha: 0.78),
                  icon: Icon(Icons.close, size: 24.w),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _descriptionFor(SubscriptionProductPlan plan) {
    final price = plan.fallbackPrice;
    return switch (plan.kind) {
      SubscriptionPlanKind.yearly => lt(
        '$price per year, cancel anytime.',
        '每年 $price，可随时取消。',
      ),
      SubscriptionPlanKind.weekly => lt(
        '$price per weekly, cancel anytime.',
        '每周 $price，可随时取消。',
      ),
    };
  }
}

class _FixedSubscriptionAction extends StatelessWidget {
  final bool compact;
  final String buttonText;
  final VoidCallback onSubscribe;
  final VoidCallback onRestore;

  const _FixedSubscriptionAction({
    required this.compact,
    required this.buttonText,
    required this.onSubscribe,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF000F14).withValues(alpha: 0),
            const Color(0xFF000F14).withValues(alpha: 0.96),
            const Color(0xFF000F14),
          ],
          stops: const [0, 0.24, 1],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          23.w,
          compact ? 16.h : 22.h,
          23.w,
          compact ? 20.h : 26.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SubscribeButton(text: buttonText, onTap: onSubscribe),
            SizedBox(height: compact ? 14.h : 18.h),
            _LegalLinks(onRestore: onRestore),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionScrim extends StatelessWidget {
  const _SubscriptionScrim();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF000F14).withValues(alpha: 0.16),
            const Color(0xFF000F14).withValues(alpha: 0.92),
            const Color(0xFF000F14),
          ],
          stops: const [0, 0.23, 0.42, 0.70],
        ),
      ),
    );
  }
}

class _BenefitPanel extends StatelessWidget {
  final bool compact;

  const _BenefitPanel({required this.compact});

  @override
  Widget build(BuildContext context) {
    final benefits = [
      (
        SubscriptionAssets.subscriptionGoalsRewards,
        lt('Goals & Rewards', '目标与奖励'),
      ),
      (
        SubscriptionAssets.subscriptionRouteTracking,
        lt('Route Tracking', '路线记录'),
      ),
      (
        SubscriptionAssets.subscriptionHealthDataSync,
        lt('Health Data Sync', '健康数据同步'),
      ),
      (
        SubscriptionAssets.subscriptionWorkoutTrends,
        lt('Workout Trends', '运动趋势'),
      ),
      (
        SubscriptionAssets.subscriptionUnlockPremium,
        lt('Unlock Premium', '解锁高级版'),
      ),
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(
        24.w,
        compact ? 16.h : 20.h,
        22.w,
        compact ? 16.h : 20.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF03151B).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < benefits.length; i++) ...[
            _BenefitRow(icon: benefits[i].$1, text: benefits[i].$2),
            if (i != benefits.length - 1)
              SizedBox(height: compact ? 16.h : 20.h),
          ],
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String icon;
  final String text;

  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(icon, width: 28.w, height: 28.w),
        SizedBox(width: 14.w),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Icon(Icons.check_circle, color: AppColors.brandGreen, size: 18.w),
      ],
    );
  }
}

class _SubscriptionPlanTile extends StatelessWidget {
  final SubscriptionProductPlan plan;
  final bool selected;
  final bool compact;
  final bool showFreeTrialBadge;
  final bool showBestBadge;
  final VoidCallback onTap;

  const _SubscriptionPlanTile({
    required this.plan,
    required this.selected,
    required this.compact,
    required this.showFreeTrialBadge,
    required this.showBestBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badgeText = showFreeTrialBadge
        ? lt('3 Days Free Trial', '免费试用 3 天')
        : showBestBadge
        ? 'BEST'
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: compact ? 62.h : 66.h,
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            decoration: BoxDecoration(
              color: const Color(0xFF03151B).withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: selected
                    ? AppColors.brandGreen
                    : Colors.white.withValues(alpha: 0.04),
                width: selected ? 2.r : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _titleFor(plan),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Text(
                  plan.fallbackPrice,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          if (badgeText != null)
            Positioned(
              right: 0,
              top: 0,
              child: _PlanBadge(text: badgeText, wide: showFreeTrialBadge),
            ),
        ],
      ),
    );
  }

  String _titleFor(SubscriptionProductPlan plan) {
    return switch (plan.kind) {
      SubscriptionPlanKind.weekly => lt('Weekly Plan', '周计划'),
      SubscriptionPlanKind.yearly => lt('Annual Plan', '年度计划'),
    };
  }
}

class _PlanBadge extends StatelessWidget {
  final String text;
  final bool wide;

  const _PlanBadge({required this.text, required this.wide});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18.h,
      width: wide ? 126.w : 66.w,
      decoration: BoxDecoration(
        color: wide ? AppColors.brandGreen : const Color(0xFFFFEB25),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20.r),
          bottomLeft: Radius.circular(18.r),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: const Color(0xFF00130A),
          fontSize: wide ? 12.sp : 11.sp,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _SubscribeButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _SubscribeButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.full),
          gradient: LinearGradient(
            colors: [AppColors.brandGreenLight, AppColors.brandGreen],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 52.w),
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF00130A),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
            Positioned(
              right: 14.w,
              child: Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF18320E).withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: 20.w,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalLinks extends StatelessWidget {
  final VoidCallback onRestore;

  const _LegalLinks({required this.onRestore});

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.72),
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
        children: [
          const TextSpan(text: 'Privacy Policy'),
          const TextSpan(text: '  |  '),
          TextSpan(text: lt('Terms', '用户协议')),
          const TextSpan(text: '  |  '),
          TextSpan(text: lt('Subscription', '订阅')),
          const TextSpan(text: '  |  '),
          TextSpan(
            text: lt('Restore', '恢复购买'),
            recognizer: TapGestureRecognizer()..onTap = onRestore,
          ),
        ],
      ),
    );
  }
}

class _PremiumTitle extends StatelessWidget {
  const _PremiumTitle();

  static const _angle = -0.21; // ~-12°

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: AppColors.brandGreenLight,
      fontSize: 36.sp,
      fontWeight: FontWeight.w900,
      height: 1.15,
    );
    return Transform.rotate(
      angle: _angle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            offset: Offset(-30.w, 0),
            child: Text(lt('Upgrade', 'Upgrade'), style: style),
          ),
          Padding(
            padding: EdgeInsets.only(left: 16.w),
            child: Text(lt('Premium', 'Premium'), style: style),
          ),
        ],
      ),
    );
  }
}
