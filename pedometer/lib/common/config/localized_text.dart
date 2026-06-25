import 'package:intl/intl.dart';
import 'package:pedometer/common/config/resource_loader.dart';

/// 当前是否为中文（含简体 zh_Hans / 繁体 zh_Hant）。
bool get isZhLocale => ResourceLoader.languageCode.startsWith('zh');

/// 兼容旧的行内双语文案。
///
/// 新语言优先从 common/string*.json 的 `lt_*` key 取值；资源加载器会按
/// 当前语言、系统语言、安全兜底资源链解析，代码层不再做中英二选一。
String lt(String en, String _) {
  final templated = _localizedTemplateText(en);
  if (templated != null) return templated;

  final value = ResourceLoader.string(
    'common',
    _legacyTextKey(en),
    fallback: en,
  );
  if (value.isNotEmpty) return value;
  return en;
}

String legacyTextKey(String en) => _legacyTextKey(en);

String _legacyTextKey(String en) {
  final slug = en
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return 'lt_$slug';
}

String? _localizedTemplateText(String en) {
  String? fromTemplate(String key, Map<String, String> values) {
    final template = ResourceLoader.string('common', key);
    if (template.isEmpty) return null;
    return values.entries.fold<String>(
      template,
      (value, entry) => value.replaceAll('{{${entry.key}}}', entry.value),
    );
  }

  final connected = RegExp(r'^(.+) Connected$').firstMatch(en);
  if (connected != null) {
    return fromTemplate('lt_template_source_connected', {
      'title': connected.group(1)!,
    });
  }

  final disconnected = RegExp(r'^(.+) Disconnected$').firstMatch(en);
  if (disconnected != null) {
    return fromTemplate('lt_template_source_disconnected', {
      'title': disconnected.group(1)!,
    });
  }

  final unavailable = RegExp(
    r'^(.+) is unavailable on this device$',
  ).firstMatch(en);
  if (unavailable != null) {
    return fromTemplate('lt_template_source_unavailable', {
      'title': unavailable.group(1)!,
    });
  }

  final unsupported = RegExp(
    r'^(.+) is not supported on this platform$',
  ).firstMatch(en);
  if (unsupported != null) {
    return fromTemplate('lt_template_source_unsupported', {
      'title': unsupported.group(1)!,
    });
  }

  final authIncomplete = RegExp(
    r'^(.+) authorization was not completed$',
  ).firstMatch(en);
  if (authIncomplete != null) {
    return fromTemplate('lt_template_source_auth_incomplete', {
      'title': authIncomplete.group(1)!,
    });
  }

  final syncing = RegExp(r'^Syncing (.+)\.\.\.$').firstMatch(en);
  if (syncing != null) {
    return fromTemplate('lt_template_source_syncing', {
      'title': syncing.group(1)!,
    });
  }

  final syncSuccess = RegExp(r'^(.+) sync successful$').firstMatch(en);
  if (syncSuccess != null) {
    return fromTemplate('lt_template_source_sync_success', {
      'title': syncSuccess.group(1)!,
    });
  }

  final sourceAuthorized = RegExp(
    r'^(.+) health data authorized$',
  ).firstMatch(en);
  if (sourceAuthorized != null) {
    return fromTemplate('lt_template_source_health_authorized', {
      'title': sourceAuthorized.group(1)!,
    });
  }

  final sourceNotAuthorized = RegExp(
    r'^(.+) is not authorized\. Please allow access in the system Health settings\.$',
  ).firstMatch(en);
  if (sourceNotAuthorized != null) {
    return fromTemplate('lt_template_source_not_authorized', {
      'title': sourceNotAuthorized.group(1)!,
    });
  }

  final sourcePending = RegExp(
    r'^(.+) authorization is pending\. Sync to verify data access\.$',
  ).firstMatch(en);
  if (sourcePending != null) {
    return fromTemplate('lt_template_source_auth_pending', {
      'title': sourcePending.group(1)!,
    });
  }

  final requestingPermission = RegExp(
    r'^Requesting (.+) permission\.\.\.$',
  ).firstMatch(en);
  if (requestingPermission != null) {
    return fromTemplate('lt_template_source_requesting_permission', {
      'title': requestingPermission.group(1)!,
    });
  }

  final syncTimedOut = RegExp(
    r'^(.+) sync timed out\. Please try again later\.$',
  ).firstMatch(en);
  if (syncTimedOut != null) {
    return fromTemplate('lt_template_source_sync_timeout', {
      'title': syncTimedOut.group(1)!,
    });
  }

  final syncFailed = RegExp(r'^(.+) sync failed: (.+)$').firstMatch(en);
  if (syncFailed != null) {
    return fromTemplate('lt_template_source_sync_failed', {
      'title': syncFailed.group(1)!,
      'error': syncFailed.group(2)!,
    });
  }

  final noHealthData = RegExp(
    r'^No health data was read from (.+)\. Allow access in the system Health settings and try again\.$',
  ).firstMatch(en);
  if (noHealthData != null) {
    return fromTemplate('lt_template_source_no_health_data', {
      'title': noHealthData.group(1)!,
    });
  }

  final syncedItems = RegExp(r'^Synced (\d+) items$').firstMatch(en);
  if (syncedItems != null) {
    return fromTemplate('lt_template_synced_items', {
      'count': syncedItems.group(1)!,
    });
  }

  final itemCount = RegExp(r'^(\d+) items$').firstMatch(en);
  if (itemCount != null) {
    return fromTemplate('lt_template_items', {'count': itemCount.group(1)!});
  }

  final steps = RegExp(r'^([0-9,]+) steps$').firstMatch(en);
  if (steps != null) {
    return fromTemplate('lt_template_steps', {'count': steps.group(1)!});
  }

  final labelledSteps = RegExp(r'^(.+) · ([0-9,]+) steps$').firstMatch(en);
  if (labelledSteps != null) {
    return fromTemplate('lt_template_labelled_steps', {
      'label': labelledSteps.group(1)!,
      'count': labelledSteps.group(2)!,
    });
  }

  final gpsAccuracy = RegExp(r'^GPS accuracy ([0-9.]+) m$').firstMatch(en);
  if (gpsAccuracy != null) {
    return fromTemplate('lt_template_gps_accuracy', {
      'value': gpsAccuracy.group(1)!,
    });
  }

  final weakGps = RegExp(r'^Weak GPS signal · ([0-9.]+) m$').firstMatch(en);
  if (weakGps != null) {
    return fromTemplate('lt_template_weak_gps_accuracy', {
      'value': weakGps.group(1)!,
    });
  }

  final updated = RegExp(r'^Updated: (.+)$').firstMatch(en);
  if (updated != null) {
    return fromTemplate('lt_template_updated_time', {
      'time': updated.group(1)!,
    });
  }

  final syncedWeekDays = RegExp(
    r'^Synced (\d+) days of health data this week$',
  ).firstMatch(en);
  if (syncedWeekDays != null) {
    return fromTemplate('lt_template_synced_week_days', {
      'count': syncedWeekDays.group(1)!,
    });
  }

  final syncedMonthDays = RegExp(
    r'^Synced (\d+) days of health data this month$',
  ).firstMatch(en);
  if (syncedMonthDays != null) {
    return fromTemplate('lt_template_synced_month_days', {
      'count': syncedMonthDays.group(1)!,
    });
  }

  final lastSync = RegExp(r'^Last sync: (.+)$').firstMatch(en);
  if (lastSync != null) {
    return fromTemplate('lt_template_last_sync', {
      'time': lt(lastSync.group(1)!, lastSync.group(1)!),
    });
  }

  return null;
}

String shortMonthName(int month) {
  final safeMonth = month.clamp(1, 12).toInt();
  return DateFormat.MMM(_intlLocaleName).format(DateTime(2024, safeMonth));
}

String localizedShortDate(DateTime date) {
  return DateFormat.MMMd(_intlLocaleName).format(date);
}

String localizedDayTitle(DateTime date) {
  return DateFormat.MMMEd(_intlLocaleName).format(date);
}

String localizedMonthTitle(DateTime date) {
  return DateFormat.yMMMM(_intlLocaleName).format(date);
}

String localizedDateTime(DateTime date) {
  return '${DateFormat.yMMMd(_intlLocaleName).format(date)} '
      '${DateFormat.Hm(_intlLocaleName).format(date)}';
}

List<String> localizedWeekdayLabels({bool narrow = false}) {
  final pattern = narrow ? 'EEEEE' : 'E';
  final monday = DateTime(2024);
  return List.generate(
    7,
    (index) => DateFormat(
      pattern,
      _intlLocaleName,
    ).format(monday.add(Duration(days: index))),
  );
}

String get _intlLocaleName {
  switch (ResourceLoader.languageCode) {
    case 'zh_Hans':
      return 'zh_CN';
    case 'zh_Hant':
      return 'zh_TW';
    default:
      return ResourceLoader.languageCode;
  }
}
