/// 业务接口异常：携带可直接展示给用户的提示文案。
class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
