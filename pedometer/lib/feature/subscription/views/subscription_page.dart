import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/common/config/localized_text.dart';
import 'package:pedometer/feature/subscription/components/free_trial_switch_intro_overlay.dart';
import 'package:pedometer/feature/subscription/config/subscription_config.dart';
import 'package:pedometer/feature/subscription/model/subscription_assets.dart';
import 'package:pedometer/feature/subscription/viewmodel/subscription_view_model.dart';

class SubscriptionPage extends GetView<SubscriptionViewModel> {
  static const String routeName = '/subscription';

  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030D3C),
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Image.asset(
              SubscriptionAssets.background2,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: Get.back,
                    color: Colors.white.withValues(alpha: 0.62),
                    icon: const Icon(Icons.close),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl,
                      150,
                    ),
                    children: [
                      Obx(
                        () => Text(
                          controller.isEligibleForIntroOffer.value
                              ? lt('Start Your Free Trial', '开始免费试用')
                              : lt(
                                  'Upgrade to Pedometer Pro',
                                  '升级 Pedometer Pro',
                                ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.xxl),
                      const _BenefitList(),
                      SizedBox(height: AppSpacing.xxl),
                      Obx(
                        () => Column(
                          children: [
                            for (var i = 0; i < controller.plans.length; i++)
                              _PlanTile(
                                plan: controller.plans[i],
                                selected: controller.selectedIndex.value == i,
                                onTap: () => controller.select(i),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppSpacing.xl),
                      _LegalLinks(onRestore: controller.restore),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomAction(controller: controller),
          ),
          Obx(
            () => Positioned.fill(
              child: FreeTrialSwitchIntroOverlay(
                visible: controller.showFreeTrialSwitchIntro.value,
                onFinished: controller.hideFreeTrialSwitchIntro,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitList extends StatelessWidget {
  const _BenefitList();

  @override
  Widget build(BuildContext context) {
    final benefits = [
      lt('Health data sync and trend analysis', '健康数据同步与趋势分析'),
      lt('Detailed day, week, and month reports', '日、周、月详细统计'),
      lt('Workout routes and history records', '运动轨迹与历史记录'),
      lt('No family sharing. Korea has no intro offer.', '无家庭共享，韩国无优惠'),
    ];
    return Column(
      children: [
        for (final benefit in benefits)
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Image.asset(
                    SubscriptionAssets.check,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.check_circle,
                      color: Color(0xFF24F04E),
                      size: 20,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    benefit,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PlanTile extends StatelessWidget {
  final SubscriptionProductPlan plan;
  final bool selected;
  final VoidCallback onTap;

  const _PlanTile({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.only(bottom: AppSpacing.md),
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          color: selected
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.08),
          border: Border.all(
            color: selected ? AppColors.brandGreen : Colors.white24,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? AppColors.brandGreen : Colors.white54,
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.fallbackTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    plan.fallbackSubtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              plan.fallbackPrice,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final SubscriptionViewModel controller;

  const _BottomAction({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.md,
        ),
        color: const Color(0xFF030D3C),
        child: Obx(
          () => GestureDetector(
            onTap: controller.purchase,
            child: Container(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.buttonText.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF101928),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    controller.isEligibleForIntroOffer.value
                        ? lt('Cancel anytime, no payment today', '可随时取消，今日无需付款')
                        : lt('Cancel anytime', '可随时取消'),
                    style: const TextStyle(
                      color: Color(0xFF005467),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
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
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(text: lt('Privacy Policy', '隐私政策')),
          const TextSpan(text: '  |  '),
          TextSpan(text: lt('Terms', '用户协议')),
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
