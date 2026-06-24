import 'package:pedometer/common/network/api_exception.dart';

/// 接口结果断言：失败时抛出可展示的 [ApiException]。
abstract final class ApiGuard {
  static void ensureSuccess(bool success, String message) {
    if (!success) throw ApiException(message);
  }

  /// 校验业务响应体 { code, message }，code 非 0 视为失败。
  static void ensureMapSuccess(Map<String, dynamic>? body, String message) {
    if (body == null) throw ApiException(message);
    final code = body['code'];
    final ok = code == 0 || code == '0';
    if (!ok) {
      final tip = (body['message'] ?? body['msg'] ?? '').toString();
      throw ApiException(tip.isNotEmpty ? tip : message);
    }
  }
}
