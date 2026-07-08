import 'dart:collection';

/// 滚动窗口实时配速。样本为 (累计距离米, 时间戳)。
/// 取最近 [windowDuration] 内的样本，要求窗口距离 ≥ [minWindowMeters] 才出值，
/// 避免起步 / 站立时配速剧烈抖动。
class WorkoutPacePolicy {
  WorkoutPacePolicy({
    this.windowDuration = const Duration(seconds: 20),
    this.minWindowMeters = 30,
  });

  final Duration windowDuration;
  final double minWindowMeters;

  final Queue<_PaceSample> _samples = Queue<_PaceSample>();

  void addSample({required double cumulativeMeters, required DateTime at}) {
    _samples.addLast(_PaceSample(cumulativeMeters, at));
    // 移除窗口外旧样本，但至少保留一个用于差分。
    while (_samples.length > 1 &&
        at.difference(_samples.first.at) > windowDuration) {
      _samples.removeFirst();
    }
  }

  void reset() => _samples.clear();

  /// 每公里配速；数据不足返回 null。
  Duration? get pacePerKm {
    if (_samples.length < 2) return null;
    final first = _samples.first;
    final last = _samples.last;
    final meters = last.cumulativeMeters - first.cumulativeMeters;
    if (meters < minWindowMeters) return null;
    final secs = last.at.difference(first.at).inMilliseconds / 1000;
    if (secs <= 0) return null;
    final secsPerKm = secs / (meters / 1000);
    return Duration(milliseconds: (secsPerKm * 1000).round());
  }
}

class _PaceSample {
  const _PaceSample(this.cumulativeMeters, this.at);
  final double cumulativeMeters;
  final DateTime at;
}
