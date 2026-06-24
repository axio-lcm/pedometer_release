import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';
import 'package:pedometer/feature/workout/viewmodel/workout_tracking_view_model.dart';

class WorkoutRouteHistoryPage extends StatelessWidget {
  static const String routeName = WorkoutRouteTable.pathRouteHistoryDetail;

  const WorkoutRouteHistoryPage({super.key});

  WorkoutTrackingViewModel? get _trackingController =>
      Get.isRegistered<WorkoutTrackingViewModel>()
      ? Get.find<WorkoutTrackingViewModel>()
      : null;

  void _back() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back<void>();
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackingController = _trackingController;
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
              child: trackingController == null
                  ? _RouteHistoryContent(
                      points: const [],
                      distance: '0.00',
                      duration: '00:00:00',
                      pace: "--'--''",
                      onBack: _back,
                    )
                  : Obx(
                      () => _RouteHistoryContent(
                        points: trackingController.pathPoints.toList(
                          growable: false,
                        ),
                        distance: trackingController.distanceKmText,
                        duration: trackingController.durationText,
                        pace: trackingController.paceText,
                        onBack: _back,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteHistoryContent extends StatelessWidget {
  final List<LatLng> points;
  final String distance;
  final String duration;
  final String pace;
  final VoidCallback onBack;

  const _RouteHistoryContent({
    required this.points,
    required this.distance,
    required this.duration,
    required this.pace,
    required this.onBack,
  });

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
          points: points,
          distance: distance,
          duration: duration,
          pace: pace,
        ),
      ],
    );
  }
}

class _CurrentRouteCard extends StatelessWidget {
  final List<LatLng> points;
  final String distance;
  final String duration;
  final String pace;

  const _CurrentRouteCard({
    required this.points,
    required this.distance,
    required this.duration,
    required this.pace,
  });

  @override
  Widget build(BuildContext context) {
    final hasRoute = points.isNotEmpty;
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
                  WorkoutResource.routeHistoryCurrent,
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
                child: hasRoute
                    ? CustomPaint(painter: _RouteHistoryPainter(points))
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
                  label: WorkoutResource.metricPace,
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

class _RouteHistoryPainter extends CustomPainter {
  final List<LatLng> points;

  const _RouteHistoryPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.bgRadialBlue.withValues(alpha: 0.72),
          AppColors.bgPrimary,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final routeOffsets = _normalize(points, size);
    if (routeOffsets.isEmpty) return;

    final gridPaint = Paint()
      ..color = AppColors.gridLine.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final x = size.width * i / 4;
      final y = size.height * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (routeOffsets.length == 1) {
      _drawMarker(canvas, routeOffsets.first, AppColors.brandGreen);
      return;
    }

    final route = Path()..moveTo(routeOffsets.first.dx, routeOffsets.first.dy);
    for (final point in routeOffsets.skip(1)) {
      route.lineTo(point.dx, point.dy);
    }

    final glowPaint = Paint()
      ..color = AppColors.brandGreen.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 14;
    final routePaint = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.accentCyan, AppColors.brandGreenLight],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 4.5;

    canvas.drawPath(route, glowPaint);
    canvas.drawPath(route, routePaint);
    _drawMarker(canvas, routeOffsets.first, AppColors.accentCyan);
    _drawMarker(canvas, routeOffsets.last, AppColors.brandGreen);
  }

  List<Offset> _normalize(List<LatLng> source, Size size) {
    if (source.isEmpty) return const [];

    var minLat = source.first.latitude;
    var maxLat = source.first.latitude;
    var minLng = source.first.longitude;
    var maxLng = source.first.longitude;
    for (final point in source) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    final latSpan = math.max(maxLat - minLat, 0.00001);
    final lngSpan = math.max(maxLng - minLng, 0.00001);
    final padding = math.min(size.width, size.height) * 0.16;
    final drawWidth = math.max(size.width - padding * 2, 1);
    final drawHeight = math.max(size.height - padding * 2, 1);

    return [
      for (final point in source)
        Offset(
          padding + ((point.longitude - minLng) / lngSpan) * drawWidth,
          padding + ((maxLat - point.latitude) / latSpan) * drawHeight,
        ),
    ];
  }

  void _drawMarker(Canvas canvas, Offset center, Color color) {
    canvas.drawCircle(
      center,
      8,
      Paint()..color = color.withValues(alpha: 0.22),
    );
    canvas.drawCircle(center, 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _RouteHistoryPainter oldDelegate) {
    return oldDelegate.points != points;
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
