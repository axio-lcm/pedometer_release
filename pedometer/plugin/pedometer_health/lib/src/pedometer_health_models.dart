enum HealthSyncSource {
  appleHealth,
  healthConnect;

  static HealthSyncSource fromWire(String value) {
    return HealthSyncSource.values.firstWhere(
      (source) => source.wireName == value,
      orElse: () => HealthSyncSource.appleHealth,
    );
  }

  String get wireName {
    return switch (this) {
      HealthSyncSource.appleHealth => 'appleHealth',
      HealthSyncSource.healthConnect => 'healthConnect',
    };
  }
}

enum HealthSyncDataType {
  steps,
  distance,
  calories,
  activeMinutes;

  String get wireName {
    return switch (this) {
      HealthSyncDataType.steps => 'steps',
      HealthSyncDataType.distance => 'distance',
      HealthSyncDataType.calories => 'calories',
      HealthSyncDataType.activeMinutes => 'activeMinutes',
    };
  }
}

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

  factory HealthDailySummary.fromMap(Map<Object?, Object?> map) {
    return HealthDailySummary(
      date: DateTime.parse(map['date']! as String),
      steps: (map['steps'] as num?)?.round() ?? 0,
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0,
      caloriesKcal: (map['caloriesKcal'] as num?)?.toDouble() ?? 0,
      activeMinutes: (map['activeMinutes'] as num?)?.round() ?? 0,
      source: HealthSyncSource.fromWire(
        map['source'] as String? ?? HealthSyncSource.appleHealth.wireName,
      ),
    );
  }
}
