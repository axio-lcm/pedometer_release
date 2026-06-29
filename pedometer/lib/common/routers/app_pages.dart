import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/localized_text.dart';
import 'package:pedometer/feature/legal/views/legal_web_page.dart';
import 'package:pedometer/feature/home/resources/home_resource.dart';
import 'package:pedometer/feature/home/views/sync_data_detail_page.dart';
import 'package:pedometer/feature/home/views/sync_source_detail_page.dart';
import 'package:pedometer/feature/home/views/sync_history_list_page.dart';
import 'package:pedometer/feature/home/views/sync_history_detail_page.dart';
import 'package:pedometer/feature/home/views/sport_detail_page.dart';
import 'package:pedometer/feature/home/viewmodel/sync_data_detail_view_model.dart';
import 'package:pedometer/feature/home/viewmodel/sync_history_detail_view_model.dart';
import 'package:pedometer/feature/home/viewmodel/sync_history_list_view_model.dart';
import 'package:pedometer/feature/home/viewmodel/sync_source_detail_view_model.dart';
import 'package:pedometer/feature/mine/viewmodel/edit_body_data_view_model.dart';
import 'package:pedometer/feature/mine/viewmodel/language_view_model.dart';
import 'package:pedometer/feature/mine/viewmodel/mine_view_model.dart';
import 'package:pedometer/feature/mine/viewmodel/suggestion_view_model.dart';
import 'package:pedometer/feature/mine/views/edit_body_data_page.dart';
import 'package:pedometer/feature/mine/views/language_page.dart';
import 'package:pedometer/feature/mine/views/suggestion_page.dart';
import 'package:pedometer/feature/subscription/service/subscription_service.dart';
import 'package:pedometer/feature/subscription/viewmodel/onboarding_view_model.dart';
import 'package:pedometer/feature/subscription/viewmodel/subscription_view_model.dart';
import 'package:pedometer/feature/subscription/views/onboarding_page.dart';
import 'package:pedometer/feature/subscription/views/subscription_page.dart';
import 'package:pedometer/feature/splash/viewmodel/startup_loading_view_model.dart';
import 'package:pedometer/feature/splash/views/startup_loading_page.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';
import 'package:pedometer/feature/workout/viewmodel/edit_sport_goal_view_model.dart';
import 'package:pedometer/feature/workout/viewmodel/exercise_result_view_model.dart';
import 'package:pedometer/feature/workout/viewmodel/workout_tracking_view_model.dart';
import 'package:pedometer/feature/workout/viewmodel/workout_view_model.dart';
import 'package:pedometer/feature/workout/views/achievement_badge_page.dart';
import 'package:pedometer/feature/workout/views/edit_sport_goal_page.dart';
import 'package:pedometer/feature/workout/views/exercise_result_page.dart';
import 'package:pedometer/feature/workout/views/workout_music_list_page.dart';
import 'package:pedometer/feature/workout/views/workout_route_history_page.dart';
import 'package:pedometer/feature/workout/views/workout_route_list_page.dart';
import 'package:pedometer/feature/workout/views/workout_tracking_page.dart';
import 'package:pedometer/feature/home/viewmodel/home_view_model.dart';
import 'package:pedometer/feature/home/viewmodel/sport_detail_view_model.dart';
import 'package:pedometer/products/phone/viewmodel/main_view_model.dart';
import 'package:pedometer/products/phone/views/main_page.dart';

/// 统一路由管理
class AppPages {
  AppPages._();

  /// 启动后的业务首屏：会员进首页；非会员进引导页。
  static String get postStartupRoute {
    final isVip =
        Get.isRegistered<SubscriptionService>() &&
        Get.find<SubscriptionService>().isVip.value;
    return isVip ? MainPage.routeName : OnboardingPage.routeName;
  }

  /// 首屏路由：展示启动加载进度条页，再进入业务首屏。
  static String get initial => StartupLoadingPage.routeName;

  static final List<GetPage> pages = [
    GetPage(
      name: StartupLoadingPage.routeName,
      page: () => const StartupLoadingPage(),
      transition: Transition.fadeIn,
      binding: BindingsBuilder(() {
        Get.lazyPut<StartupLoadingViewModel>(() => StartupLoadingViewModel());
      }),
    ),
    GetPage(
      name: OnboardingPage.routeName,
      page: () => const OnboardingPage(),
      transition: Transition.fadeIn,
      binding: BindingsBuilder(() {
        Get.lazyPut<OnboardingViewModel>(() => OnboardingViewModel());
      }),
    ),
    GetPage(
      name: SubscriptionPage.routeName,
      page: () => const SubscriptionPage(),
      transition: Transition.downToUp,
      binding: BindingsBuilder(() {
        Get.lazyPut<SubscriptionViewModel>(() => SubscriptionViewModel());
      }),
    ),
    GetPage(
      name: LegalWebPage.routeName,
      page: () => const LegalWebPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: MainPage.routeName,
      page: () => const MainPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<MainViewModel>(() => MainViewModel());
        Get.lazyPut<HomeViewModel>(() => HomeViewModel());
        Get.lazyPut<WorkoutViewModel>(() => WorkoutViewModel());
        Get.lazyPut<MineViewModel>(() => MineViewModel());
      }),
    ),
    GetPage(
      name: HomeRouteTable.pathSportDetail,
      page: () => const SportDetailPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SportDetailViewModel>(() => SportDetailViewModel());
      }),
    ),
    GetPage(
      name: HomeRouteTable.pathSyncDataDetail,
      page: () => const SyncDataDetailPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SyncDataDetailViewModel>(() => SyncDataDetailViewModel());
      }),
    ),
    GetPage(
      name: HomeRouteTable.pathSyncSourceDetail,
      page: () => const SyncSourceDetailPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SyncSourceDetailViewModel>(
          () => SyncSourceDetailViewModel(),
        );
      }),
    ),
    GetPage(
      name: HomeRouteTable.pathSyncHistoryList,
      page: () => const SyncHistoryListPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SyncHistoryListViewModel>(() => SyncHistoryListViewModel());
      }),
    ),
    GetPage(
      name: HomeRouteTable.pathSyncHistoryDetail,
      page: () => const SyncHistoryDetailPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SyncHistoryDetailViewModel>(
          () => SyncHistoryDetailViewModel(),
        );
      }),
    ),
    GetPage(
      name: WorkoutRouteTable.pathEditGoal,
      page: () => const EditSportGoalPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<EditSportGoalViewModel>(() => EditSportGoalViewModel());
      }),
    ),
    GetPage(
      name: WorkoutRouteTable.pathTracking,
      page: () => const WorkoutTrackingPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<WorkoutTrackingViewModel>(() => WorkoutTrackingViewModel());
      }),
    ),
    GetPage(
      name: WorkoutRouteTable.pathResult,
      page: () => const ExerciseResultPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ExerciseResultViewModel>(() => ExerciseResultViewModel());
      }),
    ),
    GetPage(
      name: WorkoutRouteTable.pathMusicList,
      page: () => const WorkoutMusicListPage(),
    ),
    GetPage(
      name: WorkoutRouteTable.pathRouteHistory,
      page: () => const WorkoutRouteListPage(),
    ),
    GetPage(
      name: WorkoutRouteTable.pathRouteHistoryDetail,
      page: () => const WorkoutRouteHistoryPage(),
    ),
    GetPage(
      name: WorkoutRouteTable.pathAchievement,
      page: () => const AchievementBadgePage(),
    ),
    GetPage(
      name: LanguagePage.routeName,
      page: () => const LanguagePage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<LanguageViewModel>(() => LanguageViewModel());
      }),
    ),
    GetPage(
      name: SuggestionPage.routeName,
      page: () => const SuggestionPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SuggestionViewModel>(() => SuggestionViewModel());
      }),
    ),
    GetPage(
      name: EditBodyDataPage.routeName,
      page: () => const EditBodyDataPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<EditBodyDataViewModel>(() => EditBodyDataViewModel());
      }),
    ),
  ];

  static final GetPage unknownRoute = GetPage(
    name: '/404',
    page: () =>
        Scaffold(body: Center(child: Text(lt('Page not found', '页面不存在')))),
  );
}
