import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class AppTrackingTransparencyService {
  AppTrackingTransparencyService._();

  static bool _requestedThisSession = false;

  static Future<PermissionStatus?> requestAuthorizationIfNeeded() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return null;
    if (_requestedThisSession) return null;
    _requestedThisSession = true;

    final status = await Permission.appTrackingTransparency.status;
    if (!status.isDenied) return status;
    try {
      return await Permission.appTrackingTransparency.request();
    } catch (_) {
      return null;
    }
  }
}
