import 'package:motion_fitness/motion_fitness.dart' as plugin;

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

  static Future<int?> todaySteps() async {
    return plugin.MotionFitness.todaySteps();
  }

  static Stream<int> todayStepStream() {
    return plugin.MotionFitness.todayStepStream();
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
