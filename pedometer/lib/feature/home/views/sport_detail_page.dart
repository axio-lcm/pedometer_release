import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/home/components/sport_detail_components.dart';
import 'package:pedometer/feature/home/model/sport_detail_model.dart';
import 'package:pedometer/feature/home/resources/home_resource.dart';
import 'package:pedometer/feature/home/viewmodel/sport_detail_view_model.dart';

/// 二级运动详情页：日 / 周 / 月三态。
class SportDetailPage extends GetView<SportDetailViewModel> {
  static const String routeName = HomeRouteTable.pathSportDetail;

  const SportDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeResource.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _SportDetailBackground()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Obx(
                    () => AppTopNavigationBar(
                      title: controller.title,
                      onTitlePrev: controller.isWeek
                          ? controller.prevWeek
                          : null,
                      onTitleNext: controller.isWeek
                          ? controller.nextWeek
                          : null,
                      titleNextEnabled: controller.titleNextEnabled,
                      animateTitleChanges: controller.animateTitleChanges,
                      onBack: () {
                        if (Get.key.currentState?.canPop() ?? false) {
                          Get.back<void>();
                        }
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xs,
                      AppSpacing.lg,
                      112,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: AppSpacing.sm),
                        Obx(
                          () => SportHeroSection(
                            data: controller.data.value,
                            replayKey: controller.revealRevision.value,
                          ),
                        ),
                        SizedBox(height: AppSpacing.md),
                        Obx(
                          () => _PeriodSpecificContent(
                            data: controller.data.value,
                            replayKey: controller.revealRevision.value,
                            onMonthChanged: controller.changeMonth,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: AppBottomTabBarMetrics.bottomOffset,
            child: Center(
              child: Obx(
                () => SportPeriodTabBar(
                  current: controller.period.value,
                  onChanged: controller.changePeriod,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SportDetailBackground extends StatelessWidget {
  const _SportDetailBackground();

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
            top: -80,
            left: -60,
            right: -60,
            height: 360,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.bgRadialGreen.withValues(alpha: 0.46),
                    AppColors.bgRadialBlue.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -60,
            right: -60,
            height: 320,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.brandGreenDark.withValues(alpha: 0.22),
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

class _PeriodSpecificContent extends StatelessWidget {
  final SportPeriodData data;
  final Object? replayKey;
  final void Function(int offset) onMonthChanged;

  const _PeriodSpecificContent({
    required this.data,
    required this.replayKey,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return switch (data.period) {
      SportPeriod.day => _DayContent(data: data, replayKey: replayKey),
      SportPeriod.week => _WeekContent(data: data, replayKey: replayKey),
      SportPeriod.month => _MonthContent(
        data: data,
        replayKey: replayKey,
        onMonthChanged: onMonthChanged,
      ),
    };
  }
}

class _DayContent extends StatelessWidget {
  final SportPeriodData data;
  final Object? replayKey;

  const _DayContent({required this.data, this.replayKey});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HourlyStepTrendCard(data: data.hourly, replayKey: replayKey),
        SizedBox(height: AppSpacing.md),
        _AnalysisRow(analyses: data.analyses, replayKey: replayKey),
        SizedBox(height: AppSpacing.md),
        SummaryCard(data: data.summary),
      ],
    );
  }
}

class _WeekContent extends StatelessWidget {
  final SportPeriodData data;
  final Object? replayKey;

  const _WeekContent({required this.data, this.replayKey});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WeeklyTrendCard(data: data.weekly, replayKey: replayKey),
        SizedBox(height: AppSpacing.md),
        _AnalysisRow(analyses: data.analyses, replayKey: replayKey),
        SizedBox(height: AppSpacing.md),
        SummaryCard(data: data.summary),
      ],
    );
  }
}

class _MonthContent extends StatelessWidget {
  final SportPeriodData data;
  final Object? replayKey;
  final void Function(int offset) onMonthChanged;

  const _MonthContent({
    required this.data,
    required this.onMonthChanged,
    this.replayKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonthlyHeatCalendarCard(
          days: data.monthly,
          replayKey: replayKey,
          onMonthChanged: onMonthChanged,
        ),
        SizedBox(height: AppSpacing.md),
        _AnalysisRow(analyses: data.analyses, replayKey: replayKey),
        SizedBox(height: AppSpacing.md),
        SummaryCard(data: data.summary),
      ],
    );
  }
}

class _AnalysisRow extends StatelessWidget {
  final List<SportAnalysisData> analyses;
  final Object? replayKey;

  const _AnalysisRow({required this.analyses, this.replayKey});

  @override
  Widget build(BuildContext context) {
    if (analyses.length < 2) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SportMiniAnalysisCard(
            data: analyses[0],
            replayKey: '$replayKey-0',
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: SportMiniAnalysisCard(
            data: analyses[1],
            replayKey: '$replayKey-1',
          ),
        ),
      ],
    );
  }
}
