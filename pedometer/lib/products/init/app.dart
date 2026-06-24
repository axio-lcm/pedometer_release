import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_screen.dart';
import 'package:pedometer/common/config/app_theme.dart';
import 'package:pedometer/common/routers/app_pages.dart';
import 'package:pedometer/common/storage/language_service.dart';

/// 根 Widget：深色主题 + 路由 + 国际化。
class PedometerApp extends StatelessWidget {
  const PedometerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();
    return AppScreenAdapter(
      builder: (context) => Obx(
        () => GetMaterialApp(
          key: ValueKey(
            '${languageService.languageCode.value}-'
            '${languageService.localeRevision.value}',
          ),
          navigatorKey: Get.key,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          locale: languageService.locale,
          fallbackLocale: const Locale('en', 'US'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', 'US'), Locale('zh', 'CN')],
          defaultTransition: Transition.rightToLeft,
          transitionDuration: const Duration(milliseconds: 180),
          initialRoute: AppPages.initial,
          getPages: AppPages.pages,
          unknownRoute: AppPages.unknownRoute,
        ),
      ),
    );
  }
}
