import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/feature/mine/model/mine_model.dart';
import 'package:pedometer/feature/mine/resources/mine_resource.dart';

/// 我的页 view model：个人数据与入口点击意图。
class MineViewModel extends GetxController implements IBaseViewModel {
  MineViewModel({MinePageData initialData = MinePageData.mock})
    : data = initialData.obs;

  final Rx<MinePageData> data;

  @override
  void init() {}

  @override
  void unInit() {}

  @override
  void onClose() {
    unInit();
    super.onClose();
  }

  void useData(MinePageData nextData) {
    if (identical(data.value, nextData)) return;
    data.value = nextData;
  }

  // TODO: 接入其余入口真实跳转（主题 / 语言 / 协议等）。
  void openEntry(MineEntry entry, Rect origin) {
    if (entry.title == MineText.shareApp) {
      shareApp(origin: origin);
      return;
    }
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
          text: MineResource.shareAppContent,
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
