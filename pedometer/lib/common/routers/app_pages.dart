import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/feature/home/resources/home_resource.dart';
import 'package:pedometer/feature/home/views/sync_data_detail_page.dart';
import 'package:pedometer/feature/home/views/sync_source_detail_page.dart';
import 'package:pedometer/feature/home/views/sync_history_list_page.dart';
import 'package:pedometer/feature/home/views/sync_history_detail_page.dart';
import 'package:pedometer/feature/home/views/sport_detail_page.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';
import 'package:pedometer/feature/workout/viewmodel/workout_tracking_controller.dart';
import 'package:pedometer/feature/workout/views/edit_sport_goal_page.dart';
import 'package:pedometer/feature/workout/views/exercise_result_page.dart';
import 'package:pedometer/feature/workout/views/workout_tracking_page.dart';
import 'package:pedometer/feature/home/viewmodel/home_view_model.dart';
import 'package:pedometer/products/phone/views/main_page.dart';

/// 统一路由管理
class AppPages {
  AppPages._();

  static const String initial = MainPage.routeName;

  static final List<GetPage> pages = [
    GetPage(
      name: MainPage.routeName,
      page: () => const MainPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<HomeViewModel>(() => HomeViewModel());
      }),
    ),
    GetPage(
      name: HomeRouteTable.pathSportDetail,
      page: () => const SportDetailPage(),
    ),
    GetPage(
      name: HomeRouteTable.pathSyncDataDetail,
      page: () => const SyncDataDetailPage(),
    ),
    GetPage(
      name: HomeRouteTable.pathSyncSourceDetail,
      page: () => const SyncSourceDetailPage(),
    ),
    GetPage(
      name: HomeRouteTable.pathSyncHistoryList,
      page: () => const SyncHistoryListPage(),
    ),
    GetPage(
      name: HomeRouteTable.pathSyncHistoryDetail,
      page: () => const SyncHistoryDetailPage(),
    ),
    GetPage(
      name: WorkoutRouteTable.pathEditGoal,
      page: () => const EditSportGoalPage(),
    ),
    GetPage(
      name: WorkoutRouteTable.pathTracking,
      page: () => const WorkoutTrackingPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<WorkoutTrackingController>(
          () => WorkoutTrackingController(),
        );
      }),
    ),
    GetPage(
      name: WorkoutRouteTable.pathResult,
      page: () => const ExerciseResultPage(),
    ),
  ];

  static final GetPage unknownRoute = GetPage(
    name: '/404',
    page: () => const Scaffold(body: Center(child: Text('页面不存在'))),
  );
}
