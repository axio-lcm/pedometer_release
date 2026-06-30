import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/localized_text.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/common/service/motion_fitness_permission_service.dart';
import 'package:pedometer/common/service/photo_library_permission_service.dart';
import 'package:pedometer/feature/workout/model/achievement_stats_store.dart';
import 'package:pedometer/feature/workout/model/workout_calorie_policy.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';
import 'package:pedometer/feature/workout/model/workout_pace_policy.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';
import 'package:pedometer/feature/workout/viewmodel/workout_view_model.dart';

/// 户外运动会话 view model：持有实时距离 / 时长 / 卡路里 / 配速 / 轨迹 / 方位，
/// 作为运动追踪页与地图的唯一数据源。
class WorkoutTrackingViewModel extends GetxController
    implements IBaseViewModel {
  WorkoutTrackingViewModel({
    WorkoutCaloriePolicy? caloriePolicy,
    WorkoutPacePolicy? pacePolicy,
    this.template = WorkoutTrackingData.mock,
    this.minMoveMeters = 2.5,
    this.minRoutePointMeters = 1.5,
    this.maxMetricAccuracyMeters = 35,
    this.maxRouteAccuracyMeters = 35,
    this.maxMetricSpeedKmh = 30,
  }) : _caloriePolicy = caloriePolicy ?? const WorkoutCaloriePolicy(),
       _pacePolicy = pacePolicy ?? WorkoutPacePolicy();

  final WorkoutCaloriePolicy _caloriePolicy;
  final WorkoutPacePolicy _pacePolicy;
  AudioPlayer? _musicPlayer;

  /// 页面静态模板（标题 / 目标 / GPS / 音乐等），实时值由状态合并。
  /// 目标里程在 [init] 中与运动栏的目标设置同步。
  WorkoutTrackingData template;

  /// 小于该距离（米）的相邻定位不累计运动距离；可视轨迹另由
  /// [minRoutePointMeters] 控制。
  final double minMoveMeters;

  /// 地图可视轨迹的最低位移。它小于 [minMoveMeters]，用于让真机小范围
  /// 移动先出现路线，但不参与距离 / 配速 / 卡路里计算。
  final double minRoutePointMeters;

  /// 只有精度足够的 GPS 点才参与距离 / 配速 / 卡路里计算，避免弱信号漂移放大运动量。
  final double maxMetricAccuracyMeters;

  /// 只有精度足够的 GPS 点才进入可视轨迹；当前位置 marker 仍可显示较弱信号。
  final double maxRouteAccuracyMeters;

  /// 跑步 / 健走 / 徒步场景的异常速度上限；超过时认为该 GPS 段不可信。
  final double maxMetricSpeedKmh;

  final status = WorkoutStatus.ready.obs;
  final startPoint = Rxn<LatLng>();
  final endPoint = Rxn<LatLng>();
  final currentPosition = Rxn<LatLng>();
  final pathPoints = <LatLng>[].obs;
  final distanceMeters = 0.0.obs;
  final elapsed = Duration.zero.obs;
  final calories = 0.0.obs;
  final bearing = 0.0.obs;
  final pace = Rxn<Duration>();
  late final RxString workoutTitle = template.workoutTitle.obs;
  final musicTitle = WorkoutText.trackingMusicTitle.obs;
  final musicStatus = WorkoutText.trackingMusicIdle.obs;
  final hasMusic = false.obs;
  final musicPlaying = false.obs;
  final musicMuted = false.obs;
  final currentMusicIndex = (-1).obs;
  final musicTrackNames = <String>[].obs;

  /// 是否为室内运动：室内无 GPS 地图，运动区域显示纯色背景且累积里程固定居中。
  final isIndoor = false.obs;

  /// 定位放行信号：页面打开时为 false，地图只占位、不请求定位权限；
  /// 用户点「开始」且系统授权通过后由页面置 true，驱动地图首次启动定位。
  /// 这样把权限请求延后到用户表达运动意图之后（更低摩擦、更顺的合规叙事）。
  final locationActivated = false.obs;

  /// 室内会话累计步数（来自计步器，按会话基线增量累积）。
  final steps = 0.obs;

  Timer? _ticker;
  Position? _lastRaw; // 上一个被接受的原始定位（算距离 / 方位）
  Position? _currentRaw; // 最近一次定位，开始运动时用作第一段距离基准
  Position? _lastRouteRaw; // 上一个被画到地图轨迹上的原始定位
  double _lastSpeedKmh = 0; // 当前 tick 卡路里用的速度
  DateTime? _lastSpeedUpdatedAt;
  StreamSubscription<Duration>? _motionPaceSubscription;
  StreamSubscription<MotionFitnessSample>? _motionStepSubscription;
  double? _lastIndoorDistanceMeters; // 上一计步样本的当天累计距离（米）
  int? _lastIndoorSteps; // 上一计步样本的当天累计步数
  StreamSubscription<bool>? _musicPlayingSubscription;
  StreamSubscription<int?>? _musicIndexSubscription;
  DateTime? _lastMotionPaceAt;
  List<_WorkoutMusicTrack> _musicTracks = const [];
  bool _routeHistorySaved = false;

  static const _motionPaceFreshness = Duration(seconds: 10);
  static const _calorieSpeedFreshness = Duration(seconds: 5);
  static const _musicExtensions = <String>[
    'mp3',
    'm4a',
    'aac',
    'wav',
    'flac',
    'ogg',
  ];

  // ---- 状态机 ----

  /// 用户点「开始」且定位授权通过后调用：放行地图开始定位。
  void activateLocation() {
    if (!locationActivated.value) locationActivated.value = true;
  }

  void start() {
    if (status.value == WorkoutStatus.running) return;
    if (status.value == WorkoutStatus.paused) {
      resume();
      return;
    }
    if (status.value == WorkoutStatus.ended) return;

    distanceMeters.value = 0;
    steps.value = 0;
    _lastIndoorDistanceMeters = null;
    _lastIndoorSteps = null;
    elapsed.value = Duration.zero;
    calories.value = 0;
    pace.value = null;
    pathPoints.clear();
    endPoint.value = null;
    _pacePolicy.reset();
    _lastRaw = _usableMetricRawOrNull(_currentRaw);
    _lastRouteRaw = _usableRouteRawOrNull(_currentRaw);
    _lastSpeedKmh = 0;
    _lastSpeedUpdatedAt = null;
    _lastMotionPaceAt = null;
    _routeHistorySaved = false;

    final pos = _lastRouteRaw == null ? null : currentPosition.value;
    startPoint.value = pos;
    if (pos != null) pathPoints.add(pos);

    status.value = WorkoutStatus.running;
    _startTicker();
  }

  void pause() {
    if (status.value != WorkoutStatus.running) return;
    status.value = WorkoutStatus.paused;
    _stopTicker();
  }

  void resume() {
    if (status.value != WorkoutStatus.paused) return;
    status.value = WorkoutStatus.running;
    _startTicker();
  }

  void end() {
    endPoint.value =
        currentPosition.value ??
        (pathPoints.isEmpty ? startPoint.value : pathPoints.last);
    status.value = WorkoutStatus.ended;
    _stopTicker();
  }

  WorkoutRouteHistoryRecord saveRouteHistory({Uint8List? mapSnapshot}) {
    final endedAt = DateTime.now();
    final routeSnapshot = pathPoints.toList(growable: true);
    final start =
        startPoint.value ??
        (routeSnapshot.isEmpty ? null : routeSnapshot.first);
    final end =
        endPoint.value ??
        currentPosition.value ??
        (routeSnapshot.isEmpty ? null : routeSnapshot.last);

    if (start != null && routeSnapshot.isEmpty) {
      routeSnapshot.add(start);
    }
    if (end != null && (routeSnapshot.isEmpty || routeSnapshot.last != end)) {
      routeSnapshot.add(end);
    }

    final record = WorkoutRouteHistoryRecord(
      id: endedAt.microsecondsSinceEpoch.toString(),
      sportType: workoutTitle.value,
      endedAt: endedAt,
      distanceKm: distanceKmText,
      duration: durationText,
      averagePace: averagePaceText,
      startPoint: start,
      endPoint: end,
      routePoints: List<LatLng>.unmodifiable(routeSnapshot),
      mapSnapshot: mapSnapshot,
    );
    if (!_routeHistorySaved) {
      WorkoutRouteHistoryStore.add(record);
      // 累积成就统计：距离 / 时长 / 运动天数 / 单月距离 / 连续周。
      unawaited(
        AchievementStatsStore.recordWorkout(
          distanceKm: distanceMeters.value / 1000,
          durationMinutes: elapsed.value.inMinutes,
          endedAt: endedAt,
        ),
      );
      _routeHistorySaved = true;
    }
    return record;
  }

  /// 当前运动类型（按标题匹配运动栏的户外 / 室内 / 健走 / 徒步），
  /// 匹配不到时回退到第一项。用于返回确认弹窗展示对应图标。
  WorkoutType get currentWorkoutType =>
      WorkoutPageData.localized().workoutTypes.firstWhere(
        (t) => t.title == workoutTitle.value,
        orElse: () => WorkoutPageData.mock.workoutTypes.firstWhere(
          (t) => t.title == workoutTitle.value,
          orElse: () => WorkoutPageData.localized().workoutTypes.first,
        ),
      );

  /// 是否已开始且未结束（运动中或暂停中）——用于返回拦截提示。
  bool get hasActiveSession =>
      status.value == WorkoutStatus.running ||
      status.value == WorkoutStatus.paused;

  /// 主按钮点击：依据当前状态切换。
  void togglePrimary() {
    switch (status.value) {
      case WorkoutStatus.ready:
        start();
        break;
      case WorkoutStatus.running:
        pause();
        break;
      case WorkoutStatus.paused:
        resume();
        break;
      case WorkoutStatus.ended:
        break;
    }
  }

  // ---- 运动音乐 ----

  Future<WorkoutMusicImportResult> importMusic() async {
    final auth =
        await PhotoLibraryPermissionService.ensureAuthorizedForImport();
    switch (auth) {
      case PhotoLibraryImportAuth.authorized:
        break;
      case PhotoLibraryImportAuth.denied:
        return WorkoutMusicImportResult.permissionDenied;
      case PhotoLibraryImportAuth.deniedForever:
        return WorkoutMusicImportResult.permissionDeniedForever;
    }

    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: _musicExtensions,
      withData: false,
    );
    if (result == null) return WorkoutMusicImportResult.completed;

    final pickedTracks = result.files
        .map(_trackFromPickedFile)
        .whereType<_WorkoutMusicTrack>()
        .toList(growable: false);
    final existingPaths = _musicTracks.map((track) => track.path).toSet();
    final selectedPaths = <String>{};
    final newTracks = [
      for (final track in pickedTracks)
        if (!existingPaths.contains(track.path) &&
            selectedPaths.add(track.path))
          track,
    ];
    if (newTracks.isEmpty) return WorkoutMusicImportResult.completed;

    final previousTracks = _musicTracks;
    final player = _ensureMusicPlayer();
    try {
      final tracks = [...previousTracks, ...newTracks];
      final firstNewIndex = previousTracks.length;
      await player.stop();
      await player.setAudioSources(
        [
          for (final track in tracks)
            AudioSource.uri(Uri.file(track.path), tag: track.name),
        ],
        initialIndex: firstNewIndex,
        initialPosition: Duration.zero,
      );
      await player.setLoopMode(LoopMode.all);
      _musicTracks = tracks;
      musicTrackNames.assignAll([for (final track in tracks) track.name]);
      currentMusicIndex.value = firstNewIndex;
      hasMusic.value = true;
      musicTitle.value = tracks[firstNewIndex].name;
      musicStatus.value = WorkoutResource.trackingMusicStatus;
      await player.play();
    } catch (_) {
      _musicTracks = previousTracks;
      musicTrackNames.assignAll([
        for (final track in previousTracks) track.name,
      ]);
      hasMusic.value = previousTracks.isNotEmpty;
      if (previousTracks.isEmpty) {
        currentMusicIndex.value = -1;
        musicPlaying.value = false;
        musicTitle.value = WorkoutResource.trackingMusicTitle;
        musicStatus.value = WorkoutResource.trackingMusicIdle;
      }
    }
    return WorkoutMusicImportResult.completed;
  }

  Future<WorkoutMusicImportResult> toggleMusic() async {
    if (!hasMusic.value) {
      return importMusic();
    }
    final player = _ensureMusicPlayer();
    if (player.playing) {
      await player.pause();
    } else {
      await player.play();
    }
    return WorkoutMusicImportResult.completed;
  }

  Future<void> nextMusic() async {
    if (!hasMusic.value || _musicTracks.isEmpty) return;
    final player = _ensureMusicPlayer();
    if (_musicTracks.length == 1) {
      await player.seek(Duration.zero);
      if (!player.playing) await player.play();
      return;
    }
    await player.seekToNext();
    if (!player.playing) await player.play();
  }

  Future<void> playMusicAt(int index) async {
    if (!hasMusic.value || index < 0 || index >= _musicTracks.length) return;
    final player = _ensureMusicPlayer();
    await player.seek(Duration.zero, index: index);
    await player.play();
  }

  Future<void> toggleMusicMute() async {
    musicMuted.value = !musicMuted.value;
    final player = _musicPlayer;
    if (player != null) {
      await player.setVolume(musicMuted.value ? 0 : 1);
    }
  }

  Future<void> deleteMusicAt(int index) async {
    if (index < 0 || index >= _musicTracks.length) return;

    final wasCurrent = index == currentMusicIndex.value;
    final player = _musicPlayer;
    if (player != null) {
      await player.removeAudioSourceAt(index);
    }

    _musicTracks = [
      for (var i = 0; i < _musicTracks.length; i++)
        if (i != index) _musicTracks[i],
    ];
    musicTrackNames.assignAll([for (final track in _musicTracks) track.name]);

    if (_musicTracks.isEmpty) {
      await player?.stop();
      hasMusic.value = false;
      musicPlaying.value = false;
      currentMusicIndex.value = -1;
      musicTitle.value = WorkoutResource.trackingMusicTitle;
      musicStatus.value = WorkoutResource.trackingMusicIdle;
      return;
    }

    final current = player?.currentIndex;
    currentMusicIndex.value = (current ?? currentMusicIndex.value).clamp(
      0,
      _musicTracks.length - 1,
    );
    musicTitle.value = _musicTracks[currentMusicIndex.value].name;
    if (wasCurrent && player != null && !player.playing) {
      musicStatus.value = WorkoutResource.trackingMusicPaused;
    }
  }

  List<WorkoutMusicTrackData> get musicTracks {
    final current = currentMusicIndex.value;
    return [
      for (var i = 0; i < musicTrackNames.length; i++)
        WorkoutMusicTrackData(name: musicTrackNames[i], current: i == current),
    ];
  }

  _WorkoutMusicTrack? _trackFromPickedFile(PlatformFile file) {
    final path = file.path;
    if (path == null || path.trim().isEmpty) return null;

    final extension = _fileExtension(file.name).toLowerCase();
    if (!_musicExtensions.contains(extension)) return null;

    return _WorkoutMusicTrack(path: path, name: _displayMusicName(file.name));
  }

  String _fileExtension(String fileName) {
    final index = fileName.lastIndexOf('.');
    if (index < 0 || index == fileName.length - 1) return '';
    return fileName.substring(index + 1);
  }

  String _displayMusicName(String fileName) {
    final index = fileName.lastIndexOf('.');
    if (index <= 0) return fileName;
    return fileName.substring(0, index);
  }

  AudioPlayer _ensureMusicPlayer() {
    final existing = _musicPlayer;
    if (existing != null) return existing;

    final player = AudioPlayer();
    _musicPlayer = player;
    unawaited(player.setVolume(musicMuted.value ? 0 : 1));
    _bindMusicPlayer(player);
    return player;
  }

  void _bindMusicPlayer(AudioPlayer player) {
    _musicPlayingSubscription = player.playingStream.listen((playing) {
      musicPlaying.value = playing;
      if (!hasMusic.value) {
        musicStatus.value = WorkoutResource.trackingMusicIdle;
      } else {
        musicStatus.value = playing
            ? WorkoutResource.trackingMusicStatus
            : WorkoutResource.trackingMusicPaused;
      }
    });
    _musicIndexSubscription = player.currentIndexStream.listen((index) {
      if (index == null || index < 0 || index >= _musicTracks.length) return;
      currentMusicIndex.value = index;
      musicTitle.value = _musicTracks[index].name;
    });
  }

  // ---- 定位输入 ----

  /// 每个被地图接受的定位点回调一次。
  /// [raw] 原始 WGS84（算距离 / 方位），[display] 纠偏后的显示坐标（画轨迹 / marker）。
  void onFix(Position raw, LatLng display) {
    _currentRaw = raw;
    currentPosition.value = display;

    if (!_isMetricFixUsable(raw)) {
      return;
    }

    final last = _lastRaw;
    if (last == null) {
      _lastRaw = raw;
      if (status.value == WorkoutStatus.running &&
          pathPoints.isEmpty &&
          _isRouteFixUsable(raw)) {
        startPoint.value ??= display;
        pathPoints.add(display);
        _lastRouteRaw = raw;
      }
      return;
    }

    final delta = Geolocator.distanceBetween(
      last.latitude,
      last.longitude,
      raw.latitude,
      raw.longitude,
    );
    final segmentSpeedKmh = _speedFromDelta(
      delta,
      last.timestamp,
      raw.timestamp,
    );
    if (segmentSpeedKmh <= 0 || segmentSpeedKmh > maxMetricSpeedKmh) {
      return;
    }

    if (delta < minMoveMeters) {
      _appendVisibleRoutePointIfNeeded(raw, display);
      return; // 抖动，保持上次 bearing / 距离
    }

    bearing.value = Geolocator.bearingBetween(
      last.latitude,
      last.longitude,
      raw.latitude,
      raw.longitude,
    );

    if (status.value == WorkoutStatus.running) {
      distanceMeters.value += delta;
      _appendRoutePoint(raw, display);
      _pacePolicy.addSample(
        cumulativeMeters: distanceMeters.value,
        at: DateTime.now(),
      );
      final gpsPace = _pacePolicy.pacePerKm;
      if (!_hasRecentMotionPace) pace.value = gpsPace;
      _lastSpeedKmh = _usablePositionSpeedKmh(raw) ?? segmentSpeedKmh;
      _lastSpeedUpdatedAt = DateTime.now();
    }

    _lastRaw = raw;
  }

  void _appendVisibleRoutePointIfNeeded(Position raw, LatLng display) {
    if (status.value != WorkoutStatus.running) return;
    if (!_isRouteFixUsable(raw)) return;

    final lastRoute = _lastRouteRaw;
    if (lastRoute == null) {
      _appendRoutePoint(raw, display);
      return;
    }

    final delta = Geolocator.distanceBetween(
      lastRoute.latitude,
      lastRoute.longitude,
      raw.latitude,
      raw.longitude,
    );
    if (delta < minRoutePointMeters) return;
    _appendRoutePoint(raw, display);
  }

  void _appendRoutePoint(Position raw, LatLng display) {
    if (!_isRouteFixUsable(raw)) return;
    if (pathPoints.isEmpty) {
      startPoint.value ??= display;
    }
    if (pathPoints.isEmpty || pathPoints.last != display) {
      pathPoints.add(display);
    }
    _lastRouteRaw = raw;
  }

  double _speedFromDelta(double meters, DateTime from, DateTime to) {
    final secs = to.difference(from).inMilliseconds / 1000;
    if (secs <= 0) return 0;
    return (meters / secs) * 3.6;
  }

  bool _isMetricFixUsable(Position raw) {
    final accuracy = raw.accuracy;
    return accuracy.isFinite &&
        accuracy > 0 &&
        accuracy <= maxMetricAccuracyMeters;
  }

  bool _isRouteFixUsable(Position raw) {
    final accuracy = raw.accuracy;
    return accuracy.isFinite &&
        accuracy > 0 &&
        accuracy <= maxRouteAccuracyMeters;
  }

  Position? _usableMetricRawOrNull(Position? raw) {
    if (raw == null || !_isMetricFixUsable(raw)) return null;
    return raw;
  }

  Position? _usableRouteRawOrNull(Position? raw) {
    if (raw == null || !_isRouteFixUsable(raw)) return null;
    return raw;
  }

  double? _usablePositionSpeedKmh(Position raw) {
    final speedKmh = raw.speed * 3.6;
    if (!speedKmh.isFinite || speedKmh <= 0 || speedKmh > maxMetricSpeedKmh) {
      return null;
    }
    return speedKmh;
  }

  bool get _hasRecentMotionPace {
    final at = _lastMotionPaceAt;
    return at != null && DateTime.now().difference(at) < _motionPaceFreshness;
  }

  void _startMotionPaceIfNeeded() {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    _motionPaceSubscription ??=
        MotionFitnessPermissionService.currentPaceStream().listen(
          _onMotionPace,
          onError: (_) {},
        );
  }

  /// 室内运动无 GPS，距离 / 步数改用计步器（CMPedometer）按会话基线增量累积。
  void _startMotionStepIfNeeded() {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    _motionStepSubscription ??= MotionFitnessPermissionService.todayStepStream()
        .listen(_onMotionStep, onError: (_) {});
  }

  void _onMotionStep(MotionFitnessSample sample) {
    if (!isIndoor.value) return; // 户外用 GPS 累积，室内才用计步器。

    final currentDistance = sample.distanceMeters;
    final currentSteps = sample.steps;

    // 非运行态（未开始 / 暂停）：只滚动基线，不累积，从而跳过暂停期间的步数。
    if (status.value != WorkoutStatus.running) {
      _lastIndoorDistanceMeters = currentDistance;
      _lastIndoorSteps = currentSteps;
      return;
    }

    final lastDistance = _lastIndoorDistanceMeters;
    final lastSteps = _lastIndoorSteps;
    // 首个运行态样本：仅建立基线（含跨午夜计步器清零后的重新基线）。
    if (lastDistance == null || lastSteps == null) {
      _lastIndoorDistanceMeters = currentDistance;
      _lastIndoorSteps = currentSteps;
      return;
    }

    final deltaDistance = currentDistance - lastDistance;
    final deltaSteps = currentSteps - lastSteps;
    if (deltaDistance > 0) distanceMeters.value += deltaDistance;
    if (deltaSteps > 0) steps.value += deltaSteps;
    _lastIndoorDistanceMeters = currentDistance;
    _lastIndoorSteps = currentSteps;
  }

  void _onMotionPace(Duration pacePerKm) {
    if (status.value != WorkoutStatus.running) return;
    final millisPerKm = pacePerKm.inMilliseconds;
    if (millisPerKm <= 0) return;

    final speedKmh = 3600000 / millisPerKm;
    if (!speedKmh.isFinite || speedKmh <= 0 || speedKmh > maxMetricSpeedKmh) {
      return;
    }

    _lastMotionPaceAt = DateTime.now();
    pace.value = pacePerKm;
    _lastSpeedKmh = speedKmh;
    _lastSpeedUpdatedAt = _lastMotionPaceAt;
  }

  // ---- 计时器 ----

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsed.value += const Duration(seconds: 1);
      calories.value += _caloriePolicy.kcalForTick(
        speedKmh: _freshCalorieSpeedKmh,
        seconds: 1,
      );
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void onInit() {
    super.onInit();
    init();
  }

  @override
  void init() {
    musicTitle.value = WorkoutResource.trackingMusicTitle;
    musicStatus.value = WorkoutResource.trackingMusicIdle;
    _startMotionPaceIfNeeded();
    _startMotionStepIfNeeded();
    final args = Get.arguments;
    if (args is WorkoutType) {
      workoutTitle.value = args.title;
      isIndoor.value = _isIndoorTitle(args.title);
    } else if (args is String && args.trim().isNotEmpty) {
      workoutTitle.value = args;
      isIndoor.value = _isIndoorTitle(args);
    }
    _syncGoalFromWorkout();
  }

  /// 同步运动栏「目标与成就」中的目标里程，使地图上的「目标 X 公里」与之一致。
  void _syncGoalFromWorkout() {
    if (!Get.isRegistered<WorkoutViewModel>()) return;
    final workout = Get.find<WorkoutViewModel>();
    template = template.copyWith(
      targetKm: workout.goalDistance.toStringAsFixed(2),
    );
  }

  @override
  void unInit() {
    _stopTicker();
    _motionPaceSubscription?.cancel();
    _motionPaceSubscription = null;
    _motionStepSubscription?.cancel();
    _motionStepSubscription = null;
    _musicPlayingSubscription?.cancel();
    _musicPlayingSubscription = null;
    _musicIndexSubscription?.cancel();
    _musicIndexSubscription = null;
    final player = _musicPlayer;
    _musicPlayer = null;
    if (player != null) unawaited(player.dispose());
  }

  @override
  void onClose() {
    unInit();
    super.onClose();
  }

  // ---- 格式化展示 ----

  String get distanceKmText => (distanceMeters.value / 1000).toStringAsFixed(2);

  String get stepsText => steps.value.toString();

  String get durationText {
    final d = elapsed.value;
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get caloriesText => calories.value.round().toString();

  double get _freshCalorieSpeedKmh {
    final at = _lastSpeedUpdatedAt;
    if (at == null || DateTime.now().difference(at) > _calorieSpeedFreshness) {
      return 0;
    }
    return _lastSpeedKmh;
  }

  /// 模板叠加实时值后的展示数据。
  WorkoutTrackingData get liveData => template.copyWith(
    workoutTitle: workoutTitle.value,
    status: status.value,
    distanceKm: distanceKmText,
    duration: durationText,
    calories: caloriesText,
    pace: paceText,
    musicTitle: musicTitle.value,
    musicStatus: musicStatus.value,
    hasMusic: hasMusic.value,
    musicPlaying: musicPlaying.value,
  );

  String get paceText {
    return _formatPace(pace.value);
  }

  Duration? get averagePace {
    final meters = distanceMeters.value;
    final millis = elapsed.value.inMilliseconds;
    if (meters <= 0 || millis <= 0) return null;
    final millisPerKm = millis / (meters / 1000);
    return Duration(milliseconds: millisPerKm.round());
  }

  String get averagePaceText => _formatPace(averagePace);

  String _formatPace(Duration? value) {
    if (value == null) return "--'--''";
    final total = value.inSeconds;
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return "$m'$s''";
  }

  /// 结束后用于结果页的聚合数据。
  ExerciseResultData toResultData() {
    return ExerciseResultData(
      sportType: workoutTitle.value,
      dateText: _formatResultDate(DateTime.now()),
      distance: distanceKmText,
      distanceUnit: WorkoutResource.distanceUnit,
      metrics: [
        ExerciseResultMetric(
          icon: Icons.schedule_rounded,
          color: AppColors.brandGreen,
          label: WorkoutResource.metricDuration,
          value: durationText,
        ),
        ExerciseResultMetric(
          icon: Icons.local_fire_department_rounded,
          color: AppColors.accentOrange,
          label: WorkoutResource.metricCalorieKcal,
          value: caloriesText,
        ),
        ExerciseResultMetric(
          icon: Icons.speed_rounded,
          color: AppColors.accentCyan,
          label: WorkoutResource.metricPaceMinKm,
          value: averagePaceText,
        ),
      ],
    );
  }

  String _formatResultDate(DateTime value) {
    return localizedDateTime(value);
  }

  bool _isIndoorTitle(String title) {
    return title == WorkoutResource.indoorRun ||
        title == WorkoutText.indoorRun ||
        title == '室内' ||
        title == '室内';
  }
}

enum WorkoutMusicImportResult {
  completed,
  permissionDenied,
  permissionDeniedForever,
}

class _WorkoutMusicTrack {
  final String path;
  final String name;

  const _WorkoutMusicTrack({required this.path, required this.name});
}
