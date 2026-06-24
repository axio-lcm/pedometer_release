import 'package:dio/dio.dart';

/// Dio 实例工厂。
abstract final class DioFactory {
  /// 公网 IP 查询用的轻量 Dio（短超时，独立于业务 Dio）。
  static Dio createPublicIpDio() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
  }
}
