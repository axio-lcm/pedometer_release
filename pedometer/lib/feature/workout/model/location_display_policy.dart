import 'package:pedometer/common/config/localized_text.dart';

/// 定位点的“可显示性”分级。
///
/// 注意：这与 [LocationStabilityFilter]（轨迹质量 / 抖动抑制）是两个不同的职责。
/// 显示层只关心“能不能把当前位置画出来、给用户什么提示”，因此对精度的容忍度
/// 比轨迹记录宽松得多 —— 否则冷启动 / 室内 / 城市高楼下的粗定位会被全部丢弃，
/// 界面就会一直卡在“等待定位信号”。
enum LocationFixQuality {
  /// 精度良好，正常显示精度数值。
  precise,

  /// 精度偏弱但仍可用：照常显示，但提示信号较弱。
  weak,

  /// 不可用（无效精度或精度过差）：不显示，继续等待。
  unusable,
}

class LocationDisplayDecision {
  final LocationFixQuality quality;
  final bool showOnMap;
  final String statusLabel;

  const LocationDisplayDecision({
    required this.quality,
    required this.showOnMap,
    required this.statusLabel,
  });
}

class LocationDisplayPolicy {
  /// 精度优于该值视为“精准”。
  final double preciseAccuracyMeters;

  /// 精度劣于该值视为不可用，继续等待更好的信号。
  final double usableAccuracyMeters;

  const LocationDisplayPolicy({
    this.preciseAccuracyMeters = 35,
    this.usableAccuracyMeters = 200,
  });

  LocationDisplayDecision evaluate({required double accuracyMeters}) {
    if (accuracyMeters <= 0 || accuracyMeters > usableAccuracyMeters) {
      return LocationDisplayDecision(
        quality: LocationFixQuality.unusable,
        showOnMap: false,
        statusLabel: lt('Waiting for GPS signal', '等待定位信号'),
      );
    }

    if (accuracyMeters > preciseAccuracyMeters) {
      return LocationDisplayDecision(
        quality: LocationFixQuality.weak,
        showOnMap: true,
        statusLabel: lt(
          'Weak GPS signal · ${accuracyMeters.toStringAsFixed(0)} m',
          '定位信号较弱 · ${accuracyMeters.toStringAsFixed(0)} 米',
        ),
      );
    }

    return LocationDisplayDecision(
      quality: LocationFixQuality.precise,
      showOnMap: true,
      statusLabel: lt(
        'GPS accuracy ${accuracyMeters.toStringAsFixed(0)} m',
        '定位精度 ${accuracyMeters.toStringAsFixed(0)} 米',
      ),
    );
  }
}
