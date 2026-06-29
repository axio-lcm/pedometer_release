import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pedometer/common/config/app_config.dart';
import 'package:pedometer/common/config/prefs_keys.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/common/storage/language_service.dart';
import 'package:pedometer/common/tools/app_market_launcher.dart';
import 'package:pedometer/feature/legal/legal_navigation.dart';
import 'package:pedometer/feature/mine/model/mine_model.dart';
import 'package:pedometer/feature/mine/resources/mine_resource.dart';
import 'package:pedometer/feature/mine/views/edit_body_data_page.dart';
import 'package:pedometer/feature/mine/views/language_page.dart';
import 'package:pedometer/feature/mine/views/suggestion_page.dart';

/// 我的页 view model：个人数据与入口点击意图。
class MineViewModel extends GetxController implements IBaseViewModel {
  MineViewModel({MinePageData? initialData})
    : data = (initialData ?? MinePageData.localized()).obs;

  final Rx<MinePageData> data;

  Worker? _languageWorker;

  @override
  void init() {
    refreshLocalizedData();
  }

  @override
  void unInit() {}

  @override
  void onInit() {
    super.onInit();
    init();
    // 切换语言后重建本地化数据，使设置入口/身体指标文案随之刷新。
    if (Get.isRegistered<LanguageService>()) {
      _languageWorker = ever<int>(
        Get.find<LanguageService>().localeRevision,
        (_) => refreshLocalizedData(),
      );
    }
  }

  @override
  void onClose() {
    _languageWorker?.dispose();
    unInit();
    super.onClose();
  }

  void useData(MinePageData nextData) {
    if (identical(data.value, nextData)) return;
    data.value = nextData;
  }

  void openEntry(MineEntry entry, Rect origin) {
    if (entry.title == MineResource.language ||
        entry.title == MineText.language) {
      Get.toNamed(LanguagePage.routeName);
      return;
    }
    if (entry.title == MineResource.shareApp ||
        entry.title == MineText.shareApp) {
      shareApp(origin: origin);
      return;
    }
    if (entry.title == MineResource.rateUs || entry.title == MineText.rateUs) {
      AppMarketLauncher.openAppStoreReview();
      return;
    }
    if (entry.title == MineResource.suggestion ||
        entry.title == MineText.suggestion) {
      Get.toNamed(SuggestionPage.routeName);
      return;
    }
    if (entry.title == MineResource.userAgreement ||
        entry.title == MineText.userAgreement) {
      LegalNavigation.openUserAgreement<void>(
        title: MineResource.userAgreement,
      );
      return;
    }
    if (entry.title == MineResource.privacyPolicy ||
        entry.title == MineText.privacyPolicy) {
      LegalNavigation.openPrivacyPolicy<void>(
        title: MineResource.privacyPolicy,
      );
      return;
    }
  }

  Future<void> _loadBodyData() async {
    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getDouble(PrefsKeys.bodyHeight) ?? 175.0;
    final w = prefs.getDouble(PrefsKeys.bodyWeight) ?? 68.0;
    final a = prefs.getInt(PrefsKeys.bodyAge) ?? 28;
    data.value = MinePageData.localized(height: h, weight: w, age: a);
  }

  void refreshLocalizedData() {
    _loadBodyData();
  }

  void openEditBodyData() {
    Get.toNamed(EditBodyDataPage.routeName);
  }

  /// 调起系统分享面板，分享应用。
  ///
  /// [origin] 为触发分享的控件在屏幕上的矩形，iOS（含 iPad）以此作为分享面板
  /// 的弹出锚点；为空或无效时回退到屏幕左上角的一个小矩形，避免原生层报错。
  Future<void> shareApp({Rect? origin}) async {
    final anchor = (origin == null || origin.isEmpty)
        ? const Rect.fromLTWH(0, 0, 1, 1)
        : origin;
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          text: '${MineResource.shareAppContent}\n\n${Constants.appStoreUrl}',
          subject: MineResource.shareAppSubject,
          sharePositionOrigin: anchor,
        ),
      );
      debugPrint('[shareApp] status=${result.status}, raw=${result.raw}');
    } catch (e, s) {
      debugPrint('[shareApp] failed: $e\n$s');
    }
  }
}
