import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/home/components/sync_data_detail_components.dart';
import 'package:pedometer/feature/home/components/sync_history_detail_components.dart';
import 'package:pedometer/feature/home/model/sync_data_detail_model.dart';
import 'package:pedometer/feature/home/resources/home_resource.dart';
import 'package:pedometer/feature/home/viewmodel/sync_history_detail_view_model.dart';

/// 单条同步历史详情页。
class SyncHistoryDetailPage extends GetView<SyncHistoryDetailViewModel> {
  static const String routeName = HomeRouteTable.pathSyncHistoryDetail;

  final SyncHistoryDetailData data;

  const SyncHistoryDetailPage({
    super.key,
    this.data = SyncHistoryDetailData.mock,
  });

  @override
  Widget build(BuildContext context) {
    controller.useData(data);

    return Scaffold(
      backgroundColor: HomeResource.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _SyncHistoryDetailBackground()),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: Obx(() {
                final data = controller.data.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTopNavigationBar(title: '同步历史详情', onBack: _back),
                    SyncHistoryStatusHero(data: data),
                    CurrentSyncDataCard(items: data.syncedItems),
                    SizedBox(height: AppSpacing.lg),
                    SourceAndMethodCard(
                      sources: data.sources,
                      methodItems: data.methodItems,
                    ),
                    SizedBox(height: AppSpacing.lg),
                    SyncInfoCard(items: data.infoItems),
                    SizedBox(height: AppSpacing.xl),
                    DataSecurityFooter(text: data.safetyText),
                    SizedBox(height: AppSpacing.xxxl),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _back() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back<void>();
    }
  }
}

class _SyncHistoryDetailBackground extends StatelessWidget {
  const _SyncHistoryDetailBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bgPrimary,
            AppColors.bgRadialBlue,
            AppColors.bgPrimary,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 110,
            left: -80,
            right: -80,
            height: 330,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.brandGreenDark.withValues(alpha: 0.56),
                    AppColors.bgRadialBlue.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -80,
            right: -80,
            height: 360,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.brandGreenDark.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
