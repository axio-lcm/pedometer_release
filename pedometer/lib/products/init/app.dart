import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_screen.dart';
import 'package:pedometer/common/config/app_theme.dart';
import 'package:pedometer/common/routers/app_pages.dart';

/// 根 Widget：深色主题 + 路由 + 国际化。
class PedometerApp extends StatelessWidget {
  const PedometerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreenAdapter(
      builder: (context) => GetMaterialApp(
        navigatorKey: Get.key,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
        defaultTransition: Transition.rightToLeft,
        transitionDuration: const Duration(milliseconds: 180),
        initialRoute: AppPages.initial,
        getPages: AppPages.pages,
        unknownRoute: AppPages.unknownRoute,
      ),
    );
  }
}
