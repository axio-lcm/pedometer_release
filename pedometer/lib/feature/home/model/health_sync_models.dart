enum HealthSyncSource { appleHealth, healthConnect }

enum HealthSyncDataType { steps, distance, calories, activeMinutes }

class HealthDailySummary {
  final DateTime date;
  final int steps;
  final double distanceKm;
  final double caloriesKcal;
  final int activeMinutes;
  final HealthSyncSource source;

  const HealthDailySummary({
    required this.date,
    required this.steps,
    required this.distanceKm,
    required this.caloriesKcal,
    required this.activeMinutes,
    required this.source,
  });
}
