class WorkoutMapRenderPolicy {
  const WorkoutMapRenderPolicy._();

  static bool canCreatePlatformMap({required bool isWidgetTest}) {
    return !isWidgetTest;
  }
}
