import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/home/components/sync_data_detail_components.dart';
import 'package:pedometer/feature/home/model/sync_data_detail_model.dart';
import 'package:pedometer/feature/home/resources/home_resource.dart';
import 'package:pedometer/feature/home/views/sync_history_detail_page.dart';

/// 同步历史「查看全部」列表页。
class SyncHistoryListPage extends StatelessWidget {
  static const String routeName = HomeRouteTable.pathSyncHistoryList;

  final SyncHistoryListData data;

  const SyncHistoryListPage({super.key, this.data = SyncHistoryListData.mock});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeResource.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _SyncHistoryListBackground()),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTopNavigationBar(
                    title: '同步历史',
                    onBack: () {
                      if (Get.key.currentState?.canPop() ?? false) {
                        Get.back<void>();
                      }
                    },
                  ),
                  SizedBox(height: AppSpacing.md),
                  SyncHistoryListCard(
                    records: data.records,
                    onRecordTap: (record) => Get.toNamed(
                      SyncHistoryDetailPage.routeName,
                      arguments: record,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncHistoryListBackground extends StatelessWidget {
  const _SyncHistoryListBackground();

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
            top: 90,
            left: -70,
            right: -70,
            height: 320,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.bgRadialGreen.withValues(alpha: 0.54),
                    AppColors.bgRadialBlue.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 430,
            left: -90,
            right: -90,
            height: 360,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.brandGreenDark.withValues(alpha: 0.2),
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
