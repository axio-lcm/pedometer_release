import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/home/components/sync_data_detail_components.dart';
import 'package:pedometer/feature/home/model/health_sync_source_policy.dart';
import 'package:pedometer/feature/home/model/sync_data_detail_model.dart';
import 'package:pedometer/feature/home/resources/home_resource.dart';
import 'package:pedometer/feature/home/views/sync_history_detail_page.dart';
import 'package:pedometer/feature/home/views/sync_history_list_page.dart';
import 'package:pedometer/feature/home/views/sync_source_detail_page.dart';

/// Health 同步数据详情页。
///
/// 数据来源按平台过滤：iOS 仅展示 Apple Health，Android 仅展示 Health Connect。
/// 健康权限的申请已移动到来源详情页（[SyncSourceDetailPage]）进入时进行。
class SyncDataDetailPage extends StatelessWidget {
  static const String routeName = HomeRouteTable.pathSyncDataDetail;

  final SyncDataDetailData data;

  const SyncDataDetailPage({super.key, this.data = SyncDataDetailData.mock});

  /// 仅保留当前平台支持的来源；平台无匹配时回退到原始列表，避免空白。
  List<SyncDataSource> _platformSources(TargetPlatform platform) {
    final allowedTitles = HealthSyncSourcePolicy.sourcesFor(
      platform,
    ).map(HealthSyncSourcePolicy.titleFor).toSet();
    final filtered = data.sources
        .where((source) => allowedTitles.contains(source.title))
        .toList();
    return filtered.isEmpty ? data.sources : filtered;
  }

  @override
  Widget build(BuildContext context) {
    final sources = _platformSources(defaultTargetPlatform);

    return Scaffold(
      backgroundColor: HomeResource.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _SyncDetailBackground()),
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
                    title: '同步数据详情',
                    onBack: () {
                      if (Get.key.currentState?.canPop() ?? false) {
                        Get.back<void>();
                      }
                    },
                  ),
                  SyncStatusHero(data: data),
                  SyncOverviewCard(
                    sources: sources,
                    onSourceView: (source) => Get.toNamed(
                      SyncSourceDetailPage.routeName,
                      arguments: source,
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  DataTypeCard(items: data.dataTypes),
                  SizedBox(height: AppSpacing.lg),
                  SyncHistoryCard(
                    histories: data.histories,
                    onHistoryTap: (record) => Get.toNamed(
                      SyncHistoryDetailPage.routeName,
                      arguments: record,
                    ),
                    onViewAll: () => Get.toNamed(SyncHistoryListPage.routeName),
                  ),
                  SizedBox(height: AppSpacing.xl),
                  DataSecurityFooter(text: data.safetyText),
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

class _SyncDetailBackground extends StatelessWidget {
  const _SyncDetailBackground();

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
