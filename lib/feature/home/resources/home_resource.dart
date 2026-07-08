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

  static String get entryOverview => ResourceLoader.string(
    'home',
    'entry_overview',
    fallback: 'Activity Overview',
  );
  static String get entryHealthSync =>
      ResourceLoader.string('home', 'entry_health_sync', fallback: 'Health');
  static String get todaySteps =>
      ResourceLoader.string('home', 'today_steps', fallback: 'Today');
  static String get goalSuffix =>
      ResourceLoader.string('home', 'goal_suffix', fallback: 'steps');
  static String get achieved =>
      ResourceLoader.string('home', 'achieved', fallback: 'Achieved');
  static String get trend =>
      ResourceLoader.string('home', 'trend', fallback: 'Trend');
}

/// 首页模块路由定义
class HomeRouteTable {
  HomeRouteTable._();

  static const String pathHome = '/home';
  static const String pathSportDetail = '/home/sport-detail';
  static const String pathSyncDataDetail = '/home/sync-data-detail';
  static const String pathSyncSourceDetail = '/home/sync-source-detail';
  static const String pathSyncHistoryList = '/home/sync-history-list';
  static const String pathSyncHistoryDetail = '/home/sync-history-detail';
}
