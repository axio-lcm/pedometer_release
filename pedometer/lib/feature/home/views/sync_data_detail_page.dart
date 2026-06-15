import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/home/components/sync_data_detail_components.dart';
import 'package:pedometer/feature/home/model/sync_data_detail_model.dart';
import 'package:pedometer/feature/home/resources/home_resource.dart';
import 'package:pedometer/feature/home/views/sync_history_detail_page.dart';
import 'package:pedometer/feature/home/views/sync_history_list_page.dart';
import 'package:pedometer/feature/home/views/sync_source_detail_page.dart';
import 'package:pedometer_health/pedometer_health.dart';

/// Health 同步数据详情页。
class SyncDataDetailPage extends StatefulWidget {
  static const String routeName = HomeRouteTable.pathSyncDataDetail;

  final SyncDataDetailData data;

  const SyncDataDetailPage({super.key, this.data = SyncDataDetailData.mock});

  @override
  State<SyncDataDetailPage> createState() => _SyncDataDetailPageState();
}

class _SyncDataDetailPageState extends State<SyncDataDetailPage> {
  static const _permissionTypes = [
    HealthSyncDataType.steps,
    HealthSyncDataType.distance,
    HealthSyncDataType.calories,
    HealthSyncDataType.activeMinutes,
  ];

  late List<SyncDataSource> _sources;

  @override
  void initState() {
    super.initState();
    _sources = widget.data.sources;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestSourcePermissions();
    });
  }

  @override
  void didUpdateWidget(covariant SyncDataDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.sources != widget.data.sources) {
      _sources = widget.data.sources;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestSourcePermissions();
      });
    }
  }

  Future<void> _requestSourcePermissions() async {
    final client = PedometerHealthClient();

    for (final sourceData in List<SyncDataSource>.of(_sources)) {
      if (!mounted) return; // 页面已销毁则停止，避免异步泄漏到后续（含测试间污染）
      final source = _sourceForTitle(sourceData.title);
      if (source == null) continue;

      _updateSourceStatus(sourceData.title, '请求权限中');

      try {
        final available = await client.isAvailable(source: source);
        if (!mounted) return;
        if (!available) {
          _updateSourceStatus(sourceData.title, '不可用');
          continue;
        }

        final requested = await client.requestAuthorization(
          source: source,
          types: _permissionTypes,
        );
        if (!mounted) return;
        _updateSourceStatus(sourceData.title, requested ? '已连接' : '未授权');
      } catch (error) {
        if (!mounted) return;
        final status = error is MissingPluginException ? '不可用' : '授权失败';
        _updateSourceStatus(sourceData.title, status);
      }
    }
  }

  HealthSyncSource? _sourceForTitle(String title) {
    return switch (title) {
      'Apple Health' => HealthSyncSource.appleHealth,
      'Health Connect' => HealthSyncSource.healthConnect,
      _ => null,
    };
  }

  void _updateSourceStatus(String title, String status) {
    if (!mounted) return;
    setState(() {
      _sources = [
        for (final source in _sources)
          if (source.title == title)
            source.copyWith(status: status)
          else
            source,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

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
                    sources: _sources,
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
