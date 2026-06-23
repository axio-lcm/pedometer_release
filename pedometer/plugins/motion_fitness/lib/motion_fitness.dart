import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum MotionFitnessAuthorizationStatus {
  authorized,
  denied,
  restricted,
  unsupported,
  unknown,
}

class MotionFitness {
  MotionFitness._();

  static const MethodChannel _channel = MethodChannel(
    'pedometer/motion_fitness',
  );
  static const EventChannel _stepChannel = EventChannel(
    'pedometer/motion_fitness_steps',
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

  /// Emits today's steps from the native motion sensor.
  ///
  /// The stream is intentionally lossy and best-effort; consumers should keep
  /// HealthKit / Health Connect as the preferred historical source.
  static Stream<int> todayStepStream() {
    if (kIsWeb) return const Stream<int>.empty();

    return _stepChannel
        .receiveBroadcastStream()
        .map((event) {
          if (event is int) return event;
          if (event is num) return event.round();
          if (event is Map && event['steps'] is num) {
            return (event['steps'] as num).round();
          }
          return 0;
        })
        .where((steps) => steps >= 0);
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
