import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 屏幕适配基准：iPhone X / 375x812 设计稿。
class AppScreenDesign {
  AppScreenDesign._();

  static const Size size = Size(375, 812);
}

/// 全局屏幕适配包装，统一收口 flutter_screenutil 初始化。
class AppScreenAdapter extends StatelessWidget {
  final WidgetBuilder builder;

  const AppScreenAdapter({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: AppScreenDesign.size,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => builder(context),
    );
  }
}
