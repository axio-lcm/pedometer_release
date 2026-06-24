import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pedometer/common/config/app_config.dart';
import 'package:pedometer/common/network/models/api_response.dart';

/// 统一网络请求工具（移植自 al_led_banner）。
class DioRequest {
  final Dio _dio = Dio();

  DioRequest() {
    _dio
      ..options.baseUrl = APIs.baseUrl
      ..options.connectTimeout = _getConnectTimeout()
      ..options.receiveTimeout = _getReceiveTimeout()
      ..options.sendTimeout = _getSendTimeout()
      ..options.responseType = ResponseType.json;

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (kDebugMode) {
            debugPrint(
              '[DIO][REQUEST] ${options.method} ${options.uri}\n'
              'headers: ${options.headers}\n'
              'query: ${options.queryParameters}\n'
              'data: ${options.data}',
            );
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
              '[DIO][RESPONSE] ${response.statusCode} '
              '${response.requestOptions.uri}\n'
              'data: ${response.data}',
            );
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            debugPrint(
              '[DIO][ERROR] type=${error.type} '
              'url=${error.requestOptions.uri} message=${error.message}\n'
              'response: ${error.response?.statusCode} ${error.response?.data}',
            );
          }
          handler.next(error);
        },
      ),
    );
  }

  Duration _getConnectTimeout() => _timeoutForRegion(slow: 90, normal: 60);

  Duration _getReceiveTimeout() => _timeoutForRegion(slow: 120, normal: 60);

  Duration _getSendTimeout() => _timeoutForRegion(slow: 90, normal: 60);

  /// 部分地区网络较慢，适当放宽超时。
  Duration _timeoutForRegion({required int slow, required int normal}) {
    final region = PlatformDispatcher.instance.locale.countryCode;
    switch (region) {
      case 'ID':
      case 'IN':
      case 'BR':
        return Duration(seconds: slow);
      default:
        return Duration(seconds: normal);
    }
  }

  Future<dynamic> get(
    String url, {
    Map<String, dynamic>? params,
    Map<String, dynamic>? headers,
  }) {
    return _handleResponse(
      _dio.get(url, queryParameters: params, options: Options(headers: headers)),
    );
  }

  Future<dynamic> post(
    String url, {
    dynamic data,
    Map<String, dynamic>? headers,
  }) {
    return _handleResponse(
      _dio.post(url, data: data, options: Options(headers: headers)),
    );
  }

  /// POST JSON：显式传 Header，body 使用 jsonEncode；返回原始响应 Map。
  Future<Map<String, dynamic>?> postJson(
    String url, {
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.post(
        url,
        data: jsonEncode(parameters),
        options: Options(
          headers: headers ?? const {},
          responseType: ResponseType.json,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data == null) return null;
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DIO][postJson] error: $e');
      }
    }
    return null;
  }

  Future<dynamic> _handleResponse(Future<Response<dynamic>> task) async {
    final response = await task;
    final rawData = response.data;

    if (rawData is! Map) {
      return rawData;
    }

    final apiResponse = ApiResponse<dynamic>.fromJson(
      Map<String, dynamic>.from(rawData),
    );

    if (apiResponse.isSuccess) {
      return apiResponse.data;
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: apiResponse.message ?? 'Request failed',
    );
  }
}

/// 全局唯一业务请求实例。
final DioRequest dioRequest = DioRequest();
