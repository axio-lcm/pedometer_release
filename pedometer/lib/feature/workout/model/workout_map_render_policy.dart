class WorkoutMapRenderPolicy {
  const WorkoutMapRenderPolicy._();

  static bool canCreatePlatformMap({
    required bool allowPlatformMap,
    required bool isWidgetTest,
  }) {
    return !isWidgetTest && allowPlatformMap;
  }
}
