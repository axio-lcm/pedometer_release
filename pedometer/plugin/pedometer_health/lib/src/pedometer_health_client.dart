import 'package:flutter/services.dart';

import 'pedometer_health_models.dart';

class PedometerHealthClient {
  static const String channelName = 'pedometer_health';

  final MethodChannel _channel;

  PedometerHealthClient({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  Future<bool> isAvailable({required HealthSyncSource source}) async {
    final available = await _channel.invokeMethod<bool>('isAvailable', {
      'source': source.wireName,
    });
    return available ?? false;
  }

  Future<bool> requestAuthorization({
    required HealthSyncSource source,
    required List<HealthSyncDataType> types,
  }) async {
    final granted = await _channel.invokeMethod<bool>('requestAuthorization', {
      'source': source.wireName,
      'types': types.map((type) => type.wireName).toList(),
    });
    return granted ?? false;
  }

  Future<List<HealthDailySummary>> fetchDailySummaries({
    required HealthSyncSource source,
    required DateTime startDate,
    required DateTime endDate,
    required List<HealthSyncDataType> types,
  }) async {
    final payload = await _channel
        .invokeListMethod<Object?>('fetchDailySummaries', {
          'source': source.wireName,
          'startDate': _dateOnly(startDate),
          'endDate': _dateOnly(endDate),
          'types': types.map((type) => type.wireName).toList(),
        });

    return [
      for (final item in payload ?? const [])
        HealthDailySummary.fromMap(Map<Object?, Object?>.from(item! as Map)),
    ];
  }

  String _dateOnly(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    return local.toIso8601String().split('T').first;
  }
}
