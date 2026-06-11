import 'package:flutter/material.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/resource_loader.dart';

/// 首页模块静态资源
class HomeResource {
  HomeResource._();

  static Color get background => ResourceLoader.color(
    'home',
    'home_bg',
    fallbackModule: 'common',
    fallback: AppColors.bgPrimary,
  );

  static String get entryOverview =>
      ResourceLoader.string('home', 'entry_overview', fallback: '运动总览');
  static String get entryHealthSync =>
      ResourceLoader.string('home', 'entry_health_sync', fallback: 'Health 同步');
  static String get todaySteps =>
      ResourceLoader.string('home', 'today_steps', fallback: '今日步数');
  static String get goalSuffix =>
      ResourceLoader.string('home', 'goal_suffix', fallback: '步');
  static String get achieved =>
      ResourceLoader.string('home', 'achieved', fallback: '达成');
  static String get trend =>
      ResourceLoader.string('home', 'trend', fallback: '趋势');
}

/// 首页模块路由定义
class HomeRouteTable {
  HomeRouteTable._();

  static const String pathHome = '/home';
  static const String pathSportDetail = '/home/sport-detail';
}
