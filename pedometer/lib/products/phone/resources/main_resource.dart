import 'package:flutter/material.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/resource_loader.dart';

/// 主页（Tab 宿主）静态资源
class MainResource {
  MainResource._();

  static Color get background => ResourceLoader.color(
    'phone',
    'main_bg',
    fallbackModule: 'common',
    fallback: AppColors.bgPrimary,
  );

  static String get tabHome =>
      ResourceLoader.string('phone', 'tab_home', fallback: 'Home');
  static String get tabSport =>
      ResourceLoader.string('phone', 'tab_sport', fallback: 'Workout');
  static String get tabMine =>
      ResourceLoader.string('phone', 'tab_mine', fallback: 'Me');
}

/// 主页路由定义
class PhoneRouteTable {
  PhoneRouteTable._();

  static const String pathMain = '/main';
}
