import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/common/tools/app_market_launcher.dart';
import 'package:pedometer/feature/mine/resources/mine_resource.dart';
import 'package:pedometer/feature/mine/views/suggestion_page.dart';

/// 弹出评分弹窗（复用自 al_led_banner 的评价引流思路）。
///
/// 五星 → 调起 iOS 系统应用内评价；1–4 星 → 跳转站内「建议」反馈页。
/// 用 [Get.dialog] 触发，无需调用方持有 BuildContext。
Future<void> showMineRateDialog() {
  return Get.dialog<void>(const _MineRateDialog(), barrierDismissible: true);
}

class _MineRateDialog extends StatefulWidget {
  const _MineRateDialog();

  @override
  State<_MineRateDialog> createState() => _MineRateDialogState();
}

class _MineRateDialogState extends State<_MineRateDialog> {
  int _rating = 0;

  void _close() => Get.back<void>();

  Future<void> _handleSubmit() async {
    final rating = _rating;
    if (rating < 1 || rating > 5) return;

    Get.back<void>();

    if (rating == 5) {
      await AppMarketLauncher.requestInAppReview();
      return;
    }

    await Get.toNamed<void>(SuggestionPage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: GlassCard(
          radius: AppRadius.xxl,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      MineResource.rateDialogTitle,
                      style: TextStyle(
                        color: AppColors.brandGreen,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _close,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),
              Image.asset(
                MineResource.rateIllustration,
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),
              SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 5; i++) ...[
                    if (i > 0) SizedBox(width: AppSpacing.sm),
                    GestureDetector(
                      onTap: () => setState(() => _rating = i + 1),
                      behavior: HitTestBehavior.opaque,
                      child: Image.asset(
                        i < _rating
                            ? MineResource.rateStarFilled
                            : MineResource.rateStarEmpty,
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: AppSpacing.lg),
              Text(
                MineResource.rateDialogMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.85),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              GestureDetector(
                onTap: _rating > 0 ? _handleSubmit : null,
                behavior: HitTestBehavior.opaque,
                child: Opacity(
                  opacity: _rating > 0 ? 1 : 0.4,
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.brandGreenLight,
                          AppColors.brandGreen,
                        ],
                      ),
                    ),
                    child: Text(
                      MineResource.rateDialogSubmit,
                      style: TextStyle(
                        color: AppColors.bgPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
