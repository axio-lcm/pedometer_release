import 'package:flutter/material.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/products/init/app.dart';

/// 应用冷启动初始化（main 入口）。
class AppStartup {
  AppStartup._();

  static bool _bootstrapped = false;

  static Future<void> run() async {
    await bootstrap();
    runApp(const PedometerApp());
  }

  static Future<void> bootstrap() async {
    if (_bootstrapped) return;
    WidgetsFlutterBinding.ensureInitialized();
    await ResourceLoader.init();
    _bootstrapped = true;
  }
}
