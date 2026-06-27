import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/component/asset_metric_icon.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/common/config/localized_text.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';
import 'package:pedometer/feature/workout/views/workout_route_history_page.dart';

class WorkoutRouteListPage extends StatelessWidget {
  static const String routeName = WorkoutRouteTable.pathRouteHistory;

  const WorkoutRouteListPage({super.key});

  void _back() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back<void>();
    }
  }

  void _openDetail(WorkoutRouteHistoryRecord record) {
    if (_isIndoorRecord(record)) return;
    Get.toNamed(WorkoutRouteHistoryPage.routeName, arguments: record);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorkoutResource.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _RouteListBackground()),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.lg,
                    0,
                  ),
                  child: AppTopNavigationBar(
                    title: WorkoutResource.routeHistoryTitle,
                    onBack: _back,
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: ValueListenableBuilder<int>(
                    valueListenable: WorkoutRouteHistoryStore.revision,
                    builder: (context, _, _) {
                      final records = WorkoutRouteHistoryStore.records;
                      if (records.isEmpty) {
                        return SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.xxl,
                          ),
                          child: const _RouteListEmptyState(),
                        );
                      }
                      // 懒加载：仅构建可见项，避免长列表一次性建全部条目与解码全部地图截图。
                      return ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.xxl,
                        ),
                        itemCount: records.length,
                        separatorBuilder: (context, _) =>
                            SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return _RouteListItem(
                            record: record,
                            onTap: _isIndoorRecord(record)
                                ? null
                                : () => _openDetail(record),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteListItem extends StatelessWidget {
  final WorkoutRouteHistoryRecord record;
  final VoidCallback? onTap;

  const _RouteListItem({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final workoutType = _workoutTypeFor(record.sportType);
    final sportType = WorkoutResource.localizedWorkoutTypeTitle(
      record.sportType,
    );
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
                _RouteWorkoutTypeIcon(type: workoutType),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sportType,
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
                        _formatEndedAt(record.endedAt),
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
                if (onTap != null)
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
                    value: record.distanceKm,
                    unit: 'km',
                  ),
                ),
                Expanded(
                  child: _RouteListMetric(
                    label: WorkoutResource.metricDuration,
                    value: record.duration,
                  ),
                ),
                Expanded(
                  child: _RouteListMetric(
                    label: WorkoutResource.metricPaceMinKm,
                    value: record.averagePace,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatEndedAt(DateTime value) {
    return localizedDateTime(value);
  }

  WorkoutType _workoutTypeFor(String title) {
    return WorkoutPageData.localized().workoutTypes.firstWhere(
      (type) => type.title == title,
      orElse: () => WorkoutPageData.mock.workoutTypes.firstWhere(
        (type) => type.title == title,
        orElse: () => WorkoutPageData.localized().workoutTypes.first,
      ),
    );
  }
}

bool _isIndoorRecord(WorkoutRouteHistoryRecord record) {
  final title = record.sportType;
  return title == WorkoutResource.indoorRun ||
      title == WorkoutText.indoorRun ||
      title == '室内' ||
      title == '室内';
}

class _RouteWorkoutTypeIcon extends StatelessWidget {
  final WorkoutType type;

  const _RouteWorkoutTypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final iconAsset = type.iconAsset;
    if (iconAsset != null) {
      return SizedBox(
        width: 42,
        height: 42,
        child: Center(child: AssetMetricIcon(assetName: iconAsset, size: 42)),
      );
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: type.color.withValues(alpha: 0.16),
        border: Border.all(color: type.color.withValues(alpha: 0.45)),
      ),
      child: Icon(type.icon, color: type.color, size: 24),
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
