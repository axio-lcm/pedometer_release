import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/common/config/localized_text.dart';
import 'package:pedometer/feature/legal/legal_navigation.dart';
import 'package:pedometer/feature/subscription/components/free_trial_switch_intro_overlay.dart';
import 'package:pedometer/feature/subscription/model/subscription_assets.dart';
import 'package:pedometer/feature/subscription/viewmodel/onboarding_view_model.dart';

class OnboardingPage extends GetView<OnboardingViewModel> {
  static const String routeName = '/onboarding';

  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => Stack(
          children: [
            controller.isGuidePage
                ? _GuideOnboardingBody(controller: controller)
                : _SubscriptionOnboardingBody(controller: controller),
            Positioned.fill(
              child: FreeTrialSwitchIntroOverlay(
                visible: controller.showFreeTrialSwitchIntro.value,
                onFinished: controller.hideFreeTrialSwitchIntro,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideOnboardingBody extends StatelessWidget {
  final OnboardingViewModel controller;

  const _GuideOnboardingBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: ColoredBox(
        color: const Color(0xFF00050A),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: SizedBox.expand(
                  key: ValueKey(controller.index.value),
                  child: Image.asset(
                    OnboardingViewModel.images[controller.index.value],
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            const Positioned.fill(child: _GuideScrim()),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24.w,
                    0,
                    24.w,
                    AppSpacing.xl + 36.h,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Transform.translate(
                        offset: Offset(0, 20.h),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _GuideTitle(
                              title: controller.titles[controller.index.value],
                            ),
                            SizedBox(height: 22.h),
                            Text(
                              controller.subtitles[controller.index.value],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.94),
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                height: 1.18,
                              ),
                            ),
                            SizedBox(height: 26.h),
                            Transform.translate(
                              offset: Offset(0, -10.h),
                              child: _PageDots(
                                count: OnboardingViewModel.guidePageCount,
                                index: controller.index.value,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 28.h),
                      _GuideContinueButton(
                        text: lt('Continue', '继续'),
                        onTap: controller.next,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideScrim extends StatelessWidget {
  const _GuideScrim();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.transparent,
            const Color(0xFF00050A).withValues(alpha: 0.44),
            const Color(0xFF00050A),
          ],
          stops: const [0, 0.50, 0.72, 0.86],
        ),
      ),
    );
  }
}

class _GuideTitle extends StatelessWidget {
  /// 本地化标题文案，用 `*` 包裹需绿色高亮的关键词，例如 `Make Every *Step* Count`。
  final String title;

  const _GuideTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final segments = title.split('*');
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          color: Colors.white,
          fontSize: 22.sp,
          fontWeight: FontWeight.w900,
          height: 1.05,
        ),
        // split('*') 后奇数下标即被 `*` 包裹的高亮片段。
        children: [
          for (var i = 0; i < segments.length; i++)
            TextSpan(
              text: segments[i],
              style: i.isOdd ? TextStyle(color: AppColors.brandGreen) : null,
            ),
        ],
      ),
    );
  }
}

class _SubscriptionOnboardingBody extends StatelessWidget {
  final OnboardingViewModel controller;

  const _SubscriptionOnboardingBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isIntroOffer = controller.isEligibleForIntroOffer.value;
    final description = controller.productDescription.value.isEmpty
        ? isIntroOffer
              ? lt(
                  r'3-day free trial, then weekly $9.99. Cancel anytime.',
                  r'免费试用 3 天，之后每周 $9.99，可随时取消。',
                )
              : lt(
                  r'Subscribe to unlock goals, rewards, route tracking, health sync, and training insights. Weekly $9.99. Cancel anytime.',
                  r'订阅即可解锁目标、奖励、路线记录、健康同步和训练洞察。每周 $9.99，可随时取消。',
                )
        : controller.productDescription.value;
    final buttonText = isIntroOffer
        ? (controller.buttonText.value.isEmpty
              ? lt('Start Free Trial', '开始免费试用')
              : controller.buttonText.value)
        : lt('Subscribe', '订阅');

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            SubscriptionAssets.onboardingPremiumBackground,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 8.w, top: 2.h),
              child: IconButton(
                onPressed: controller.close,
                color: Colors.white.withValues(alpha: 0.78),
                icon: Icon(Icons.close, size: 24.w),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(23.w, 0, 23.w, 26.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: _PremiumTitle()),
                  SizedBox(height: isIntroOffer ? 25.h : 20.h),
                  Text(
                    lt('Get all permissions', '解锁全部权限'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.22,
                    ),
                  ),
                  SizedBox(height: isIntroOffer ? 42.h : 26.h),
                  if (!isIntroOffer) ...[
                    _OnboardingWeeklyPlanTile(
                      price: controller.productPrice.value,
                    ),
                    SizedBox(height: 24.h),
                  ],
                  _PremiumTrialButton(text: buttonText, onTap: controller.next),
                  SizedBox(height: 18.h),
                  _LegalLinks(
                    onRestore: controller.restore,
                    onManage: controller.manageSubscriptions,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int index;

  const _PageDots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: 8.w,
          height: 8.w,
          margin: EdgeInsets.symmetric(horizontal: 8.w),
          decoration: BoxDecoration(
            color: active
                ? AppColors.brandGreen
                : Colors.white.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(AppRadius.full),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.brandGreen.withValues(alpha: 0.46),
                      blurRadius: 14.r,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

class _GuideContinueButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _GuideContinueButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.full),
          gradient: LinearGradient(
            colors: [AppColors.brandGreenLight, AppColors.brandGreen],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandGreen.withValues(alpha: 0.32),
              blurRadius: 24.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFF00130A),
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _PremiumTrialButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _PremiumTrialButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
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

class _OnboardingWeeklyPlanTile extends StatelessWidget {
  final String price;

  const _OnboardingWeeklyPlanTile({required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68.h,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
        color: const Color(0xFF03141A).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.brandGreen, width: 2.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              lt('Weekly Plan', '周计划'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Text(
            price,
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
    );
  }
}

class _LegalLinks extends StatelessWidget {
  final VoidCallback onRestore;
  final VoidCallback onManage;

  const _LegalLinks({required this.onRestore, required this.onManage});

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.68),
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(
            text: lt('Privacy Policy', '隐私政策'),
            recognizer: TapGestureRecognizer()
              ..onTap = () => LegalNavigation.openPrivacyPolicy<void>(
                title: lt('Privacy Policy', '隐私政策'),
              ),
          ),
          const TextSpan(text: '  |  '),
          TextSpan(
            text: lt('Terms', '用户协议'),
            recognizer: TapGestureRecognizer()
              ..onTap = () => LegalNavigation.openUserAgreement<void>(
                title: lt('Terms', '用户协议'),
              ),
          ),
          const TextSpan(text: '  |  '),
          TextSpan(
            text: lt('Subscribe', '订阅'),
            recognizer: TapGestureRecognizer()..onTap = onManage,
          ),
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
