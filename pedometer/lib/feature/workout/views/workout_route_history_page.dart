import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';

class WorkoutRouteHistoryPage extends StatelessWidget {
  static const String routeName = WorkoutRouteTable.pathRouteHistoryDetail;

  const WorkoutRouteHistoryPage({super.key});

  void _back() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back<void>();
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final record = args is WorkoutRouteHistoryRecord
        ? args
        : WorkoutRouteHistoryStore.latest;
    return Scaffold(
      backgroundColor: WorkoutResource.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _RouteHistoryBackground()),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: _RouteHistoryContent(record: record, onBack: _back),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteHistoryContent extends StatelessWidget {
  final WorkoutRouteHistoryRecord? record;
  final VoidCallback onBack;

  const _RouteHistoryContent({required this.record, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTopNavigationBar(
          title: WorkoutResource.routeHistoryDetailTitle,
          onBack: onBack,
        ),
        SizedBox(height: AppSpacing.lg),
        _CurrentRouteCard(
          title: record?.sportType ?? WorkoutResource.routeHistoryEmpty,
          points: record?.routePoints ?? const [],
          distance: record?.distanceKm ?? '0.00',
          duration: record?.duration ?? '00:00:00',
          pace: record?.averagePace ?? "--'--''",
          startPoint: record?.startPoint,
          endPoint: record?.endPoint,
          mapSnapshot: record?.mapSnapshot,
        ),
      ],
    );
  }
}

class _CurrentRouteCard extends StatelessWidget {
  final String title;
  final List<LatLng> points;
  final String distance;
  final String duration;
  final String pace;
  final LatLng? startPoint;
  final LatLng? endPoint;
  final Uint8List? mapSnapshot;

  const _CurrentRouteCard({
    required this.title,
    required this.points,
    required this.distance,
    required this.duration,
    required this.pace,
    required this.startPoint,
    required this.endPoint,
    required this.mapSnapshot,
  });

  @override
  Widget build(BuildContext context) {
    final hasSnapshot = mapSnapshot != null;
    return GlassCard(
      radius: AppRadius.xl,
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  color: AppColors.brandGreen.withValues(alpha: 0.18),
                ),
                child: Icon(
                  Icons.route_rounded,
                  color: AppColors.brandGreen,
                  size: 22,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          AspectRatio(
            aspectRatio: 1.72,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                color: AppColors.surfaceIcon.withValues(alpha: 0.44),
                border: Border.all(color: AppColors.strokeCard),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: hasSnapshot
                    ? Image.memory(mapSnapshot!, fit: BoxFit.cover)
                    : _RouteEmptyState(),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _RouteStatItem(
                  label: WorkoutResource.metricDistance,
                  value: distance,
                  unit: 'km',
                ),
              ),
              Expanded(
                child: _RouteStatItem(
                  label: WorkoutResource.metricDuration,
                  value: duration,
                ),
              ),
              Expanded(
                child: _RouteStatItem(
                  label: WorkoutResource.metricPaceMinKm,
                  value: pace,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        WorkoutResource.routeHistoryEmpty,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
    );
  }
}

class _RouteStatItem extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;

  const _RouteStatItem({required this.label, required this.value, this.unit});

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
        RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (unit != null)
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteHistoryBackground extends StatelessWidget {
  const _RouteHistoryBackground();

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
