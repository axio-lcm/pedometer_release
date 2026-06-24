/// 统一业务响应结构：{ code, data, message }。
class ApiResponse<T> {
  const ApiResponse({required this.code, this.data, this.message});

  final dynamic code;
  final T? data;
  final String? message;

  bool get isSuccess =>
      code == NetworkConstants.successCode ||
      code == NetworkConstants.successCode.toString();

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic json)? dataParser,
  }) {
    final rawData = json['data'];
    return ApiResponse<T>(
      code: json['code'],
      data: dataParser != null && rawData != null
          ? dataParser(rawData)
          : rawData as T?,
      message: json['message']?.toString(),
    );
  }
}

abstract final class NetworkConstants {
  static const int successCode = 0;
}
