/// 公共请求 Header 数据模型。
class HeaderData {
  /// 用户 ID：uuid 生成并持久化。
  final String userId;

  /// 设备类型：iOS / android。
  final String deviceType;

  /// 设备型号：iPhone / iPad 等。
  final String deviceModel;

  /// 设备系统版本：iOS 26 / Android 18。
  final String deviceOSVersion;

  /// 屏幕宽高：1080x1920。
  final String screenWH;

  /// 系统语言地区：en_US / zh_CN。
  final String sysLocale;

  /// 应用语言：en / zh。
  final String appLangCode;

  /// 客户端公网 IP。
  final String cip;

  /// 网络类型：WIFI / MOBILE / ETHERNET / VPN / BLUETOOTH / NONE。
  final String netType;

  /// 应用 ID（包名）。
  final String appId;

  /// 应用版本：1.0.0。
  final String appVersion;

  /// SCT 密钥。
  final String sct;

  /// 客户端公网 IP，同时放入 x-forwarded-for。
  final String xForwardedFor;

  const HeaderData({
    required this.userId,
    required this.deviceType,
    required this.deviceModel,
    required this.deviceOSVersion,
    required this.screenWH,
    required this.sysLocale,
    required this.appLangCode,
    required this.cip,
    required this.netType,
    required this.appId,
    required this.appVersion,
    required this.sct,
    required this.xForwardedFor,
  });

  /// 实际请求 Header（不含 sct，sct 由调用方单独附加）。
  Map<String, String> toApiToolMap() {
    return {
      'userId': userId,
      'deviceType': deviceType,
      'deviceModel': deviceModel,
      'deviceOSVersion': deviceOSVersion,
      'screenWH': screenWH,
      'sysLocale': sysLocale,
      'appLangCode': appLangCode,
      'cip': cip,
      'netType': netType,
      'appId': appId,
      'appVersion': appVersion,
      'xForwardedFor': xForwardedFor,
    };
  }
}
