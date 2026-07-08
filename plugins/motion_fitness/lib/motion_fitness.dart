import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum MotionFitnessAuthorizationStatus {
  authorized,
  denied,
  restricted,
  unsupported,
  unknown,
}

/// 单次运动采样：今日步数 + 真实距离（米）。
///
/// [distanceMeters] 取自 CMPedometerData.distance；设备不支持距离统计时为 0，
/// 消费方应在为 0 时回退到按步数估算。
class MotionFitnessSample {
  const MotionFitnessSample({
    required this.steps,
    required this.distanceMeters,
  });

  final int steps;
  final double distanceMeters;
}

/// 某一自然日的运动汇总：日期 + 步数 + 真实距离（米）。
///
/// 由 [MotionFitness.historyDailyData] 回查最近数日数据时返回。
class MotionFitnessDailySample {
  const MotionFitnessDailySample({
    required this.date,
    required this.steps,
    required this.distanceMeters,
  });

  final DateTime date;
  final int steps;
  final double distanceMeters;
}

class MotionFitness {
  MotionFitness._();

  static const MethodChannel _channel = MethodChannel(
    'pedometer/motion_fitness',
  );
  static const EventChannel _stepChannel = EventChannel(
    'pedometer/motion_fitness_steps',
  );
  static const EventChannel _paceChannel = EventChannel(
    'pedometer/motion_fitness_pace',
  );

  static Future<MotionFitnessAuthorizationStatus> requestAuthorization() async {
    if (kIsWeb) return MotionFitnessAuthorizationStatus.unsupported;

    try {
      final status = await _channel.invokeMethod<String>(
        'requestAuthorization',
      );
      return _parseStatus(status);
    } on PlatformException {
      return MotionFitnessAuthorizationStatus.unknown;
    } on MissingPluginException {
      return MotionFitnessAuthorizationStatus.unsupported;
    }
  }

  static Future<MotionFitnessAuthorizationStatus> authorizationStatus() async {
    if (kIsWeb) return MotionFitnessAuthorizationStatus.unsupported;

    try {
      final status = await _channel.invokeMethod<String>('authorizationStatus');
      return _parseStatus(status);
    } on PlatformException {
      return MotionFitnessAuthorizationStatus.unknown;
    } on MissingPluginException {
      return MotionFitnessAuthorizationStatus.unsupported;
    }
  }

  static Future<bool> isStepCountingAvailable() async {
    if (kIsWeb) return false;

    try {
      return await _channel.invokeMethod<bool>('isStepCountingAvailable') ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<bool> isPaceAvailable() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return false;

    try {
      return await _channel.invokeMethod<bool>('isPaceAvailable') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Returns the platform's best available "today steps" value.
  ///
  /// iOS uses Core Motion historical pedometer data. Android uses the hardware
  /// step counter with an app-local daily baseline when Android tracking is
  /// enabled.
  static Future<int?> todaySteps() async {
    if (kIsWeb) return null;

    try {
      final steps = await _channel.invokeMethod<int>('todaySteps');
      return steps?.clamp(0, 1 << 31);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Returns today's steps together with the real walked distance (meters).
  ///
  /// Distance comes from Core Motion's `CMPedometerData.distance`; it is 0 when
  /// the device cannot report distance, in which case callers should fall back
  /// to a step-based estimate.
  static Future<MotionFitnessSample?> todayActivity() async {
    if (kIsWeb) return null;

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'todayActivity',
      );
      if (result == null) return null;
      return _sampleFromMap(result);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Returns per-day {steps, distance} for the last [days] calendar days.
  ///
  /// Core Motion keeps roughly 7 days of data, so [days] is clamped to 1..7 on
  /// the native side. Days that fail or fall outside the retention window are
  /// omitted; callers merge the result into their own persisted history.
  static Future<List<MotionFitnessDailySample>> historyDailyData(
    int days,
  ) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return const <MotionFitnessDailySample>[];
    }

    try {
      final entries = await _channel.invokeMethod<List<dynamic>>(
        'historyDailyData',
        {'days': days},
      );
      if (entries == null) return const <MotionFitnessDailySample>[];
      final samples = <MotionFitnessDailySample>[];
      for (final entry in entries) {
        if (entry is! Map) continue;
        final dateMs = entry['date'];
        if (dateMs is! num) continue;
        final sample = _sampleFromMap(entry);
        samples.add(
          MotionFitnessDailySample(
            date: DateTime.fromMillisecondsSinceEpoch(dateMs.toInt()),
            steps: sample.steps,
            distanceMeters: sample.distanceMeters,
          ),
        );
      }
      return samples;
    } on PlatformException {
      return const <MotionFitnessDailySample>[];
    } on MissingPluginException {
      return const <MotionFitnessDailySample>[];
    }
  }

  /// Returns today's hourly step buckets from the platform motion sensor.
  ///
  /// iOS uses Core Motion's historical pedometer query for each hour. Values
  /// represent the current device's motion data and may differ from Apple
  /// Health totals that merge Apple Watch / iPhone / third-party sources.
  static Future<List<int>> todayHourlySteps() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return const <int>[];
    }

    try {
      final values = await _channel.invokeMethod<List<dynamic>>(
        'todayHourlySteps',
      );
      if (values == null) return const <int>[];
      return [
        for (final value in values.take(24))
          value is num ? value.round().clamp(0, 1 << 31) : 0,
      ];
    } on PlatformException {
      return const <int>[];
    } on MissingPluginException {
      return const <int>[];
    }
  }

  /// Emits today's steps and real distance from the native motion sensor.
  ///
  /// The stream is intentionally lossy and best-effort; consumers should keep
  /// HealthKit / Health Connect as the preferred historical source.
  static Stream<MotionFitnessSample> todayStepStream() {
    if (kIsWeb) return const Stream<MotionFitnessSample>.empty();

    return _stepChannel
        .receiveBroadcastStream()
        .map((event) {
          if (event is Map) return _sampleFromMap(event);
          if (event is num) {
            return MotionFitnessSample(
              steps: event.round(),
              distanceMeters: 0,
            );
          }
          return const MotionFitnessSample(steps: 0, distanceMeters: 0);
        })
        .where((sample) => sample.steps >= 0);
  }

  static MotionFitnessSample _sampleFromMap(Map<dynamic, dynamic> map) {
    final steps = map['steps'];
    final distance = map['distance'];
    return MotionFitnessSample(
      steps: steps is num ? steps.round().clamp(0, 1 << 31) : 0,
      distanceMeters: distance is num && distance.isFinite && distance > 0
          ? distance.toDouble()
          : 0,
    );
  }

  /// Emits current Core Motion pace as a per-kilometer duration on iOS.
  ///
  /// Values are best-effort and may be sparse/null while Core Motion is still
  /// estimating gait.
  static Stream<Duration> currentPaceStream() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return const Stream<Duration>.empty();
    }

    return _paceChannel
        .receiveBroadcastStream()
        .map((event) {
          final secondsPerMeter = switch (event) {
            {'secondsPerMeter': final num value} => value.toDouble(),
            final num value => value.toDouble(),
            _ => 0.0,
          };
          if (!secondsPerMeter.isFinite || secondsPerMeter <= 0) {
            return Duration.zero;
          }
          return Duration(
            milliseconds: (secondsPerMeter * 1000 * 1000).round(),
          );
        })
        .where((pace) => pace > Duration.zero);
  }

  static MotionFitnessAuthorizationStatus _parseStatus(String? status) {
    return switch (status) {
      'authorized' => MotionFitnessAuthorizationStatus.authorized,
      'denied' => MotionFitnessAuthorizationStatus.denied,
      'restricted' => MotionFitnessAuthorizationStatus.restricted,
      'unsupported' => MotionFitnessAuthorizationStatus.unsupported,
      _ => MotionFitnessAuthorizationStatus.unknown,
    };
  }
}
