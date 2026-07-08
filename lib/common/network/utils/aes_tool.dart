import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:pedometer/common/config/app_config.dart';

/// 请求参数 AES-256-CBC 加密工具（与服务端约定，须与 al_led_banner 一致）。
abstract final class AesTool {
  static const String kSctToken = Constants.sct;

  /// 加密为 base64 字符串；入参为空或失败时返回空串。
  static String encrypt(String plainText) {
    if (plainText.isEmpty) return plainText;

    try {
      final key = enc.Key.fromUtf8(Constants.aesKey);
      final iv = enc.IV.fromUtf8(Constants.aesIV);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.encrypt(plainText, iv: iv).base64;
    } catch (e, st) {
      debugPrint('[AesTool] encrypt failed: $e\n$st');
      return '';
    }
  }
}
