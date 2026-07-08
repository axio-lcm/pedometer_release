import 'package:motion_fitness/motion_fitness.dart' as plugin;

export 'package:motion_fitness/motion_fitness.dart'
    show MotionFitnessSample, MotionFitnessDailySample;

enum MotionFitnessAuthorizationStatus {
  authorized,
  denied,
  restricted,
  unsupported,
  unknown,
}

class MotionFitnessPermissionService {
  MotionFitnessPermissionService._();

  static Future<MotionFitnessAuthorizationStatus> requestAuthorization() async {
    return _fromPlugin(await plugin.MotionFitness.requestAuthorization());
  }

  static Future<MotionFitnessAuthorizationStatus> authorizationStatus() async {
    return _fromPlugin(await plugin.MotionFitness.authorizationStatus());
  }

  static Future<bool> isStepCountingAvailable() async {
    return plugin.MotionFitness.isStepCountingAvailable();
  }

  static Future<bool> isPaceAvailable() async {
    return plugin.MotionFitness.isPaceAvailable();
  }

  static Future<int?> todaySteps() async {
    return plugin.MotionFitness.todaySteps();
  }

  /// 今日步数 + 真实距离（米）。距离不可用时 distanceMeters 为 0。
  static Future<plugin.MotionFitnessSample?> todayActivity() async {
    return plugin.MotionFitness.todayActivity();
  }

  /// 回查最近 [days] 天（iOS 上限约 7 天）的每日步数 + 真实距离。
  static Future<List<plugin.MotionFitnessDailySample>> historyDailyData(
    int days,
  ) async {
    return plugin.MotionFitness.historyDailyData(days);
  }

  static Future<List<int>> todayHourlySteps() async {
    return plugin.MotionFitness.todayHourlySteps();
  }

  static Stream<plugin.MotionFitnessSample> todayStepStream() {
    return plugin.MotionFitness.todayStepStream();
  }

  static Stream<Duration> currentPaceStream() {
    return plugin.MotionFitness.currentPaceStream();
  }

  static MotionFitnessAuthorizationStatus _fromPlugin(
    plugin.MotionFitnessAuthorizationStatus status,
  ) {
    return switch (status) {
      plugin.MotionFitnessAuthorizationStatus.authorized =>
        MotionFitnessAuthorizationStatus.authorized,
      plugin.MotionFitnessAuthorizationStatus.denied =>
        MotionFitnessAuthorizationStatus.denied,
      plugin.MotionFitnessAuthorizationStatus.restricted =>
        MotionFitnessAuthorizationStatus.restricted,
      plugin.MotionFitnessAuthorizationStatus.unsupported =>
        MotionFitnessAuthorizationStatus.unsupported,
      plugin.MotionFitnessAuthorizationStatus.unknown =>
        MotionFitnessAuthorizationStatus.unknown,
    };
  }
}
