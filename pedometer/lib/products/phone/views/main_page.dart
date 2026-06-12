import 'package:flutter/material.dart';
import 'package:pedometer/feature/home/views/home_page.dart';
import 'package:pedometer/feature/mine/views/mine_page.dart';
import 'package:pedometer/feature/workout/views/workout_page.dart';
import 'package:pedometer/products/phone/components/glass_bottom_nav_bar.dart';
import 'package:pedometer/products/phone/resources/main_resource.dart';

/// 主页容器：底部三栏胶囊切换（首页 + 运动 + 我的）。
class MainPage extends StatefulWidget {
  static const String routeName = PhoneRouteTable.pathMain;
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MainResource.background,
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: const [HomePage(), WorkoutPage(), MinePage()],
      ),
      bottomNavigationBar: GlassBottomNavBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
