import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/mine/components/mine_components.dart';
import 'package:pedometer/feature/mine/model/mine_model.dart';
import 'package:pedometer/feature/mine/resources/mine_resource.dart';
import 'package:pedometer/feature/mine/viewmodel/mine_view_model.dart';

/// 我的（个人中心）页：身体指标总览 + 设置入口列表。
///
/// 由 MainPage 的底部三栏导航宿主，选中态为「我的」，故本页不自带底部导航。
class MinePage extends GetView<MineViewModel> {
  final MinePageData data;

  const MinePage({super.key, this.data = MinePageData.mock});

  @override
  Widget build(BuildContext context) {
    controller.useData(data);

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
                AppSpacing.xxxl,
                AppSpacing.lg,
                120,
              ),
              child: Obx(() {
                final data = controller.data.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BodyStatsCard(stats: data.bodyStats),
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
