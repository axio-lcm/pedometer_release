import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/home/components/mini_analysis_card.dart';
import 'package:pedometer/feature/home/components/sport_detail_components.dart';
import 'package:pedometer/feature/home/components/top_entry_card.dart';
import 'package:pedometer/feature/home/components/trend_chart_card.dart';
import 'package:pedometer/feature/home/resources/home_resource.dart';
import 'package:pedometer/feature/home/viewmodel/home_view_model.dart';
import 'package:pedometer/feature/home/views/sync_data_detail_page.dart';
import 'package:pedometer/feature/home/views/sport_detail_page.dart';
import 'package:pedometer/feature/subscription/config/subscription_config.dart';
import 'package:pedometer/feature/subscription/service/subscription_service.dart';

/// 首页：暗色霓虹森林运动 Dashboard。
class HomePage extends GetView<HomeViewModel> {
  static const String routeName = HomeRouteTable.pathHome;
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeResource.background,
      body: Stack(
        children: [
          _background(),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                120,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _topEntries(),
                  SizedBox(height: AppSpacing.lg),
                  _mainRow(),
                  SizedBox(height: AppSpacing.lg),
                  Obx(() => TrendChartCard(points: controller.trend.toList())),
                  SizedBox(height: AppSpacing.lg),
                  _analysisRow(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _background() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.6),
            radius: 1.2,
            colors: [AppColors.bgRadialBlue, AppColors.bgPrimary],
          ),
        ),
      ),
    );
  }

  SubscriptionService get _sub => Get.find<SubscriptionService>();

  Widget _topEntries() {
    return Row(
      children: [
        Expanded(
          child: TopEntryCard(
            icon: Icons.directions_run_rounded,
            iconColor: AppColors.brandGreen,
            label: HomeResource.entryOverview,
            onTap: () => _sub.navigateWithVipGate(
              destination: SportDetailPage.routeName,
              source: SubscriptionSource.subscription,
            ),
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: TopEntryCard(
            icon: Icons.favorite_rounded,
            iconColor: AppColors.accentPink,
            label: HomeResource.entryHealthSync,
            onTap: () => _sub.navigateWithVipGate(
              destination: SyncDataDetailPage.routeName,
              source: SubscriptionSource.subscription,
            ),
          ),
        ),
      ],
    );
  }

  Widget _mainRow() {
    return Obx(() => SportHeroSection(data: controller.dayOverview.value));
  }

  Widget _analysisRow() {
    return Obx(() {
      final list = controller.analyses;
      if (list.length < 2) return const SizedBox.shrink();
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: MiniAnalysisCard(data: list[0])),
          SizedBox(width: AppSpacing.md),
          Expanded(child: MiniAnalysisCard(data: list[1])),
        ],
      );
    });
  }
}
