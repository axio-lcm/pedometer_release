import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/workout/model/location_display_policy.dart';
import 'package:pedometer/feature/workout/model/location_stability_filter.dart';
import 'package:pedometer/feature/workout/model/map_coordinate_converter.dart';
import 'package:pedometer/feature/workout/model/workout_location_marker_style.dart';
import 'package:pedometer/feature/workout/model/workout_location_startup_policy.dart';
import 'package:pedometer/feature/workout/model/workout_map_render_policy.dart';
import 'package:pedometer/feature/workout/model/workout_map_style.dart';
import 'package:pedometer/feature/workout/model/workout_map_zoom_policy.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';
import 'package:pedometer/feature/workout/model/workout_route_polyline_policy.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';
import 'package:pedometer/feature/workout/service/workout_location_service.dart';
import 'package:get/get.dart';
import 'package:pedometer/feature/workout/viewmodel/workout_tracking_view_model.dart';

/// 红框标准区域对应的地图容器：底层后续替换为真实地图，浮层保持不变。
class WorkoutMapSection extends StatefulWidget {
  final WorkoutTrackingData data;
  final WorkoutTrackingViewModel controller;
  final bool showMoreMenu;
  final VoidCallback? onDismissMoreMenu;
  final VoidCallback? onImportMusic;
  final VoidCallback? onWorkoutRoute;
  final bool controlsLocked;

  const WorkoutMapSection({
    super.key,
    required this.data,
    required this.controller,
    this.showMoreMenu = false,
    this.onDismissMoreMenu,
    this.onImportMusic,
    this.onWorkoutRoute,
    this.controlsLocked = false,
  });

  @override
  WorkoutMapSectionState createState() => WorkoutMapSectionState();
}

class WorkoutMapSectionState extends State<WorkoutMapSection> {
  final _mapKey = GlobalKey<_WorkoutMapViewState>();

  Future<Uint8List?> takeSnapshot() async {
    return _mapKey.currentState?.takeSnapshot();
  }

  @override
  Widget build(BuildContext context) {
    // 室内运动无 GPS 轨迹：用纯色背景替代地图，且不展示定位按钮。
    final indoor = widget.controller.isIndoor.value;
    return SizedBox(
      height: 386,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: widget.controlsLocked,
              child: indoor
                  ? const ColoredBox(color: WorkoutResource.indoorBackground)
                  : WorkoutMapView(key: _mapKey, controller: widget.controller),
            ),
          ),
          Obx(() {
            final data = _liveData();
            if (data.status == WorkoutStatus.ended) {
              return Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.lg,
                child: WorkoutEndedMapSummary(data: data),
              );
            }
            // 室内：累积里程固定居中显示，点击开始不变换位置。
            return indoor
                ? _FixedDistanceOverlayAnchor(data: data)
                : _AnimatedDistanceOverlayAnchor(data: data);
          }),
          if (!indoor)
            Positioned(
              left: 14,
              bottom: 24,
              child: MapControlButtons(
                onLocate: widget.controlsLocked
                    ? null
                    : () => _mapKey.currentState?.centerOnCurrentLocation(),
              ),
            ),
          if (widget.showMoreMenu && !widget.controlsLocked) ...[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: widget.onDismissMoreMenu,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.lg,
              child: WorkoutMapMoreMenu(
                onImportMusic: widget.onImportMusic,
                onWorkoutRoute: widget.onWorkoutRoute,
              ),
            ),
          ],
        ],
      ),
    );
  }

  WorkoutTrackingData _liveData() {
    return widget.data.copyWith(
      status: widget.controller.status.value,
      distanceKm: widget.controller.distanceKmText,
      duration: widget.controller.durationText,
      calories: widget.controller.caloriesText,
      pace: widget.controller.paceText,
    );
  }
}

/// 地图区域右上角的更多菜单：垂直展示导入音乐 / 运动轨迹。
class WorkoutMapMoreMenu extends StatelessWidget {
  final VoidCallback? onImportMusic;
  final VoidCallback? onWorkoutRoute;

  const WorkoutMapMoreMenu({
    super.key,
    this.onImportMusic,
    this.onWorkoutRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(AppColors.surfaceCardTop, AppColors.bgPrimary),
            Color.alphaBlend(AppColors.surfaceCardBottom, AppColors.bgPrimary),
          ],
        ),
        border: Border.all(color: AppColors.strokeCard, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _WorkoutMapMoreMenuItem(
            icon: Icons.library_music_rounded,
            label: WorkoutResource.trackingImportMusic,
            onTap: onImportMusic,
          ),
          Divider(height: 1, color: AppColors.divider),
          _WorkoutMapMoreMenuItem(
            icon: Icons.route_rounded,
            label: WorkoutResource.trackingRoute,
            onTap: onWorkoutRoute,
          ),
        ],
      ),
    );
  }
}

class _WorkoutMapMoreMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _WorkoutMapMoreMenuItem({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            SizedBox(width: AppSpacing.md),
            Icon(icon, color: AppColors.brandGreen, size: 20),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class WorkoutMapView extends StatefulWidget {
  final WorkoutTrackingViewModel controller;

  const WorkoutMapView({super.key, required this.controller});

  @override
  State<WorkoutMapView> createState() => _WorkoutMapViewState();
}

class _WorkoutMapViewState extends State<WorkoutMapView> {
  static const _defaultCameraPosition = CameraPosition(
    target: LatLng(31.2304, 121.4737),
    zoom: WorkoutMapZoomPolicy.defaultZoom,
  );
  static const _cameraMoveThrottle = Duration(milliseconds: 900);
  static const _cameraAnimationTimeout = Duration(milliseconds: 700);
  static const _headingPaintInterval = Duration(milliseconds: 160);
  static const _headingPaintDelta = 3.0;

  // 显示层：决定“是否显示当前位置 + 状态文案”，对粗定位宽松。
  final _displayPolicy = const LocationDisplayPolicy();
  // 抖动抑制：仅用于过滤不可能的跳变，精度上限放宽到与显示层一致，
  // 避免再次把粗定位整体丢弃导致卡死。
  final _stabilityFilter = LocationStabilityFilter(maxAccuracyMeters: 200);
  final _locationService = WorkoutLocationService();

  WorkoutTrackingViewModel get _controller => widget.controller;

  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<double>? _compassSubscription;
  Worker? _statusWorker;
  BitmapDescriptor? _currentLocationMarkerIcon;
  LatLng? _currentPosition;
  double _currentZoom = WorkoutMapZoomPolicy.defaultZoom;
  bool _locationAuthorized = false;
  bool? _positionStreamUsesTrackingSettings;
  bool _cameraMoving = false;
  DateTime? _lastCameraMoveAt;
  DateTime? _lastHeadingPaintAt;
  // 设备罗盘朝向（度，0=正北，顺时针）。驱动当前位置箭头随手机方向旋转。
  double _headingDegrees = 0;

  @override
  void initState() {
    super.initState();
    if (!_isWidgetTest) {
      _statusWorker = ever<WorkoutStatus>(
        _controller.status,
        _handleWorkoutStatusChanged,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_loadCurrentLocationMarkerIcon());
        unawaited(_prepareLocation());
        _startCompass();
      });
    }
  }

  void _startCompass() {
    final stream = _locationService.headingStream();
    if (stream == null) return; // 设备无磁力计
    _compassSubscription = stream.listen((heading) {
      if (!mounted) return;
      if (_currentPosition == null || _currentLocationMarkerIcon == null) {
        return;
      }
      // 仅在朝向变化明显时刷新，避免高频重建。
      final delta = (heading - _headingDegrees).abs();
      final normalizedDelta = delta > 180 ? 360 - delta : delta;
      if (_headingDegrees != 0 && normalizedDelta < _headingPaintDelta) {
        return;
      }
      final now = DateTime.now();
      final lastPaint = _lastHeadingPaintAt;
      if (lastPaint != null &&
          now.difference(lastPaint) < _headingPaintInterval) {
        return;
      }
      _lastHeadingPaintAt = now;
      setState(() => _headingDegrees = heading);
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _compassSubscription?.cancel();
    _statusWorker?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canCreatePlatformMap = WorkoutMapRenderPolicy.canCreatePlatformMap(
      isWidgetTest: _isWidgetTest,
    );

    if (!canCreatePlatformMap) {
      return Stack(
        key: const Key('workout-google-map'),
        children: [const Positioned.fill(child: _WorkoutMapFallback())],
      );
    }

    return Stack(
      key: const Key('workout-google-map'),
      children: [
        Positioned.fill(
          child: Obx(() {
            final routePoints = _routePointsForDisplay();
            return GoogleMap(
              style: WorkoutMapStyle.night,
              initialCameraPosition: _currentPosition == null
                  ? _defaultCameraPosition
                  : CameraPosition(
                      target: _currentPosition!,
                      zoom: _currentZoom,
                    ),
              minMaxZoomPreference: const MinMaxZoomPreference(
                WorkoutMapZoomPolicy.minZoom,
                WorkoutMapZoomPolicy.maxZoom,
              ),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              markers: _trackingMarkers,
              polylines: WorkoutRoutePolylinePolicy.build(routePoints),
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: false,
              onCameraMove: (position) {
                _currentZoom = WorkoutMapZoomPolicy.clampZoom(position.zoom);
              },
              onMapCreated: (controller) {
                _mapController = controller;
                final position = _currentPosition;
                if (position != null) {
                  unawaited(_moveCamera(position, immediate: true));
                }
              },
            );
          }),
        ),
      ],
    );
  }

  Future<void> _prepareLocation() async {
    try {
      final authorized = await _locationService.ensureAuthorized();
      if (!mounted) return;
      if (!authorized) return;

      _locationAuthorized = true;
      await _seedLastKnownPosition();
      if (!mounted) return;
      final status = _controller.status.value;
      final tracking = _usesTrackingLocationSettings(status);
      _syncPositionStreamWithStatus(status);
      if (tracking) {
        unawaited(_requestPreciseLocationIfNeeded());
      }
      unawaited(_refreshCurrentPosition(tracking: tracking));
    } on TimeoutException {
      if (!mounted) return;
      _locationAuthorized = true;
      _syncPositionStreamWithStatus(_controller.status.value);
    } catch (_) {
      if (!mounted) return;
      return;
    }
  }

  void _handleWorkoutStatusChanged(WorkoutStatus status) {
    if (!_locationAuthorized || !mounted) return;
    _syncPositionStreamWithStatus(status);
    if (_usesTrackingLocationSettings(status)) {
      unawaited(_requestPreciseLocationIfNeeded());
      unawaited(_refreshCurrentPosition(tracking: true));
    }
  }

  void _syncPositionStreamWithStatus(WorkoutStatus status) {
    if (status == WorkoutStatus.ended) {
      unawaited(_positionSubscription?.cancel());
      _positionSubscription = null;
      _positionStreamUsesTrackingSettings = null;
      return;
    }
    _startPositionStream(tracking: _usesTrackingLocationSettings(status));
  }

  bool _usesTrackingLocationSettings(WorkoutStatus status) {
    return status == WorkoutStatus.running || status == WorkoutStatus.paused;
  }

  void _startPositionStream({required bool tracking}) {
    if (_positionSubscription != null &&
        _positionStreamUsesTrackingSettings == tracking) {
      return;
    }
    unawaited(_positionSubscription?.cancel());
    _positionSubscription = null;
    _positionStreamUsesTrackingSettings = tracking;
    _positionSubscription = _locationService
        .positionStream(tracking: tracking)
        .listen(_acceptPosition, onError: _handlePositionError);
  }

  Future<void> _seedLastKnownPosition() async {
    try {
      final cached = await _locationService.lastKnownPosition();
      if (cached == null || !mounted) return;
      if (!WorkoutLocationStartupPolicy.canUseCachedPosition(
        recordedAt: cached.timestamp,
        now: DateTime.now(),
      )) {
        return;
      }

      _acceptPosition(cached);
    } catch (_) {
      // Cached location is only a startup accelerator. Live location still follows.
    }
  }

  Future<void> _refreshCurrentPosition({required bool tracking}) async {
    try {
      final current = await _locationService.currentPosition(
        tracking: tracking,
      );
      _acceptPosition(current);
    } on TimeoutException {
      // 首帧定位超时：等待实时定位流补位。
    } catch (_) {
      // 定位暂不可用：等待实时定位流补位。
    }
  }

  void _handlePositionError(Object _) {
    // 定位流报错：忽略，等待后续定位点恢复。
  }

  Future<void> _requestPreciseLocationIfNeeded() async {
    try {
      await _locationService.requestPreciseLocationIfNeeded();
    } catch (_) {
      // Android and older iOS versions may not need or support this flow.
    }
  }

  void _acceptPosition(Position position) {
    if (!mounted) return;

    // 第一关：能不能显示。粗定位也接受，只在真正无效/过差时才继续等待。
    final decision = _displayPolicy.evaluate(accuracyMeters: position.accuracy);
    if (!decision.showOnMap) return;

    // 第二关：抖动抑制。跳变过大的点不挪动相机/标记，但绝不卡死。
    final coordinate = WorkoutCoordinate(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    final isFirstFix = _currentPosition == null;
    final isStable = _stabilityFilter.shouldAccept(
      coordinate,
      accuracyMeters: position.accuracy,
      recordedAt: position.timestamp,
    );

    final rawCoordinate = WorkoutMapCoordinate(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    final displayCoordinate = MapCoordinateConverter.wgs84ToGcj02(
      rawCoordinate,
    );
    final latLng = LatLng(
      displayCoordinate.latitude,
      displayCoordinate.longitude,
    );
    setState(() {
      if (isStable || isFirstFix) {
        _currentPosition = latLng;
        if (isFirstFix) {
          _currentZoom = WorkoutMapZoomPolicy.trackingZoom;
        }
      }
    });

    if (isStable || isFirstFix) {
      unawaited(_moveCamera(latLng, immediate: isFirstFix));
    }
    _controller.onFix(position, latLng);
  }

  Future<void> _moveCamera(LatLng target, {bool immediate = false}) async {
    final controller = _mapController;
    if (controller == null) return;

    final now = DateTime.now();
    if (!immediate) {
      final lastMove = _lastCameraMoveAt;
      if (_cameraMoving ||
          (lastMove != null &&
              now.difference(lastMove) < _cameraMoveThrottle)) {
        return;
      }
    }

    _cameraMoving = true;
    _lastCameraMoveAt = now;
    final update = CameraUpdate.newCameraPosition(
      CameraPosition(target: target, zoom: _currentZoom),
    );
    try {
      if (immediate) {
        await controller.moveCamera(update);
      } else {
        await controller.animateCamera(update).timeout(_cameraAnimationTimeout);
      }
    } catch (_) {
      // Platform-map camera calls can fail during creation/disposal races.
    } finally {
      _cameraMoving = false;
    }
  }

  Future<void> centerOnCurrentLocation() async {
    final position = _currentPosition;
    if (position == null) return;
    await _moveCamera(position, immediate: true);
  }

  Future<Uint8List?> takeSnapshot() async {
    return _mapController?.takeSnapshot();
  }

  List<LatLng> _routePointsForDisplay() {
    final route = _controller.pathPoints.toList(growable: true);
    final start = _controller.startPoint.value;
    final end = _controller.endPoint.value;
    if (route.isEmpty) {
      if (start != null) route.add(start);
      if (end != null && (route.isEmpty || route.last != end)) route.add(end);
      return route;
    }
    if (start != null && route.first != start) route.insert(0, start);
    if (end != null && route.last != end) route.add(end);
    return route;
  }

  Set<Marker> get _trackingMarkers {
    final markers = <Marker>{};

    final start = _controller.startPoint.value;
    if (start != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('workout-start'),
          position: start,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          anchor: const Offset(0.5, 1),
          zIndexInt: 1,
        ),
      );
    }

    final end = _controller.endPoint.value;
    if (end != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('workout-end'),
          position: end,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          anchor: const Offset(0.5, 1),
          zIndexInt: 2,
        ),
      );
    }

    final position = _currentPosition;
    final icon = _currentLocationMarkerIcon;
    if (position != null &&
        icon != null &&
        _controller.status.value != WorkoutStatus.ended) {
      markers.add(
        Marker(
          markerId: const MarkerId('workout-current-location'),
          position: position,
          anchor: WorkoutLocationMarkerStyle.anchor,
          icon: icon,
          // 箭头随设备罗盘朝向旋转（站着转手机也会转）。
          rotation: _headingDegrees,
          flat: true,
          zIndexInt: 3,
        ),
      );
    }

    return markers;
  }

  Future<void> _loadCurrentLocationMarkerIcon() async {
    final icon = await _createCurrentLocationMarkerIcon();
    if (!mounted) return;
    setState(() => _currentLocationMarkerIcon = icon);
  }

  Future<BitmapDescriptor> _createCurrentLocationMarkerIcon() async {
    final bytes = await _drawCurrentLocationMarkerPng();
    return BitmapDescriptor.bytes(
      bytes,
      width: WorkoutLocationMarkerStyle.logicalSize.width,
      height: WorkoutLocationMarkerStyle.logicalSize.height,
      imagePixelRatio: WorkoutLocationMarkerStyle.renderPixelRatio,
    );
  }

  Future<Uint8List> _drawCurrentLocationMarkerPng() async {
    const pixelRatio = WorkoutLocationMarkerStyle.renderPixelRatio;
    final width = (WorkoutLocationMarkerStyle.logicalSize.width * pixelRatio)
        .round();
    final height = (WorkoutLocationMarkerStyle.logicalSize.height * pixelRatio)
        .round();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(
        0,
        0,
        WorkoutLocationMarkerStyle.logicalSize.width,
        WorkoutLocationMarkerStyle.logicalSize.height,
      ),
    )..scale(pixelRatio);

    final center = WorkoutLocationMarkerStyle.dotCenter;
    const coneRadius = WorkoutLocationMarkerStyle.coneRadius;
    const halfAngle = WorkoutLocationMarkerStyle.coneHalfAngleRad;

    // 方向光锥：从圆点向「上」（-90°，画布 y 轴向下）张开的扇形，
    // 旋转 marker.rotation = bearing 时整体转向实际行进方向。
    final startAngle = -math.pi / 2 - halfAngle;
    const sweepAngle = 2 * halfAngle;
    final conePath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: coneRadius),
        startAngle,
        sweepAngle,
        false,
      )
      ..close();

    // 径向渐变：圆点处较实、向外淡出，营造 Google 风格的方向光束。
    final coneShader = ui.Gradient.radial(
      center,
      coneRadius,
      const [Color(0xCC4285F4), Color(0x554285F4), Color(0x004285F4)],
      const [0.0, 0.55, 1.0],
    );
    canvas.drawPath(conePath, Paint()..shader = coneShader);

    canvas.drawCircle(
      center,
      WorkoutLocationMarkerStyle.whiteRingRadius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2),
    );
    canvas.drawCircle(
      center,
      WorkoutLocationMarkerStyle.whiteRingRadius,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      center,
      WorkoutLocationMarkerStyle.dotRadius,
      Paint()..color = const Color(0xFF4285F4),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();

    return byteData!.buffer.asUint8List();
  }

  bool get _isWidgetTest {
    return WidgetsBinding.instance.runtimeType.toString().contains(
      'TestWidgetsFlutterBinding',
    );
  }
}

class _WorkoutMapFallback extends StatelessWidget {
  const _WorkoutMapFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bgPrimary,
            AppColors.bgRadialBlue.withValues(alpha: 0.82),
            AppColors.bgPrimary,
          ],
        ),
      ),
      child: CustomPaint(painter: _MapPlaceholderPainter()),
    );
  }
}

class RoutePolylineLayer extends StatelessWidget {
  const RoutePolylineLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _RoutePainter());
  }
}

class _AnimatedDistanceOverlayAnchor extends StatelessWidget {
  final WorkoutTrackingData data;

  const _AnimatedDistanceOverlayAnchor({required this.data});

  static const _duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final compact = data.status == WorkoutStatus.running;
    return AnimatedPositioned(
      duration: _duration,
      curve: Curves.easeOutCubic,
      top: compact ? 360 : 96,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedScale(
          duration: _duration,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          scale: compact ? 0.96 : 1,
          child: WorkoutDistanceOverlay(data: data, compact: compact),
        ),
      ),
    );
  }
}

/// 室内运动的累积里程展示：固定居中，开始 / 暂停均不改变位置或大小。
class _FixedDistanceOverlayAnchor extends StatelessWidget {
  final WorkoutTrackingData data;

  const _FixedDistanceOverlayAnchor({required this.data});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 96,
      left: 0,
      right: 0,
      child: Center(child: WorkoutDistanceOverlay(data: data)),
    );
  }
}

class WorkoutDistanceOverlay extends StatelessWidget {
  final WorkoutTrackingData data;
  final bool compact;

  const WorkoutDistanceOverlay({
    super.key,
    required this.data,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      const compactFontSize = 15.0;
      const compactValueFontSize = 25.0;
      return SizedBox(
        width: 330,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                WorkoutResource.trackingDistanceLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: compactFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              data.distanceKm,
              maxLines: 1,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: compactValueFontSize,
                height: 1,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.85),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                WorkoutResource.trackingTarget(data.targetKm),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: compactFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: 190,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            WorkoutResource.trackingDistanceLabel,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              data.distanceKm,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 78,
                height: 0.98,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.85),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            WorkoutResource.trackingTarget(data.targetKm),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class WorkoutEndedMapSummary extends StatelessWidget {
  final WorkoutTrackingData data;

  const WorkoutEndedMapSummary({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.lg,
      padding: EdgeInsets.all(AppSpacing.lg),
      borderColor: AppColors.strokeGreen,
      child: Row(
        children: [
          Expanded(
            child: _EndedMetric(
              label: WorkoutResource.metricDistance,
              value: data.distanceKm,
            ),
          ),
          Expanded(
            child: _EndedMetric(
              label: WorkoutResource.metricDuration,
              value: data.duration,
            ),
          ),
          Expanded(
            child: _EndedMetric(
              label: WorkoutResource.metricPace,
              value: data.pace,
            ),
          ),
        ],
      ),
    );
  }
}

class _EndedMetric extends StatelessWidget {
  final String label;
  final String value;

  const _EndedMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class MapControlButtons extends StatelessWidget {
  final VoidCallback? onLocate;

  const MapControlButtons({super.key, this.onLocate});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleGlassIconButton(icon: Icons.my_location_rounded, onTap: onLocate),
      ],
    );
  }
}

class WorkoutMetricPanel extends StatelessWidget {
  final WorkoutTrackingData data;

  const WorkoutMetricPanel({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xl,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: WorkoutMetricItem(
              icon: Icons.schedule_rounded,
              iconColor: AppColors.brandGreen,
              label: WorkoutResource.metricDuration,
              value: data.duration,
            ),
          ),
          _MetricDivider(),
          Expanded(
            child: WorkoutMetricItem(
              icon: Icons.local_fire_department_rounded,
              iconColor: AppColors.accentOrange,
              label: WorkoutResource.metricCalorieKcal,
              value: data.calories,
            ),
          ),
          _MetricDivider(),
          Expanded(
            child: WorkoutMetricItem(
              icon: Icons.speed_rounded,
              iconColor: AppColors.accentCyan,
              label: WorkoutResource.metricPaceMinKm,
              value: data.pace,
            ),
          ),
        ],
      ),
    );
  }
}

class WorkoutMetricItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const WorkoutMetricItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 21),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 44, color: AppColors.divider);
  }
}

class WorkoutControlPanel extends StatelessWidget {
  final WorkoutTrackingData data;
  final VoidCallback? onPrimaryTap;
  final bool locked;
  final VoidCallback? onLockToggle;
  final bool muted;
  final VoidCallback? onMuteToggle;

  /// 长按主按钮满 3 秒后触发（结束运动）。
  final VoidCallback? onEnd;

  const WorkoutControlPanel({
    super.key,
    required this.data,
    this.onPrimaryTap,
    this.locked = false,
    this.onLockToggle,
    this.muted = false,
    this.onMuteToggle,
    this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    // 仅运动中 / 暂停时允许长按结束（与「长按结束」提示一致）。
    final holdEnabled =
        !locked &&
        (data.status == WorkoutStatus.running ||
            data.status == WorkoutStatus.paused);
    final hintText = switch (data.status) {
      WorkoutStatus.ready => WorkoutResource.trackingStartHint,
      WorkoutStatus.running => data.endHint,
      WorkoutStatus.paused => data.endHint,
      WorkoutStatus.ended => null,
    };
    return SizedBox(
      height: 108,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CircleGlassIconButton(
                  icon: locked ? Icons.lock_rounded : Icons.lock_open_rounded,
                  onTap: onLockToggle,
                ),
                NeonPauseButton(
                  showStartIcon: data.status != WorkoutStatus.running,
                  onTap: locked ? null : onPrimaryTap,
                  onHoldComplete: holdEnabled ? onEnd : null,
                ),
                CircleGlassIconButton(
                  icon: muted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  onTap: locked ? null : onMuteToggle,
                ),
              ],
            ),
          ),
          if (hintText != null)
            Positioned(
              top: 112,
              left: 0,
              right: 0,
              child: Text(
                hintText,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

class CircleGlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  const CircleGlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 56,
    this.iconSize = 27,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.surfaceCardTop, AppColors.surfaceCardBottom],
          ),
          border: Border.all(color: AppColors.strokeCard),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.36),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: iconSize),
      ),
    );
  }
}

/// 主控制按钮：点击切换开始/暂停；当 [onHoldComplete] 非空时支持长按蓄力，
/// 按住满 [holdDuration]（默认 3 秒）触发 [onHoldComplete]，并显示环形蓄力进度。
class NeonPauseButton extends StatefulWidget {
  final bool showStartIcon;
  final VoidCallback? onTap;
  final VoidCallback? onHoldComplete;
  final Duration holdDuration;

  const NeonPauseButton({
    super.key,
    required this.showStartIcon,
    this.onTap,
    this.onHoldComplete,
    this.holdDuration = const Duration(seconds: 3),
  });

  @override
  State<NeonPauseButton> createState() => _NeonPauseButtonState();
}

class _NeonPauseButtonState extends State<NeonPauseButton>
    with SingleTickerProviderStateMixin {
  static const _holdActivationDelay = Duration(milliseconds: 220);

  late final AnimationController _hold;
  Timer? _holdStartTimer;
  bool _completed = false;

  bool get _holdEnabled => widget.onHoldComplete != null;

  @override
  void initState() {
    super.initState();
    _hold = AnimationController(vsync: this, duration: widget.holdDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _completed = true;
          widget.onHoldComplete?.call();
        }
      });
  }

  @override
  void dispose() {
    _holdStartTimer?.cancel();
    _hold.dispose();
    super.dispose();
  }

  void _handlePressStart() {
    if (!_holdEnabled) return;
    _completed = false;
    _holdStartTimer?.cancel();
    _holdStartTimer = Timer(_holdActivationDelay, () {
      if (!mounted || !_holdEnabled) return;
      _hold.forward(from: 0);
    });
  }

  void _handleHoldRelease() {
    _holdStartTimer?.cancel();
    if (_holdEnabled && !_completed) _hold.reset();
  }

  void _handleTap() {
    // 长按已触发结束，忽略随后的 tap，避免误切换状态。
    if (_completed) {
      _completed = false;
      _hold.reset();
      return;
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _handlePressStart(),
      onPointerUp: (_) => _handleHoldRelease(),
      onPointerCancel: (_) => _handleHoldRelease(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: SizedBox(
          width: 108,
          height: 108,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.brandLime,
                      AppColors.brandGreen,
                      AppColors.brandGreenDark,
                    ],
                    stops: const [0, 0.62, 1],
                  ),
                ),
                child: Icon(
                  widget.showStartIcon
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  color: AppColors.bgPrimary,
                  size: 56,
                ),
              ),
              if (_holdEnabled)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _hold,
                    builder: (_, _) =>
                        CustomPaint(painter: _HoldRingPainter(_hold.value)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoldRingPainter extends CustomPainter {
  final double progress;

  _HoldRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: size.width / 2 - 3);
    const start = -math.pi / 2;
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    final glow = Paint()
      ..color = AppColors.brandLime.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final paint = Paint()
      ..color = AppColors.brandLime
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, glow);
    canvas.drawArc(rect, start, sweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant _HoldRingPainter old) =>
      old.progress != progress;
}

class WorkoutMusicCard extends StatelessWidget {
  final WorkoutTrackingData data;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onOpenList;

  const WorkoutMusicCard({
    super.key,
    required this.data,
    this.onPlayPause,
    this.onNext,
    this.onOpenList,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpenList,
      child: GlassCard(
        radius: AppRadius.lg,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                color: AppColors.brandGreen.withValues(alpha: 0.18),
              ),
              child: Icon(
                Icons.music_note_rounded,
                color: AppColors.brandLime,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.musicTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.musicStatus,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onPlayPause,
              icon: Icon(
                data.musicPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: data.hasMusic
                    ? AppColors.brandGreen
                    : AppColors.textSecondary,
                size: 34,
              ),
            ),
            IconButton(
              onPressed: data.hasMusic ? onNext : null,
              icon: Icon(
                Icons.skip_next_rounded,
                color: data.hasMusic
                    ? AppColors.brandGreen
                    : AppColors.textSecondary.withValues(alpha: 0.45),
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = AppColors.gridLine.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final blockPaint = Paint()
      ..color = AppColors.brandGreenDark.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 9; i++) {
      final y = size.height * (0.16 + i * 0.095);
      final path = Path()
        ..moveTo(-20, y)
        ..quadraticBezierTo(
          size.width * 0.28,
          y - 22,
          size.width * 0.54,
          y + 12,
        )
        ..quadraticBezierTo(size.width * 0.78, y + 34, size.width + 20, y - 14);
      canvas.drawPath(path, roadPaint);
    }

    for (var i = 0; i < 7; i++) {
      final x = size.width * (0.08 + i * 0.14);
      final path = Path()
        ..moveTo(x, 0)
        ..quadraticBezierTo(x + 28, size.height * 0.38, x - 18, size.height)
        ..moveTo(x + 48, 0)
        ..quadraticBezierTo(x + 20, size.height * 0.5, x + 64, size.height);
      canvas.drawPath(path, roadPaint);
    }

    for (var i = 0; i < 12; i++) {
      final left = size.width * ((i * 37 % 100) / 100);
      final top = size.height * ((i * 23 % 92) / 100);
      final rect = Rect.fromLTWH(
        left,
        top,
        30 + (i % 3) * 14,
        20 + (i % 2) * 18,
      );
      canvas.save();
      canvas.rotate((i.isEven ? 1 : -1) * math.pi / 90);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        blockPaint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final route = Path()
      ..moveTo(size.width * 0.29, size.height * 0.62)
      ..cubicTo(
        size.width * 0.42,
        size.height * 0.58,
        size.width * 0.44,
        size.height * 0.48,
        size.width * 0.56,
        size.height * 0.46,
      )
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.44,
        size.width * 0.68,
        size.height * 0.54,
        size.width * 0.80,
        size.height * 0.45,
      );

    final glowPaint = Paint()
      ..color = AppColors.brandGreen.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final basePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.accentOrange,
          AppColors.brandGreenLight,
          AppColors.brandGreen,
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(route, glowPaint);
    canvas.drawPath(route, basePaint);
    _drawPoint(
      canvas,
      Offset(size.width * 0.29, size.height * 0.62),
      AppColors.accentOrange,
      8,
    );
    _drawPoint(
      canvas,
      Offset(size.width * 0.80, size.height * 0.45),
      AppColors.brandGreen,
      10,
    );
  }

  void _drawPoint(Canvas canvas, Offset center, Color color, double radius) {
    final glow = Paint()
      ..color = color.withValues(alpha: 0.34)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final fill = Paint()..color = color;
    final inner = Paint()..color = AppColors.textPrimary.withValues(alpha: 0.8);
    canvas.drawCircle(center, radius + 12, glow);
    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(center, radius * 0.46, inner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
