import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/feature/home/views/home_page.dart';
import 'package:pedometer/feature/mine/views/mine_page.dart';
import 'package:pedometer/feature/workout/views/workout_page.dart';
import 'package:pedometer/products/phone/components/glass_bottom_nav_bar.dart';
import 'package:pedometer/products/phone/resources/main_resource.dart';
import 'package:pedometer/products/phone/viewmodel/main_view_model.dart';

/// 主页容器：底部三栏胶囊切换（首页 + 运动 + 我的）。
class MainPage extends GetView<MainViewModel> {
  static const String routeName = PhoneRouteTable.pathMain;
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: MainResource.background,
        extendBody: true,
        body: IndexedStack(
          index: controller.currentIndex.value,
          children: const [HomePage(), WorkoutPage(), MinePage()],
        ),
        bottomNavigationBar: GlassBottomNavBar(
          currentIndex: controller.currentIndex.value,
          onTap: controller.selectTab,
        ),
      ),
    );
  }
}
