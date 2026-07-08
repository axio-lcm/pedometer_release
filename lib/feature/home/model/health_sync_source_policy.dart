import 'package:flutter/foundation.dart';
import 'package:pedometer/common/config/localized_text.dart';
import 'package:pedometer/feature/home/model/health_sync_models.dart';

/// 按平台决定可用的健康数据来源，并在展示标题与插件来源枚举之间转换。
///
/// 与原生插件实现保持一致：iOS / macOS 走 HealthKit（Apple Health），
/// Android 走 Health Connect；其它平台暂不支持健康同步。
class HealthSyncSourcePolicy {
  const HealthSyncSourcePolicy._();

  static const String appleHealthTitle = 'Apple Health';
  static const String healthConnectTitle = 'Health Connect';

  /// 当前平台支持的健康数据来源（顺序即展示顺序）。
  static List<HealthSyncSource> sourcesFor(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return const [HealthSyncSource.appleHealth];
      case TargetPlatform.android:
        return const [HealthSyncSource.healthConnect];
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return const [];
    }
  }

  /// 指定来源在当前平台是否受支持。
  static bool isSupported(HealthSyncSource source, TargetPlatform platform) {
    return sourcesFor(platform).contains(source);
  }

  /// 来源枚举对应的展示标题。
  static String titleFor(HealthSyncSource source) {
    return switch (source) {
      HealthSyncSource.appleHealth => appleHealthTitle,
      HealthSyncSource.healthConnect => healthConnectTitle,
      HealthSyncSource.motionSensor => lt('Motion Sensor', '运动传感器'),
    };
  }

  /// 展示标题对应的来源枚举，未知标题返回 null。
  static HealthSyncSource? sourceForTitle(String title) {
    return switch (title) {
      appleHealthTitle => HealthSyncSource.appleHealth,
      healthConnectTitle => HealthSyncSource.healthConnect,
      _ => null,
    };
  }
}
