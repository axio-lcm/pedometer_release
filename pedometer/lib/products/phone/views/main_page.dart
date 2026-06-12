import 'package:flutter/material.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/feature/home/views/home_page.dart';
import 'package:pedometer/feature/workout/views/workout_page.dart';
import 'package:pedometer/products/phone/components/glass_bottom_nav_bar.dart';
import 'package:pedometer/products/phone/resources/main_resource.dart';

/// 主页容器：底部三栏胶囊切换（首页 + 运动占位 + 我的占位）。
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
        children: [
          const HomePage(),
          const WorkoutPage(),
          _Placeholder(label: MainResource.tabMine),
        ],
      ),
      bottomNavigationBar: GlassBottomNavBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

/// "敬请期待"占位页（对齐 chat 占位做法）。
class _Placeholder extends StatelessWidget {
  final String label;
  const _Placeholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Center(
        child: Text(
          AppStrings.comingSoon(label),
          style: TextStyle(color: AppColors.textTertiary, fontSize: 15),
        ),
      ),
    );
  }
}
