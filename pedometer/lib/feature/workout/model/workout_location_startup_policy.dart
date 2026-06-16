class WorkoutLocationStartupPolicy {
  static const Duration currentFixTimeout = Duration(seconds: 8);
  static const Duration startupFixTimeout = Duration(seconds: 3);
  static const Duration cachedPositionMaxAge = Duration(minutes: 2);

  const WorkoutLocationStartupPolicy._();

  static bool canUseCachedPosition({
    required DateTime recordedAt,
    required DateTime now,
  }) {
    if (recordedAt.isAfter(now)) {
      return false;
    }

    return now.difference(recordedAt) <= cachedPositionMaxAge;
  }
}
