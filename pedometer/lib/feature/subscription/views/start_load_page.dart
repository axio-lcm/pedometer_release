import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/subscription/model/subscription_assets.dart';
import 'package:pedometer/feature/subscription/viewmodel/start_load_view_model.dart';

class StartLoadPage extends GetView<StartLoadViewModel> {
  static const String routeName = '/start-load';

  const StartLoadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              SubscriptionAssets.background1,
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Transform.translate(
              offset: const Offset(0, -72),
              child: Image.asset(
                SubscriptionAssets.appLogo,
                width: 130,
                height: 130,
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.xxxl,
                ),
                child: Obx(
                  () => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: LinearProgressIndicator(
                          minHeight: 5,
                          value: controller.progress.value / 100,
                          color: AppColors.brandGreen,
                          backgroundColor: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        controller.statusText.value,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
