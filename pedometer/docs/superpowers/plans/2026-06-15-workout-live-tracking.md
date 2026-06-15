# 户外运动实时追踪 实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 让户外运动页点击「开始」后，距离从 0 实时累计，时长、卡路里、配速实时计算，地图实时绘制 GPS 轨迹、钉住起点、当前位置箭头随行进方向旋转。

**架构：** 新建 `WorkoutTrackingController`（GetxController）作为会话唯一数据源；已跑通的 `WorkoutMapView` GPS 管线保留，每个被接受的定位点回调 `controller.onFix(raw, display)`；地图与指标面板通过 `Obx` 观察控制器。卡路里 / 配速抽成纯函数模型便于单测。

**技术栈：** Flutter、GetX（Rx + 路由 binding）、geolocator（`distanceBetween` / `bearingBetween` 纯 Dart）、google_maps_flutter（Polyline / Marker）、flutter_test + fake_async。

**规格：** `docs/superpowers/specs/2026-06-15-workout-live-tracking-design.md`

---

## 文件结构

新增：

- `lib/feature/workout/model/workout_calorie_policy.dart` — 按速度查 MET 表 + 卡路里 tick 累加（纯函数）。
- `lib/feature/workout/model/workout_pace_policy.dart` — 滚动窗口实时配速（纯函数）。
- `lib/feature/workout/viewmodel/workout_tracking_controller.dart` — GetxController 会话控制器。
- `test/feature/workout/workout_calorie_policy_test.dart`
- `test/feature/workout/workout_pace_policy_test.dart`
- `test/feature/workout/workout_tracking_controller_test.dart`

修改：

- `lib/feature/workout/model/workout_model.dart` — `WorkoutTrackingData.copyWith` 扩展可覆盖实时字段。
- `lib/feature/workout/components/workout_tracking_components.dart` — `WorkoutMapView` 对接控制器：onFix、Polyline、起点 marker、bearing 旋转。
- `lib/feature/workout/views/workout_tracking_page.dart` — 用控制器替换本地 `_status` 与静态数据，Obx 绑定。
- `lib/feature/workout/views/exercise_result_page.dart` — 经 `Get.arguments` 接收真实聚合结果。
- `lib/common/routers/app_pages.dart` — tracking 路由绑定 `WorkoutTrackingController`。

---

## 任务 1：WorkoutCaloriePolicy（卡路里纯函数）

**文件：**
- 创建：`lib/feature/workout/model/workout_calorie_policy.dart`
- 测试：`test/feature/workout/workout_calorie_policy_test.dart`

- [ ] **步骤 1：编写失败的测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer/feature/workout/model/workout_calorie_policy.dart';

void main() {
  test('MET table maps speed bands to expected values', () {
    expect(WorkoutCaloriePolicy.metForSpeedKmh(0), 2.5);
    expect(WorkoutCaloriePolicy.metForSpeedKmh(3.9), 2.5);
    expect(WorkoutCaloriePolicy.metForSpeedKmh(4), 3.5);
    expect(WorkoutCaloriePolicy.metForSpeedKmh(7), 6.0);
    expect(WorkoutCaloriePolicy.metForSpeedKmh(9), 8.3);
    expect(WorkoutCaloriePolicy.metForSpeedKmh(11), 9.8);
    expect(WorkoutCaloriePolicy.metForSpeedKmh(15), 11.0);
  });

  test('kcalForTick = MET * weight * hours', () {
    const policy = WorkoutCaloriePolicy(weightKg: 60);
    // 速度 9km/h → MET 8.3；1 秒 = 1/3600 小时。
    final kcal = policy.kcalForTick(speedKmh: 9, seconds: 1);
    expect(kcal, closeTo(8.3 * 60 * (1 / 3600), 1e-9));
  });

  test('default weight is 60kg', () {
    const policy = WorkoutCaloriePolicy();
    expect(policy.weightKg, 60);
  });
}
```

- [ ] **步骤 2：运行测试验证失败**

运行：`flutter test test/feature/workout/workout_calorie_policy_test.dart`
预期：FAIL，报 `Target of URI doesn't exist` / `WorkoutCaloriePolicy` 未定义。

- [ ] **步骤 3：编写最少实现代码**

创建 `lib/feature/workout/model/workout_calorie_policy.dart`：

```dart
/// 卡路里估算：固定默认体重 + 按速度查 MET 表。
/// MET（代谢当量）数值取自常见运动能耗表，按速度分档近似。
class WorkoutCaloriePolicy {
  const WorkoutCaloriePolicy({this.weightKg = 60});

  /// 估算用体重（千克）。项目暂无用户体重，使用固定默认值。
  final double weightKg;

  /// 按速度（km/h）返回 MET 值。
  static double metForSpeedKmh(double speedKmh) {
    if (speedKmh < 4) return 2.5;
    if (speedKmh < 6) return 3.5;
    if (speedKmh < 8) return 6.0;
    if (speedKmh < 10) return 8.3;
    if (speedKmh < 12) return 9.8;
    return 11.0;
  }

  /// 本次 tick 消耗的卡路里增量。
  /// [speedKmh] 当前速度，[seconds] tick 时长（秒）。
  double kcalForTick({required double speedKmh, required double seconds}) {
    final met = metForSpeedKmh(speedKmh);
    return met * weightKg * (seconds / 3600);
  }
}
```

- [ ] **步骤 4：运行测试验证通过**

运行：`flutter test test/feature/workout/workout_calorie_policy_test.dart`
预期：PASS（3 个 test 全绿）。

- [ ] **步骤 5：Commit**

```bash
git add lib/feature/workout/model/workout_calorie_policy.dart test/feature/workout/workout_calorie_policy_test.dart
git commit -m "feat(workout): add WorkoutCaloriePolicy MET-based calorie model"
```

---

## 任务 2：WorkoutPacePolicy（滚动窗口实时配速纯函数）

**文件：**
- 创建：`lib/feature/workout/model/workout_pace_policy.dart`
- 测试：`test/feature/workout/workout_pace_policy_test.dart`

- [ ] **步骤 1：编写失败的测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer/feature/workout/model/workout_pace_policy.dart';

void main() {
  final t0 = DateTime(2026, 6, 15, 8);

  test('returns null with fewer than two samples', () {
    final policy = WorkoutPacePolicy();
    expect(policy.pacePerKm, isNull);
    policy.addSample(cumulativeMeters: 0, at: t0);
    expect(policy.pacePerKm, isNull);
  });

  test('returns null until window distance reaches the minimum gate', () {
    final policy = WorkoutPacePolicy(minWindowMeters: 30);
    policy.addSample(cumulativeMeters: 0, at: t0);
    policy.addSample(cumulativeMeters: 10, at: t0.add(const Duration(seconds: 5)));
    // 仅 10m < 30m 门槛。
    expect(policy.pacePerKm, isNull);
  });

  test('computes pace from window distance and time', () {
    final policy = WorkoutPacePolicy(minWindowMeters: 30);
    policy.addSample(cumulativeMeters: 0, at: t0);
    // 100m 用 20s（落在默认 20s 窗口内）→ 配速 = 20s / 0.1km = 200 s/km。
    policy.addSample(cumulativeMeters: 100, at: t0.add(const Duration(seconds: 20)));
    expect(policy.pacePerKm, const Duration(seconds: 200));
  });

  test('slides out samples older than the window', () {
    final policy = WorkoutPacePolicy(
      windowDuration: const Duration(seconds: 20),
      minWindowMeters: 30,
    );
    policy.addSample(cumulativeMeters: 0, at: t0);
    policy.addSample(cumulativeMeters: 100, at: t0.add(const Duration(seconds: 30)));
    // 第二个样本距首样本 30s > 20s 窗口 → 旧样本被滑出，只剩 1 个 → null。
    expect(policy.pacePerKm, isNull);
    // 再加一个落在窗口内的样本形成有效区间。
    policy.addSample(cumulativeMeters: 200, at: t0.add(const Duration(seconds: 40)));
    // 窗口内：100m(@30s) → 200m(@40s) = 100m / 10s = 100 s/km。
    expect(policy.pacePerKm, const Duration(seconds: 100));
  });

  test('reset clears samples', () {
    final policy = WorkoutPacePolicy(minWindowMeters: 30);
    policy.addSample(cumulativeMeters: 0, at: t0);
    policy.addSample(cumulativeMeters: 200, at: t0.add(const Duration(seconds: 60)));
    policy.reset();
    expect(policy.pacePerKm, isNull);
  });
}
```

- [ ] **步骤 2：运行测试验证失败**

运行：`flutter test test/feature/workout/workout_pace_policy_test.dart`
预期：FAIL，`WorkoutPacePolicy` 未定义。

- [ ] **步骤 3：编写最少实现代码**

创建 `lib/feature/workout/model/workout_pace_policy.dart`：

```dart
import 'dart:collection';

/// 滚动窗口实时配速。样本为 (累计距离米, 时间戳)。
/// 取最近 [windowDuration] 内的样本，要求窗口距离 ≥ [minWindowMeters] 才出值，
/// 避免起步 / 站立时配速剧烈抖动。
class WorkoutPacePolicy {
  WorkoutPacePolicy({
    this.windowDuration = const Duration(seconds: 20),
    this.minWindowMeters = 30,
  });

  final Duration windowDuration;
  final double minWindowMeters;

  final Queue<_PaceSample> _samples = Queue<_PaceSample>();

  void addSample({required double cumulativeMeters, required DateTime at}) {
    _samples.addLast(_PaceSample(cumulativeMeters, at));
    // 移除窗口外旧样本，但至少保留一个用于差分。
    while (_samples.length > 1 &&
        at.difference(_samples.first.at) > windowDuration) {
      _samples.removeFirst();
    }
  }

  void reset() => _samples.clear();

  /// 每公里配速；数据不足返回 null。
  Duration? get pacePerKm {
    if (_samples.length < 2) return null;
    final first = _samples.first;
    final last = _samples.last;
    final meters = last.cumulativeMeters - first.cumulativeMeters;
    if (meters < minWindowMeters) return null;
    final secs = last.at.difference(first.at).inMilliseconds / 1000;
    if (secs <= 0) return null;
    final secsPerKm = secs / (meters / 1000);
    return Duration(milliseconds: (secsPerKm * 1000).round());
  }
}

class _PaceSample {
  const _PaceSample(this.cumulativeMeters, this.at);
  final double cumulativeMeters;
  final DateTime at;
}
```

- [ ] **步骤 4：运行测试验证通过**

运行：`flutter test test/feature/workout/workout_pace_policy_test.dart`
预期：PASS（5 个 test 全绿）。

- [ ] **步骤 5：Commit**

```bash
git add lib/feature/workout/model/workout_pace_policy.dart test/feature/workout/workout_pace_policy_test.dart
git commit -m "feat(workout): add WorkoutPacePolicy rolling-window pace model"
```

---

## 任务 3：WorkoutTrackingController（会话控制器）

**文件：**
- 创建：`lib/feature/workout/viewmodel/workout_tracking_controller.dart`
- 测试：`test/feature/workout/workout_tracking_controller_test.dart`

依赖说明：`Geolocator.distanceBetween` / `bearingBetween` 是 geolocator 内的纯 Dart Haversine 工具方法，不触发平台通道，可在单测中直接调用。`Timer.periodic` 用 `package:fake_async` 推进。

- [ ] **步骤 1：编写失败的测试**

```dart
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';
import 'package:pedometer/feature/workout/viewmodel/workout_tracking_controller.dart';

Position _pos(double lat, double lng, {double speed = 0, DateTime? at}) {
  return Position(
    latitude: lat,
    longitude: lng,
    timestamp: at ?? DateTime(2026, 6, 15, 8),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: speed,
    speedAccuracy: 0,
  );
}

void main() {
  test('start resets metrics and pins the start point', () {
    final c = WorkoutTrackingController();
    c.onFix(_pos(31.0, 121.0), const LatLng(31.0, 121.0));
    c.start();

    expect(c.status.value, WorkoutStatus.running);
    expect(c.distanceMeters.value, 0);
    expect(c.elapsed.value, Duration.zero);
    expect(c.calories.value, 0);
    expect(c.startPoint.value, const LatLng(31.0, 121.0));
    expect(c.pathPoints, [const LatLng(31.0, 121.0)]);
  });

  test('distance accumulates only while running and ignores sub-threshold jitter', () {
    final c = WorkoutTrackingController(minMoveMeters: 2.5);
    c.onFix(_pos(31.20000, 121.40000), const LatLng(31.20000, 121.40000));
    c.start();
    // ~111km/deg 纬度 → 0.00001 deg ≈ 1.1m（< 2.5m 抖动门限，应被丢弃）。
    c.onFix(_pos(31.200010, 121.40000), const LatLng(31.200010, 121.40000));
    expect(c.distanceMeters.value, 0);

    // 0.0005 deg ≈ 55m（> 门限，应累计）。
    c.onFix(_pos(31.200510, 121.40000), const LatLng(31.200510, 121.40000));
    expect(c.distanceMeters.value, greaterThan(50));
    expect(c.pathPoints.length, 2); // 起点 + 1 个有效移动点
  });

  test('paused freezes the timer; running accumulates duration and calories', () {
    fakeAsync((async) {
      final c = WorkoutTrackingController();
      c.onFix(_pos(31.0, 121.0, speed: 2.5), const LatLng(31.0, 121.0)); // 9km/h
      c.start();
      async.elapse(const Duration(seconds: 3));
      expect(c.elapsed.value, const Duration(seconds: 3));
      expect(c.calories.value, greaterThan(0));

      final frozen = c.calories.value;
      c.pause();
      async.elapse(const Duration(seconds: 5));
      expect(c.elapsed.value, const Duration(seconds: 3)); // 暂停期间不走动
      expect(c.calories.value, frozen);

      c.resume();
      async.elapse(const Duration(seconds: 2));
      expect(c.elapsed.value, const Duration(seconds: 5));
      c.end();
    });
  });

  test('togglePrimary follows the state machine', () {
    final c = WorkoutTrackingController();
    c.onFix(_pos(31.0, 121.0), const LatLng(31.0, 121.0));
    expect(c.status.value, WorkoutStatus.ready);
    c.togglePrimary();
    expect(c.status.value, WorkoutStatus.running);
    c.togglePrimary();
    expect(c.status.value, WorkoutStatus.paused);
    c.togglePrimary();
    expect(c.status.value, WorkoutStatus.running);
    c.end();
    expect(c.status.value, WorkoutStatus.ended);
  });

  test('durationText / distanceKmText / paceText format correctly', () {
    final c = WorkoutTrackingController();
    expect(c.durationText, '00:00:00');
    expect(c.distanceKmText, '0.00');
    expect(c.paceText, "--'--''"); // 无配速数据
  });
}
```

- [ ] **步骤 2：运行测试验证失败**

运行：`flutter test test/feature/workout/workout_tracking_controller_test.dart`
预期：FAIL，`WorkoutTrackingController` 未定义。

- [ ] **步骤 3：编写最少实现代码**

创建 `lib/feature/workout/viewmodel/workout_tracking_controller.dart`：

```dart
import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pedometer/feature/workout/model/workout_calorie_policy.dart';
import 'package:pedometer/feature/workout/model/workout_pace_policy.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';

/// 户外运动会话控制器：持有实时距离 / 时长 / 卡路里 / 配速 / 轨迹 / 方位，
/// 作为运动追踪页与地图的唯一数据源。
class WorkoutTrackingController extends GetxController {
  WorkoutTrackingController({
    WorkoutCaloriePolicy? caloriePolicy,
    WorkoutPacePolicy? pacePolicy,
    this.minMoveMeters = 2.5,
  })  : _caloriePolicy = caloriePolicy ?? const WorkoutCaloriePolicy(),
        _pacePolicy = pacePolicy ?? WorkoutPacePolicy();

  final WorkoutCaloriePolicy _caloriePolicy;
  final WorkoutPacePolicy _pacePolicy;

  /// 小于该距离（米）的相邻定位视为 GPS 抖动，不累计、不画点。
  final double minMoveMeters;

  final status = WorkoutStatus.ready.obs;
  final startPoint = Rxn<LatLng>();
  final currentPosition = Rxn<LatLng>();
  final pathPoints = <LatLng>[].obs;
  final distanceMeters = 0.0.obs;
  final elapsed = Duration.zero.obs;
  final calories = 0.0.obs;
  final bearing = 0.0.obs;
  final pace = Rxn<Duration>();

  Timer? _ticker;
  Position? _lastRaw; // 上一个被接受的原始定位（算距离 / 方位）
  double _lastSpeedKmh = 0; // 当前 tick 卡路里用的速度

  // ---- 状态机 ----

  void start() {
    distanceMeters.value = 0;
    elapsed.value = Duration.zero;
    calories.value = 0;
    pace.value = null;
    pathPoints.clear();
    _pacePolicy.reset();
    _lastRaw = null;
    _lastSpeedKmh = 0;

    final pos = currentPosition.value;
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
    status.value = WorkoutStatus.ended;
    _stopTicker();
  }

  /// 主按钮点击：依据当前状态切换。
  void togglePrimary() {
    switch (status.value) {
      case WorkoutStatus.ready:
        start();
      case WorkoutStatus.running:
        pause();
      case WorkoutStatus.paused:
        resume();
      case WorkoutStatus.ended:
        break;
    }
  }

  // ---- 定位输入 ----

  /// 每个被地图接受的定位点回调一次。
  /// [raw] 原始 WGS84（算距离 / 方位），[display] 纠偏后的显示坐标（画轨迹 / marker）。
  void onFix(Position raw, LatLng display) {
    currentPosition.value = display;

    final last = _lastRaw;
    if (last == null) {
      _lastRaw = raw;
      return;
    }

    final delta = Geolocator.distanceBetween(
      last.latitude,
      last.longitude,
      raw.latitude,
      raw.longitude,
    );
    if (delta < minMoveMeters) return; // 抖动，保持上次 bearing / 距离

    bearing.value = Geolocator.bearingBetween(
      last.latitude,
      last.longitude,
      raw.latitude,
      raw.longitude,
    );

    if (status.value == WorkoutStatus.running) {
      distanceMeters.value += delta;
      pathPoints.add(display);
      _pacePolicy.addSample(
        cumulativeMeters: distanceMeters.value,
        at: DateTime.now(),
      );
      pace.value = _pacePolicy.pacePerKm;
      _lastSpeedKmh = (raw.speed.isFinite && raw.speed > 0)
          ? raw.speed * 3.6
          : _speedFromDelta(delta, last.timestamp, raw.timestamp);
    }

    _lastRaw = raw;
  }

  double _speedFromDelta(double meters, DateTime from, DateTime to) {
    final secs = to.difference(from).inMilliseconds / 1000;
    if (secs <= 0) return 0;
    return (meters / secs) * 3.6;
  }

  // ---- 计时器 ----

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsed.value += const Duration(seconds: 1);
      calories.value += _caloriePolicy.kcalForTick(
        speedKmh: _lastSpeedKmh,
        seconds: 1,
      );
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void onClose() {
    _stopTicker();
    super.onClose();
  }

  // ---- 格式化展示 ----

  String get distanceKmText => (distanceMeters.value / 1000).toStringAsFixed(2);

  String get durationText {
    final d = elapsed.value;
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get caloriesText => calories.value.round().toString();

  String get paceText {
    final p = pace.value;
    if (p == null) return "--'--''";
    final total = p.inSeconds;
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return "$m'$s''";
  }

  /// 结束后用于结果页的聚合数据。
  ExerciseResultData toResultData() {
    return ExerciseResultData(
      sportType: WorkoutText.outdoorRun,
      dateText: ExerciseResultData.mock.dateText,
      distance: distanceKmText,
      distanceUnit: WorkoutText.distanceUnit,
      metrics: [
        ExerciseResultMetric(
          icon: Icons.schedule_rounded,
          color: const Color(0xFF24F04E),
          label: WorkoutText.metricDuration,
          value: durationText,
        ),
        ExerciseResultMetric(
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFFF9F12),
          label: WorkoutText.metricCalorieKcal,
          value: caloriesText,
        ),
        ExerciseResultMetric(
          icon: Icons.speed_rounded,
          color: const Color(0xFF0CD9FF),
          label: WorkoutText.metricPaceMinKm,
          value: paceText,
        ),
      ],
    );
  }
}
```

注意：`toResultData` 用到 `Icons` / `Color`，需在文件顶部补 `import 'package:flutter/material.dart';`。

- [ ] **步骤 4：运行测试验证通过**

运行：`flutter test test/feature/workout/workout_tracking_controller_test.dart`
预期：PASS（5 个 test 全绿）。

- [ ] **步骤 5：Commit**

```bash
git add lib/feature/workout/viewmodel/workout_tracking_controller.dart test/feature/workout/workout_tracking_controller_test.dart
git commit -m "feat(workout): add WorkoutTrackingController live session state"
```

---

## 任务 4：扩展 WorkoutTrackingData.copyWith

**文件：**
- 修改：`lib/feature/workout/model/workout_model.dart:95-110`

让页面能用控制器派生值覆盖实时字段（其余静态字段保持不变）。

- [ ] **步骤 1：编写失败的测试**

创建 `test/feature/workout/workout_tracking_data_copywith_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';

void main() {
  test('copyWith overrides live fields and keeps the rest', () {
    final updated = WorkoutTrackingData.mock.copyWith(
      status: WorkoutStatus.running,
      distanceKm: '0.42',
      duration: '00:01:05',
      calories: '7',
      pace: "05'00''",
    );

    expect(updated.status, WorkoutStatus.running);
    expect(updated.distanceKm, '0.42');
    expect(updated.duration, '00:01:05');
    expect(updated.calories, '7');
    expect(updated.pace, "05'00''");
    // 未覆盖字段保持 mock 原值。
    expect(updated.workoutTitle, WorkoutTrackingData.mock.workoutTitle);
    expect(updated.targetKm, WorkoutTrackingData.mock.targetKm);
  });
}
```

- [ ] **步骤 2：运行测试验证失败**

运行：`flutter test test/feature/workout/workout_tracking_data_copywith_test.dart`
预期：FAIL，`copyWith` 不接受 `distanceKm` 等命名参数。

- [ ] **步骤 3：编写最少实现代码**

把 `lib/feature/workout/model/workout_model.dart:95-110` 的 `copyWith` 替换为：

```dart
  WorkoutTrackingData copyWith({
    WorkoutStatus? status,
    String? distanceKm,
    String? duration,
    String? calories,
    String? pace,
  }) {
    return WorkoutTrackingData(
      workoutTitle: workoutTitle,
      status: status ?? this.status,
      gpsLabel: gpsLabel,
      gpsStatus: gpsStatus,
      distanceKm: distanceKm ?? this.distanceKm,
      targetKm: targetKm,
      duration: duration ?? this.duration,
      calories: calories ?? this.calories,
      pace: pace ?? this.pace,
      endHint: endHint,
      musicTitle: musicTitle,
      musicStatus: musicStatus,
    );
  }
```

- [ ] **步骤 4：运行测试验证通过**

运行：`flutter test test/feature/workout/workout_tracking_data_copywith_test.dart`
预期：PASS。

- [ ] **步骤 5：Commit**

```bash
git add lib/feature/workout/model/workout_model.dart test/feature/workout/workout_tracking_data_copywith_test.dart
git commit -m "feat(workout): extend WorkoutTrackingData.copyWith with live fields"
```

---

## 任务 5：WorkoutMapView 对接控制器（轨迹 / 起点 / 方向旋转 / onFix）

**文件：**
- 修改：`lib/feature/workout/components/workout_tracking_components.dart`

控制器解析采用「已注册则 find，否则 put」的回退，保证现有 `WorkoutMapView()` 无参构造与测试不破。`_isWidgetTest` 短路仍阻止测试中创建真实地图与定位流，故 onFix 不会在测试里被调用。

- [ ] **步骤 1：补依赖导入**

在文件顶部 import 区（`workout_model.dart` 之后）加：

```dart
import 'package:get/get.dart';
import 'package:pedometer/feature/workout/viewmodel/workout_tracking_controller.dart';
```

- [ ] **步骤 2：在 `_WorkoutMapViewState` 解析控制器**

在 `_WorkoutMapViewState`（约 `workout_tracking_components.dart:85`）字段区加：

```dart
  late final WorkoutTrackingController _controller =
      Get.isRegistered<WorkoutTrackingController>()
          ? Get.find<WorkoutTrackingController>()
          : Get.put(WorkoutTrackingController());
```

- [ ] **步骤 3：把每个被接受的定位点喂给控制器**

在 `_acceptPosition` 末尾（`workout_tracking_components.dart:341-343` 的 `if (isStable || isFirstFix) { _moveCamera(latLng); }` 之后）加：

```dart
    _controller.onFix(position, latLng);
```

- [ ] **步骤 4：地图叠加轨迹层、起点 marker、当前位置 marker 旋转**

把 `build` 中真实地图分支的 `GoogleMap(...)`（`workout_tracking_components.dart:145-173`）用 `Obx` 包裹，并加入 `polylines` 与合并后的 markers。将该 `Positioned.fill(child: GoogleMap(...))` 替换为：

```dart
        Positioned.fill(
          child: Obx(
            () => GoogleMap(
              initialCameraPosition: _currentPosition == null
                  ? _defaultCameraPosition
                  : CameraPosition(
                      target: _currentPosition!, zoom: _currentZoom),
              minMaxZoomPreference: const MinMaxZoomPreference(
                WorkoutMapZoomPolicy.minZoom,
                WorkoutMapZoomPolicy.maxZoom,
              ),
              myLocationEnabled: _useNativeMyLocationLayer,
              myLocationButtonEnabled: false,
              markers: _trackingMarkers,
              polylines: _trackingPolylines,
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
                  _moveCamera(position);
                }
              },
            ),
          ),
        ),
```

- [ ] **步骤 5：新增 markers / polylines getter，并给当前位置 marker 加旋转**

把现有 `_correctedLocationMarkers` getter（`workout_tracking_components.dart:360-376`）替换为下面三个 getter：

```dart
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

    final position = _currentPosition;
    final icon = _currentLocationMarkerIcon;
    if (!_useNativeMyLocationLayer && position != null && icon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('workout-current-location'),
          position: position,
          anchor: WorkoutLocationMarkerStyle.anchor,
          icon: icon,
          rotation: _controller.bearing.value,
          flat: true,
          zIndexInt: 2,
        ),
      );
    }

    return markers;
  }

  Set<Polyline> get _trackingPolylines {
    final points = _controller.pathPoints;
    if (points.length < 2) return const {};
    return {
      Polyline(
        polylineId: const PolylineId('workout-route'),
        points: points.toList(),
        color: const Color(0xFF24F04E),
        width: 6,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }
```

注意：原 `markers: _correctedLocationMarkers`（步骤 4 已替换为 `_trackingMarkers`）。确认文件中不再有对 `_correctedLocationMarkers` 的引用（全局搜索应为 0）。

- [ ] **步骤 6：运行既有地图相关测试确认未破坏**

运行：`flutter test test/feature/workout/workout_page_test.dart test/feature/workout/workout_tracking_end_test.dart`
预期：PASS（`_isWidgetTest` 短路使测试走 fallback 分支，控制器经 `Get.put` 回退可解析）。
若 `workout_tracking_end_test.dart` 因控制器状态残留失败，在其 `setUp`/`tearDown` 加 `Get.reset()`（见任务 6 步骤 4 同款处理）。

- [ ] **步骤 7：静态分析**

运行：`flutter analyze lib/feature/workout/components/workout_tracking_components.dart`
预期：No issues（无未用 import、无未定义引用）。

- [ ] **步骤 8：Commit**

```bash
git add lib/feature/workout/components/workout_tracking_components.dart
git commit -m "feat(workout): draw live route/start marker and rotate location by bearing"
```

---

## 任务 6：WorkoutTrackingPage 绑定控制器

**文件：**
- 修改：`lib/feature/workout/views/workout_tracking_page.dart`
- 修改：`lib/common/routers/app_pages.dart`

- [ ] **步骤 1：tracking 路由注入控制器**

在 `lib/common/routers/app_pages.dart` 顶部加 import：

```dart
import 'package:pedometer/feature/workout/viewmodel/workout_tracking_controller.dart';
```

把 `WorkoutRouteTable.pathTracking` 的 `GetPage`（`app_pages.dart:49-52`）改为带 binding：

```dart
    GetPage(
      name: WorkoutRouteTable.pathTracking,
      page: () => const WorkoutTrackingPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<WorkoutTrackingController>(
          () => WorkoutTrackingController(),
        );
      }),
    ),
```

- [ ] **步骤 2：页面用控制器替换本地状态与静态数据**

把 `lib/feature/workout/views/workout_tracking_page.dart` 的 `_WorkoutTrackingPageState`（`workout_tracking_page.dart:23-110`）整体替换为：

```dart
class _WorkoutTrackingPageState extends State<WorkoutTrackingPage> {
  late final WorkoutTrackingController controller =
      Get.isRegistered<WorkoutTrackingController>()
          ? Get.find<WorkoutTrackingController>()
          : Get.put(WorkoutTrackingController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorkoutResource.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _WorkoutTrackingBackground()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: AppTopNavigationBar(
                    title: widget.data.workoutTitle,
                    onBack: _back,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: AppSpacing.xl),
                    child: Obx(() {
                      final data = widget.data.copyWith(
                        status: controller.status.value,
                        distanceKm: controller.distanceKmText,
                        duration: controller.durationText,
                        calories: controller.caloriesText,
                        pace: controller.paceText,
                      );
                      return Column(
                        children: [
                          WorkoutMapSection(data: data),
                          const SizedBox(height: 4),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            child: Column(
                              children: [
                                WorkoutMetricPanel(data: data),
                                const SizedBox(height: 28),
                                WorkoutControlPanel(
                                  data: data,
                                  onPrimaryTap: controller.togglePrimary,
                                  onEnd: _endWorkout,
                                ),
                                const SizedBox(
                                  height: AppBottomTabBarMetrics.bottomOffset,
                                ),
                                WorkoutMusicCard(data: data),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _back() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
      return;
    }
  }

  // 结束运动：聚合真实数据并跳结果页（替换记录中页，结果页「完成」回到运动主页）。
  void _endWorkout() {
    controller.end();
    Get.offNamed(
      ExerciseResultPage.routeName,
      arguments: controller.toResultData(),
    );
  }
}
```

- [ ] **步骤 3：补 import**

确认 `workout_tracking_page.dart` 顶部含：

```dart
import 'package:pedometer/feature/workout/viewmodel/workout_tracking_controller.dart';
```

（`get`、`app_dimens` 的 `AppBottomTabBarMetrics`、`workout_tracking_components` 均已 import；若 `AppBottomTabBarMetrics` 未 import，加 `import 'package:pedometer/common/config/app_dimens.dart';` —— 实际已在用 `AppSpacing` 时导入。）

- [ ] **步骤 4：编写页面 smoke 测试**

创建 `test/feature/workout/workout_tracking_controller_wiring_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/feature/workout/components/workout_tracking_components.dart';
import 'package:pedometer/feature/workout/viewmodel/workout_tracking_controller.dart';
import 'package:pedometer/feature/workout/views/workout_tracking_page.dart';

void main() {
  setUp(() {
    ResourceLoader.loadForTest(colors: {'common': {}}, strings: {'common': {}});
  });

  tearDown(Get.reset);

  testWidgets('start updates the live metric panel from the controller',
      (tester) async {
    final controller = Get.put(WorkoutTrackingController());
    // 预置一个当前位置，让 start 能钉起点。
    controller.currentPosition.value = const _Stub().latLng;

    await tester.pumpWidget(
      const GetMaterialApp(home: WorkoutTrackingPage()),
    );
    await tester.pump();

    // 初始展示 0.00 公里。
    expect(find.text('0.00'), findsWidgets);

    controller.distanceMeters.value = 1234; // 1.23km
    await tester.pump();
    expect(find.text('1.23'), findsOneWidget);
  });
}

class _Stub {
  const _Stub();
  get latLng => null; // 占位：currentPosition 允许为 null，start 不依赖它出值
}
```

说明：若 `_Stub` 写法不便，直接 `controller.currentPosition.value = const LatLng(31.0, 121.0);`（import `google_maps_flutter`）。该测试核心是验证「控制器 `distanceMeters` 变化 → 面板文本随 Obx 刷新」。

- [ ] **步骤 5：运行测试**

运行：`flutter test test/feature/workout/workout_tracking_controller_wiring_test.dart`
预期：PASS。

- [ ] **步骤 6：Commit**

```bash
git add lib/feature/workout/views/workout_tracking_page.dart lib/common/routers/app_pages.dart test/feature/workout/workout_tracking_controller_wiring_test.dart
git commit -m "feat(workout): wire tracking page to controller via Obx"
```

---

## 任务 7：ExerciseResultPage 接收真实聚合结果

**文件：**
- 修改：`lib/feature/workout/views/exercise_result_page.dart`

- [ ] **步骤 1：编写失败的测试**

创建 `test/feature/workout/exercise_result_arguments_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';
import 'package:pedometer/feature/workout/views/exercise_result_page.dart';

void main() {
  setUp(() {
    ResourceLoader.loadForTest(colors: {'common': {}}, strings: {'common': {}});
  });
  tearDown(Get.reset);

  testWidgets('uses ExerciseResultData passed via Get.arguments', (tester) async {
    const real = ExerciseResultData(
      sportType: '户外跑步',
      dateText: '今天',
      distance: '3.33',
      distanceUnit: '公里',
      metrics: [],
    );

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: ExerciseResultPage.routeName,
        getPages: [
          GetPage(
            name: ExerciseResultPage.routeName,
            page: () => const ExerciseResultPage(),
          ),
        ],
        navigatorKey: Get.key,
      ),
    );
    Get.toNamed(ExerciseResultPage.routeName, arguments: real);
    await tester.pumpAndSettle();

    expect(find.text('3.33'), findsOneWidget);
  });
}
```

说明：若上面的路由跳转写法在 widget 测试中不稳，改为直接断言一个读取 `Get.arguments` 的工具方法；核心是验证「`Get.arguments` 为 `ExerciseResultData` 时优先于 mock」。

- [ ] **步骤 2：运行测试验证失败**

运行：`flutter test test/feature/workout/exercise_result_arguments_test.dart`
预期：FAIL，页面仍显示 mock 的 `2.35`，找不到 `3.33`。

- [ ] **步骤 3：编写最少实现代码**

在 `_ExerciseResultPageState`（`exercise_result_page.dart:30` 起）加一个有效数据 getter，并把 build 中所有 `widget.data` 改用它。在 state 类内加：

```dart
  ExerciseResultData get _data {
    final args = Get.arguments;
    if (args is ExerciseResultData) return args;
    return widget.data;
  }
```

然后把该文件 `build` 方法体内引用 `widget.data` 的地方替换为 `_data`（用编辑器全局替换该文件内 `widget.data` → `_data`；`widget.onDone` / `widget.onShare` 不变）。

- [ ] **步骤 4：运行测试验证通过**

运行：`flutter test test/feature/workout/exercise_result_arguments_test.dart test/feature/workout/exercise_result_page_test.dart`
预期：PASS（新测试通过；既有 `exercise_result_page_test.dart` 因无 arguments 回退 `widget.data`，仍通过）。

- [ ] **步骤 5：Commit**

```bash
git add lib/feature/workout/views/exercise_result_page.dart test/feature/workout/exercise_result_arguments_test.dart
git commit -m "feat(workout): result page reads real aggregated data from Get.arguments"
```

---

## 任务 8：全量验证

- [ ] **步骤 1：静态分析**

运行：`flutter analyze`
预期：No issues found.

- [ ] **步骤 2：全量测试**

运行：`flutter test`
预期：所有测试 PASS（含既有的 workout / home / mine 套件）。

- [ ] **步骤 3：真机 / 模拟器手动验证**

前置：确认 Google Maps API key 已在 `android/app/src/main/AndroidManifest.xml` 与 iOS `AppDelegate` 配好（见规格「范围外」）。
运行：`flutter run`，进入运动追踪页：
- 点击「开始」→ 距离从 0.00 起涨，时长每秒 +1，卡路里增长，移动后配速出值。
- 地图出现绿色轨迹随移动生长、起点出现绿色 marker、当前位置箭头随行进方向旋转。
- 点击切换暂停（时长冻结），再点继续；长按 3 秒进入结果页，结果页数值与运动中一致。

- [ ] **步骤 4：最终 Commit（如有 lint 微调）**

```bash
git add -A
git commit -m "chore(workout): finalize live tracking wiring"
```

---

## 自检结论

- **规格覆盖度：** 距离累计(任务3/5)、时长(任务3)、卡路里(任务1/3)、配速(任务2/3)、轨迹 Polyline(任务5)、起点 marker(任务5)、方向旋转(任务5)、状态机修正(任务3/6)、结果页真实数据(任务3/7) —— 全覆盖。
- **占位符扫描：** 任务 6 步骤 4 / 任务 7 步骤 1 的测试给了「若写法不稳的退路」属测试稳健性说明，核心断言均具体；无 TODO / 待定。
- **类型一致性：** `onFix(Position, LatLng)`、`togglePrimary()`、`toResultData()`、`distanceKmText/durationText/caloriesText/paceText`、`copyWith(distanceKm/duration/calories/pace)`、`_trackingMarkers/_trackingPolylines` 在定义与调用处命名一致。
