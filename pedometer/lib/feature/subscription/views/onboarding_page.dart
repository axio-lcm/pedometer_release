import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/common/config/localized_text.dart';
import 'package:pedometer/feature/subscription/viewmodel/onboarding_view_model.dart';

class OnboardingPage extends GetView<OnboardingViewModel> {
  static const String routeName = '/onboarding';

  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => controller.isGuidePage
            ? _GuideOnboardingBody(controller: controller)
            : _SubscriptionOnboardingBody(controller: controller),
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
                  padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 28.h),
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
                            _GuideTitle(index: controller.index.value),
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
  final int index;

  const _GuideTitle({required this.index});

  @override
  Widget build(BuildContext context) {
    final parts = switch (index) {
      0 => ('Make Every ', 'Step', ' Count'),
      1 => ('Stay ', 'Motivated', ''),
      _ => ('Sync with ', 'Health', ''),
    };

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          color: Colors.white,
          fontSize: 28.sp,
          fontWeight: FontWeight.w900,
          height: 1.05,
        ),
        children: [
          TextSpan(text: parts.$1),
          TextSpan(
            text: parts.$2,
            style: TextStyle(color: AppColors.brandGreen),
          ),
          TextSpan(text: parts.$3),
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
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0E3286), Color(0xFF010323)],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: controller.close,
                  color: Colors.white.withValues(alpha: 0.62),
                  icon: const Icon(Icons.close),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      controller.titles[controller.index.value],
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      controller.subtitles[controller.index.value],
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 15,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (controller.productDescription.value.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        controller.productDescription.value,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: Color(0xFFB2F0FF),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Image.asset(
                    OnboardingViewModel.images[controller.index.value],
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              _SubscriptionButton(
                text: controller.buttonText.value,
                onTap: controller.next,
              ),
              SizedBox(height: AppSpacing.sm),
              _LegalLinks(onRestore: controller.restore),
              SizedBox(height: AppSpacing.xl),
            ],
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
        height: 54.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.full),
          gradient: const LinearGradient(
            colors: [Color(0xFF32F12C), Color(0xFFB8F915)],
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

class _SubscriptionButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _SubscriptionButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF69EAFF),
                Color(0xFFB2F0FF),
                Color(0xFFEDF5FD),
                Color(0xFFF5CCFF),
              ],
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF101928),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
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
          color: Colors.white.withValues(alpha: 0.68),
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(text: lt('Cancel anytime', '可随时取消')),
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
