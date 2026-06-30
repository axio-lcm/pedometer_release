import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

enum PhotoLibraryImportAuth { authorized, denied, deniedForever }

class PhotoLibraryPermissionService {
  PhotoLibraryPermissionService._();

  static Future<PhotoLibraryImportAuth> ensureAuthorizedForImport() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return PhotoLibraryImportAuth.authorized;
    }

    try {
      final status = await Permission.photos.status;
      if (_canImport(status)) return PhotoLibraryImportAuth.authorized;
      if (_requiresSettings(status)) {
        return PhotoLibraryImportAuth.deniedForever;
      }

      final requested = await Permission.photos.request();
      if (_canImport(requested)) return PhotoLibraryImportAuth.authorized;
      if (_requiresSettings(requested)) {
        return PhotoLibraryImportAuth.deniedForever;
      }
      return PhotoLibraryImportAuth.denied;
    } catch (_) {
      return PhotoLibraryImportAuth.denied;
    }
  }

  static Future<bool> openSettings() => openAppSettings();

  static bool _canImport(PermissionStatus status) {
    return status.isGranted || status.isLimited;
  }

  static bool _requiresSettings(PermissionStatus status) {
    return status.isPermanentlyDenied || status.isRestricted;
  }
}
