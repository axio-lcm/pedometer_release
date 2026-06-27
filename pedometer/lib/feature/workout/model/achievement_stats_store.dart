import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 成就累积统计（运动维度），持久化于 SharedPreferences。
///
/// 每次「开始运动」结束写入运动记录时调用 [recordWorkout] 同步累积；
/// 成就徽章页据此计算各徽章进度（达标才点亮彩色徽章）。
/// 步数 / 卡路里类徽章不在此处，改由首页 HealthSyncRuntime 提供。
class AchievementStatsStore {
  AchievementStatsStore._();

  static const String _prefsKey = 'achievement_stats';

  static double _totalDistanceKm = 0;
  static int _maxSessionMinutes = 0;
  static final Set<String> _runDays = {}; // yyyy-MM-dd
  static final Map<String, double> _monthDistanceKm = {}; // yyyy-MM -> km
  static final Set<String> _weekMondays = {}; // 有运动的周的周一 yyyy-MM-dd

  /// 数据变更通知，成就页据此刷新。
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// 累计跑步距离（公里）：初级跑者 / 百公里 / 200 / 进阶 / 500 公里。
  static double get totalDistanceKm => _totalDistanceKm;

  /// 单次最长时长（分钟）：时间掌控者。
  static int get maxSessionMinutes => _maxSessionMinutes;

  /// 累计运动天数：坚持不懈。
  static int get runDaysCount => _runDays.length;

  /// 单月最高距离（公里）：月度之星。
  static double get bestMonthDistanceKm =>
      _monthDistanceKm.values.fold(0.0, (m, v) => v > m ? v : m);

  /// 最长连续运动周数：周周打卡。
  static int get longestWeekStreak => _longestWeekStreak();

  /// 启动时从持久化恢复。
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _totalDistanceKm = (map['totalDistanceKm'] as num?)?.toDouble() ?? 0;
      _maxSessionMinutes = (map['maxSessionMinutes'] as num?)?.toInt() ?? 0;
      _runDays
        ..clear()
        ..addAll(((map['runDays'] as List?) ?? const []).map((e) => '$e'));
      _monthDistanceKm
        ..clear()
        ..addAll(
          ((map['monthDistanceKm'] as Map?) ?? const {}).map(
            (k, v) => MapEntry('$k', (v as num).toDouble()),
          ),
        );
      _weekMondays
        ..clear()
        ..addAll(((map['weekMondays'] as List?) ?? const []).map((e) => '$e'));
      revision.value++;
    } catch (_) {
      // 读取失败不影响功能，按空统计处理。
    }
  }

  /// 一次运动结束后累积。[distanceKm] 公里、[durationMinutes] 分钟、[endedAt] 结束时刻。
  static Future<void> recordWorkout({
    required double distanceKm,
    required int durationMinutes,
    required DateTime endedAt,
  }) async {
    if (distanceKm.isFinite && distanceKm > 0) {
      _totalDistanceKm += distanceKm;
      final ym = _monthKey(endedAt);
      _monthDistanceKm[ym] = (_monthDistanceKm[ym] ?? 0) + distanceKm;
    }
    if (durationMinutes > _maxSessionMinutes) {
      _maxSessionMinutes = durationMinutes;
    }
    _runDays.add(_dayKey(endedAt));
    _weekMondays.add(_dayKey(_mondayOf(endedAt)));
    revision.value++;
    await _persist();
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode({
          'totalDistanceKm': _totalDistanceKm,
          'maxSessionMinutes': _maxSessionMinutes,
          'runDays': _runDays.toList(),
          'monthDistanceKm': _monthDistanceKm,
          'weekMondays': _weekMondays.toList(),
        }),
      );
    } catch (_) {
      // 落盘失败忽略，下次结束运动会再次尝试。
    }
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
  static String _dayKey(DateTime d) =>
      '${d.year}-${_two(d.month)}-${_two(d.day)}';
  static String _monthKey(DateTime d) => '${d.year}-${_two(d.month)}';
  static DateTime _mondayOf(DateTime d) {
    final date = DateTime(d.year, d.month, d.day);
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// 把有运动的周（按周一日期）排序，统计最长「相邻周一相差 7 天」的连续段。
  static int _longestWeekStreak() {
    if (_weekMondays.isEmpty) return 0;
    final mondays = _weekMondays.map(DateTime.parse).toList()..sort();
    var longest = 1;
    var current = 1;
    for (var i = 1; i < mondays.length; i++) {
      final diff = mondays[i].difference(mondays[i - 1]).inDays;
      if (diff == 7) {
        current++;
        if (current > longest) longest = current;
      } else if (diff > 7) {
        current = 1;
      }
    }
    return longest;
  }
}
