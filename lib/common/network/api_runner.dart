import 'package:pedometer/common/config/localized_text.dart';
import 'package:pedometer/common/network/api_exception.dart';
import 'package:pedometer/common/network/api_feedback.dart';

/// 统一执行接口动作：捕获异常并按需提示，返回 null 表示失败。
Future<T?> runApi<T>(
  Future<T> Function() action, {
  bool showError = true,
  String? fallback,
}) async {
  try {
    return await action();
  } on ApiException catch (e) {
    if (showError) ApiFeedback.error(e.message);
    return null;
  } catch (_) {
    if (showError) {
      ApiFeedback.error(fallback ?? lt('Operation failed', '操作失败'));
    }
    return null;
  }
}

/// [runApi] 的 bool 便捷封装：成功返回 true，否则 false。
Future<bool> runApiBool(
  Future<bool> Function() action, {
  bool showError = true,
  String? fallback,
}) async {
  final result = await runApi<bool>(
    action,
    showError: showError,
    fallback: fallback,
  );
  return result == true;
}
