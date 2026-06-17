import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/home/components/sport_detail_components.dart';
import 'package:pedometer/feature/home/model/health_repository.dart';
import 'package:pedometer/feature/home/model/sport_detail_model.dart';
import 'package:pedometer/feature/home/resources/home_resource.dart';

/// 二级运动详情页：日 / 周 / 月三态。
class SportDetailPage extends StatefulWidget {
  static const String routeName = HomeRouteTable.pathSportDetail;

  final SportPeriod initialPeriod;
  final HealthRepository? repository;

  const SportDetailPage({
    super.key,
    this.initialPeriod = SportPeriod.day,
    this.repository,
  });

  @override
  State<SportDetailPage> createState() => _SportDetailPageState();
}

class _SportDetailPageState extends State<SportDetailPage> {
  late SportPeriod _period = widget.initialPeriod;
  late final HealthRepository _repository =
      widget.repository ?? HealthRepository.defaultRepository();

  /// 周视图的周偏移：0 = 本周，-1 = 上周……不可大于 0（即不能查看未来）。
  int _weekOffset = 0;

  @override
  void initState() {
    super.initState();
    HealthSyncRuntime.revision.addListener(_refreshSyncedHealth);
  }

  @override
  void dispose() {
    HealthSyncRuntime.revision.removeListener(_refreshSyncedHealth);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _repository.sportPeriodData(_period);
    final isWeek = _period == SportPeriod.week;
    final title = isWeek
        ? SportDetailFixtures.weekTitle(offset: _weekOffset)
        : data.dateTitle;
    return Scaffold(
      backgroundColor: HomeResource.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _SportDetailBackground()),
          SafeArea(
            bottom: false,
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
                  AppTopNavigationBar(
                    title: title,
                    onTitlePrev: isWeek
                        ? () => setState(() => _weekOffset -= 1)
                        : null,
                    onTitleNext: isWeek
                        ? () => setState(() {
                            if (_weekOffset < 0) _weekOffset += 1;
                          })
                        : null,
                    titleNextEnabled: isWeek && _weekOffset < 0,
                    onBack: () {
                      if (Get.key.currentState?.canPop() ?? false) {
                        Get.back<void>();
                      }
                    },
                  ),
                  SizedBox(height: AppSpacing.sm),
                  SportHeroSection(data: data),
                  SizedBox(height: AppSpacing.md),
                  _PeriodSpecificContent(data: data),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: AppBottomTabBarMetrics.bottomOffset,
            child: Center(
              child: SportPeriodTabBar(
                current: _period,
                onChanged: (period) => setState(() {
                  _period = period;
                  _weekOffset = 0;
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _refreshSyncedHealth() {
    if (mounted) setState(() {});
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

  const _PeriodSpecificContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return switch (data.period) {
      SportPeriod.day => _DayContent(data: data),
      SportPeriod.week => _WeekContent(data: data),
      SportPeriod.month => _MonthContent(data: data),
    };
  }
}

class _DayContent extends StatelessWidget {
  final SportPeriodData data;

  const _DayContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HourlyStepTrendCard(data: data.hourly),
        SizedBox(height: AppSpacing.md),
        SportSegmentListCard(segments: data.segments),
        SizedBox(height: AppSpacing.md),
        SummaryCard(data: data.summary),
      ],
    );
  }
}

class _WeekContent extends StatelessWidget {
  final SportPeriodData data;

  const _WeekContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WeeklyTrendCard(data: data.weekly),
        SizedBox(height: AppSpacing.md),
        _AnalysisRow(analyses: data.analyses),
        SizedBox(height: AppSpacing.md),
        SummaryCard(data: data.summary),
      ],
    );
  }
}

class _MonthContent extends StatelessWidget {
  final SportPeriodData data;

  const _MonthContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonthlyHeatCalendarCard(days: data.monthly),
        SizedBox(height: AppSpacing.md),
        _AnalysisRow(analyses: data.analyses),
        SizedBox(height: AppSpacing.md),
        SummaryCard(data: data.summary),
      ],
    );
  }
}

class _AnalysisRow extends StatelessWidget {
  final List<SportAnalysisData> analyses;

  const _AnalysisRow({required this.analyses});

  @override
  Widget build(BuildContext context) {
    if (analyses.length < 2) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: SportMiniAnalysisCard(data: analyses[0])),
        SizedBox(width: AppSpacing.md),
        Expanded(child: SportMiniAnalysisCard(data: analyses[1])),
      ],
    );
  }
}
