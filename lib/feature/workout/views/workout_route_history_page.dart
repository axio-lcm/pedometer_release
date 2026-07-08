import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/component/asset_metric_icon.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/workout/model/workout_map_render_policy.dart';
import 'package:pedometer/feature/workout/model/workout_map_style.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';
import 'package:pedometer/feature/workout/model/workout_route_polyline_policy.dart';
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
    final record = this.record;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTopNavigationBar(
          title: WorkoutResource.routeHistoryDetailTitle,
          onBack: onBack,
        ),
        SizedBox(height: AppSpacing.lg),
        if (record == null)
          _CurrentRouteCard(
            title: WorkoutResource.routeHistoryEmpty,
            points: const [],
            distance: '0.00',
            duration: '00:00:00',
            pace: "--'--''",
            startPoint: null,
            endPoint: null,
          )
        else
          FutureBuilder<WorkoutRouteHistoryRecord?>(
            future: record.routeLoaded
                ? Future.value(record)
                : WorkoutRouteHistoryStore.loadDetail(record.id),
            initialData: record,
            builder: (context, snapshot) {
              final detail = snapshot.data ?? record;
              return _CurrentRouteCard(
                title: WorkoutResource.localizedWorkoutTypeTitle(
                  detail.sportType,
                ),
                points: detail.routePoints,
                distance: detail.distanceKm,
                duration: detail.duration,
                pace: detail.averagePace,
                startPoint: detail.startPoint,
                endPoint: detail.endPoint,
              );
            },
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

  const _CurrentRouteCard({
    required this.title,
    required this.points,
    required this.distance,
    required this.duration,
    required this.pace,
    required this.startPoint,
    required this.endPoint,
  });

  @override
  Widget build(BuildContext context) {
    final workoutType = _workoutTypeFor(title);
    final routePoints = _normalizeRoutePoints(
      points: points,
      startPoint: startPoint,
      endPoint: endPoint,
    );
    return GlassCard(
      radius: AppRadius.xl,
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _RouteDetailWorkoutTypeIcon(type: workoutType),
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
                child: routePoints.isNotEmpty
                    ? _SavedRouteMapView(points: routePoints)
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

  WorkoutType _workoutTypeFor(String title) {
    return WorkoutPageData.mock.workoutTypes.firstWhere(
      (type) => type.title == title,
      orElse: () => WorkoutPageData.mock.workoutTypes.first,
    );
  }

  List<LatLng> _normalizeRoutePoints({
    required List<LatLng> points,
    required LatLng? startPoint,
    required LatLng? endPoint,
  }) {
    final route = <LatLng>[];
    if (startPoint != null) _appendIfDistinct(route, startPoint);
    for (final point in points) {
      _appendIfDistinct(route, point);
    }
    if (endPoint != null) _appendIfDistinct(route, endPoint);
    return List<LatLng>.unmodifiable(route);
  }

  void _appendIfDistinct(List<LatLng> points, LatLng point) {
    if (points.isEmpty || !_samePoint(points.last, point)) {
      points.add(point);
    }
  }

  bool _samePoint(LatLng a, LatLng b) {
    return a.latitude == b.latitude && a.longitude == b.longitude;
  }
}

class _RouteDetailWorkoutTypeIcon extends StatelessWidget {
  final WorkoutType type;

  const _RouteDetailWorkoutTypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final iconAsset = type.iconAsset;
    if (iconAsset != null) {
      return SizedBox(
        width: 38,
        height: 38,
        child: Center(child: AssetMetricIcon(assetName: iconAsset, size: 38)),
      );
    }

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        color: type.color.withValues(alpha: 0.16),
        border: Border.all(color: type.color.withValues(alpha: 0.45)),
      ),
      child: Icon(type.icon, color: type.color, size: 22),
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

class _SavedRouteMapView extends StatefulWidget {
  final List<LatLng> points;

  const _SavedRouteMapView({required this.points});

  @override
  State<_SavedRouteMapView> createState() => _SavedRouteMapViewState();
}

class _SavedRouteMapViewState extends State<_SavedRouteMapView> {
  static const _defaultCameraPosition = CameraPosition(
    target: LatLng(31.2304, 121.4737),
    zoom: 15,
  );

  GoogleMapController? _mapController;
  bool _createMap = false;
  List<LatLng> _cachedPoints = const [];
  Set<Marker> _cachedMarkers = const {};
  Set<Polyline> _cachedPolylines = const {};

  bool get _isWidgetTest {
    return WidgetsBinding.instance.runtimeType.toString().contains(
      'TestWidgetsFlutterBinding',
    );
  }

  @override
  void initState() {
    super.initState();
    _refreshMapArtifacts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _createMap = true);
    });
  }

  @override
  void didUpdateWidget(covariant _SavedRouteMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameRoute(oldWidget.points, widget.points)) {
      _refreshMapArtifacts();
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitRoute());
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!WorkoutMapRenderPolicy.canCreatePlatformMap(
      isWidgetTest: _isWidgetTest,
    )) {
      return const _RouteMapFallback();
    }

    if (!_createMap) {
      return const _RouteMapFallback();
    }

    return GoogleMap(
      style: WorkoutMapStyle.night,
      initialCameraPosition: _initialCameraPosition(),
      minMaxZoomPreference: const MinMaxZoomPreference(3, 20),
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      markers: _cachedMarkers,
      polylines: _cachedPolylines,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: false,
      gestureRecognizers: {
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      },
      onMapCreated: (controller) {
        _mapController = controller;
        WidgetsBinding.instance.addPostFrameCallback((_) => _fitRoute());
      },
    );
  }

  CameraPosition _initialCameraPosition() {
    if (widget.points.isEmpty) return _defaultCameraPosition;
    return CameraPosition(target: widget.points.first, zoom: 15);
  }

  void _refreshMapArtifacts() {
    _cachedPoints = List<LatLng>.unmodifiable(widget.points);
    _cachedMarkers = _buildMarkers(_cachedPoints);
    _cachedPolylines = WorkoutRoutePolylinePolicy.build(_cachedPoints);
  }

  Set<Marker> _buildMarkers(List<LatLng> points) {
    if (points.isEmpty) return const {};
    final start = points.first;
    final end = points.last;
    return {
      Marker(
        markerId: const MarkerId('saved-route-start'),
        position: start,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        anchor: const Offset(0.5, 1),
      ),
      if (!_samePoint(start, end))
        Marker(
          markerId: const MarkerId('saved-route-end'),
          position: end,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          anchor: const Offset(0.5, 1),
        ),
    };
  }

  Future<void> _fitRoute() async {
    final controller = _mapController;
    if (controller == null || !mounted || widget.points.isEmpty) return;
    try {
      if (widget.points.length == 1) {
        await controller.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: widget.points.first, zoom: 15),
          ),
        );
        return;
      }
      await controller.moveCamera(
        CameraUpdate.newLatLngBounds(_boundsFor(widget.points), 48),
      );
    } catch (_) {
      // Platform-map camera calls can fail during creation/disposal races.
    }
  }

  LatLngBounds _boundsFor(List<LatLng> points) {
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final point in points.skip(1)) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  bool _sameRoute(List<LatLng> a, List<LatLng> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_samePoint(a[i], b[i])) return false;
    }
    return true;
  }

  bool _samePoint(LatLng a, LatLng b) {
    return a.latitude == b.latitude && a.longitude == b.longitude;
  }
}

class _RouteMapFallback extends StatelessWidget {
  const _RouteMapFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: AppColors.surfaceIcon.withValues(alpha: 0.44));
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
