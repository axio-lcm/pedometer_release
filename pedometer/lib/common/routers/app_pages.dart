import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
  ];

  static final GetPage unknownRoute = GetPage(
    name: '/404',
    page: () => const Scaffold(body: Center(child: Text('页面不存在'))),
  );
}
