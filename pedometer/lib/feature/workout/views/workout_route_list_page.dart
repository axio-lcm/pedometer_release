import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';
import 'package:pedometer/feature/workout/viewmodel/workout_tracking_view_model.dart';
import 'package:pedometer/feature/workout/views/workout_route_history_page.dart';

class WorkoutRouteListPage extends StatelessWidget {
  static const String routeName = WorkoutRouteTable.pathRouteHistory;

  const WorkoutRouteListPage({super.key});

  WorkoutTrackingViewModel? get _trackingController =>
      Get.isRegistered<WorkoutTrackingViewModel>()
      ? Get.find<WorkoutTrackingViewModel>()
      : null;

  void _back() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back<void>();
    }
  }

  void _openDetail() {
    Get.toNamed(WorkoutRouteHistoryPage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final trackingController = _trackingController;
    return Scaffold(
      backgroundColor: WorkoutResource.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _RouteListBackground()),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: trackingController == null
                  ? _RouteListContent(onBack: _back)
                  : Obx(
                      () => _RouteListContent(
                        onBack: _back,
                        distance: trackingController.distanceKmText,
                        duration: trackingController.durationText,
                        pace: trackingController.paceText,
                        onRouteTap: _openDetail,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteListContent extends StatelessWidget {
  final String distance;
  final String duration;
  final String pace;
  final VoidCallback onBack;
  final VoidCallback? onRouteTap;

  const _RouteListContent({
    required this.onBack,
    this.distance = '0.00',
    this.duration = '00:00:00',
    this.pace = "--'--''",
    this.onRouteTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasRoute = onRouteTap != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTopNavigationBar(
          title: WorkoutResource.routeHistoryTitle,
          onBack: onBack,
        ),
        SizedBox(height: AppSpacing.lg),
        if (hasRoute)
          _RouteListItem(
            distance: distance,
            duration: duration,
            pace: pace,
            onTap: onRouteTap!,
          )
        else
          const _RouteListEmptyState(),
      ],
    );
  }
}

class _RouteListItem extends StatelessWidget {
  final String distance;
  final String duration;
  final String pace;
  final VoidCallback onTap;

  const _RouteListItem({
    required this.distance,
    required this.duration,
    required this.pace,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: GlassCard(
        radius: AppRadius.xl,
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    color: AppColors.brandGreen.withValues(alpha: 0.18),
                  ),
                  child: Icon(
                    Icons.route_rounded,
                    color: AppColors.brandGreen,
                    size: 24,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        WorkoutResource.routeHistoryCurrent,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        WorkoutResource.routeHistoryRecording,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 26,
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _RouteListMetric(
                    label: WorkoutResource.metricDistance,
                    value: distance,
                    unit: 'km',
                  ),
                ),
                Expanded(
                  child: _RouteListMetric(
                    label: WorkoutResource.metricDuration,
                    value: duration,
                  ),
                ),
                Expanded(
                  child: _RouteListMetric(
                    label: WorkoutResource.metricPace,
                    value: pace,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteListMetric extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;

  const _RouteListMetric({required this.label, required this.value, this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
        SizedBox(height: AppSpacing.xs),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (unit != null)
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _RouteListEmptyState extends StatelessWidget {
  const _RouteListEmptyState();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xl,
      padding: EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Icon(Icons.route_outlined, color: AppColors.textSecondary, size: 44),
          SizedBox(height: AppSpacing.md),
          Text(
            WorkoutResource.routeHistoryEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _RouteListBackground extends StatelessWidget {
  const _RouteListBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bgPrimary,
            AppColors.bgRadialBlue.withValues(alpha: 0.72),
            AppColors.bgPrimary,
          ],
        ),
      ),
    );
  }
}
