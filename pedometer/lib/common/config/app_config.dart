/// 应用级常量配置。
///
/// 网络相关常量（baseUrl / 反馈接口 / AES 密钥 / sct）与 al_led_banner 保持一致，
/// 以复用同一套后端接口；bundleId 为本应用自身的包名。
abstract final class Constants {
  static const String appName = 'Pedometer';

  /// 后端识别用的数字 App Store ID（已在 al.asmyapp.com 白名单注册）。
  /// 作为请求头 `appId` 发送，服务端据此校验来源 app。
  static const String appleId = '6779515132';

  /// 请求参数 AES-256-CBC 加密密钥与偏移量（与服务端约定）。
  static const String aesKey = 'alhNenJDsXYyQUVOxwGB4Sg8cKUdC7sq';
  static const String aesIV = 'UgyIR0mHd2fYYZHe';
  static const String sct = 'FBwFFqartUL0wTQi';
}

/// 后端接口地址。
abstract final class APIs {
  static const String baseUrl = 'https://al.asmyapp.com';

  /// ASA 归因注册：POST，body 为 AES 加密后的归因与设备信息。
  static const String attributionRegister = '/api/alh/${Constants.appleId}/reg';

  /// 首订上报：POST，body 为 AES 加密后的订阅交易信息。
  static const String firstSubscription = '/api/alh/${Constants.appleId}/sub';

  /// 意见反馈：POST，body 为 AES 加密后的 { userId, email, title, content }。
  static const String feedback = '/api/alh/feedback';
}
