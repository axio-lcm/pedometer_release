/// 应用级常量配置。
///
/// 网络相关常量（baseUrl / 反馈接口 / AES 密钥 / sct）与 al_led_banner 保持一致，
/// 以复用同一套后端接口；bundleId 为本应用自身的包名。
abstract final class Constants {
  static const String appName = 'Pedometer';
  static const String bundleId = 'com.pedometer.step.counter.walking.tracker';

  /// 请求参数 AES-256-CBC 加密密钥与偏移量（与服务端约定，须与 al_led_banner 一致）。
  static const String aesKey = 'tomata@ciVDXYvUOD5uMn9t5hogVQBVF';
  static const String aesIV = 'avlamBpsrytoKn49';
  static const String sct = 'avlamBpsrytoKn49';
}

/// 后端接口地址。
abstract final class APIs {
  static const String baseUrl = 'https://tomata.mobiaura.com';

  /// 意见反馈：POST，body 为 AES 加密后的 { userId, email, title, content }。
  static const String feedback = '/api/tomata/6502852054/feed1x';
}
