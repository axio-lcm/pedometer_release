import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
      backgroundColor: const Color(0xFF030D3C),
      body: Obx(
        () => Stack(
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
                  if (controller.isLast)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: controller.close,
                        color: Colors.white.withValues(alpha: 0.62),
                        icon: const Icon(Icons.close),
                      ),
                    )
                  else
                    SizedBox(height: AppSpacing.xxl),
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
                        if (controller.isLast &&
                            controller.productDescription.value.isNotEmpty) ...[
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
                  _PrimarySubscriptionButton(
                    text: controller.isLast
                        ? controller.buttonText.value
                        : lt('Continue', '继续'),
                    onTap: controller.next,
                  ),
                  if (controller.isLast) ...[
                    SizedBox(height: AppSpacing.sm),
                    _LegalLinks(onRestore: controller.restore),
                  ],
                  SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
            if (controller.isLast) const _FreeTrialHintOverlay(),
          ],
        ),
      ),
    );
  }
}

class _PrimarySubscriptionButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _PrimarySubscriptionButton({required this.text, required this.onTap});

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
          color: Colors.white.withValues(alpha: 0.72),
          fontSize: 12,
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

class _FreeTrialHintOverlay extends StatelessWidget {
  const _FreeTrialHintOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1, end: 0),
        duration: const Duration(milliseconds: 2600),
        builder: (context, value, child) {
          if (value <= 0.02) return const SizedBox.shrink();
          return Opacity(opacity: value, child: child);
        },
        child: Container(
          color: Colors.black.withValues(alpha: 0.84),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(value: true, onChanged: (_) {}),
              SizedBox(height: AppSpacing.md),
              Text(
                lt('3-Day Free Trial Enabled', '已开启 3 天免费试用'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.brandGreen,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
