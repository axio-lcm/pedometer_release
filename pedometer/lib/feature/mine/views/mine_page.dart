import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/common/storage/language_service.dart';
import 'package:pedometer/feature/subscription/config/subscription_config.dart';
import 'package:pedometer/feature/subscription/service/subscription_service.dart';
import 'package:pedometer/feature/subscription/views/subscription_page.dart';
import 'package:pedometer/feature/mine/components/mine_components.dart';
import 'package:pedometer/feature/mine/model/mine_model.dart';
import 'package:pedometer/feature/mine/resources/mine_resource.dart';
import 'package:pedometer/feature/mine/viewmodel/mine_view_model.dart';

/// 我的（个人中心）页：身体指标总览 + 设置入口列表。
///
/// 由 MainPage 的底部三栏导航宿主，选中态为「我的」，故本页不自带底部导航。
class MinePage extends GetView<MineViewModel> {
  final MinePageData? data;

  const MinePage({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MineResource.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _MineBackground()),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              // 底部留白避让 MainPage 的玻璃胶囊导航栏。
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                120,
              ),
              child: Obx(() {
                if (Get.isRegistered<LanguageService>()) {
                  Get.find<LanguageService>().localeRevision.value;
                }
                final data = this.data ?? controller.data.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BodyStatsCard(stats: data.bodyStats),
                    if (!_isVip) ...[
                      SizedBox(height: AppSpacing.xl),
                      MembershipSubscriptionCard(onTap: _openSubscriptionPage),
                    ],
                    SizedBox(height: AppSpacing.xxl),
                    MineSettingsCard(
                      entries: data.entries,
                      onEntryTap: controller.openEntry,
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSubscriptionPage() async {
    if (!Get.isRegistered<SubscriptionService>()) return;
    final service = Get.find<SubscriptionService>();
    if (!await service.shouldShowSubscriptionPage()) return;
    await Get.toNamed(
      SubscriptionPage.routeName,
      arguments: SubscriptionSource.mine,
    );
  }

  bool get _isVip {
    if (!Get.isRegistered<SubscriptionService>()) return false;
    return Get.find<SubscriptionService>().isVip.value;
  }
}

class _MineBackground extends StatelessWidget {
  const _MineBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.6),
          radius: 1.2,
          colors: [AppColors.bgRadialBlue, AppColors.bgPrimary],
        ),
      ),
    );
  }
}
