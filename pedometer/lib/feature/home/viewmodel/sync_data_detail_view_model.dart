import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/feature/home/model/health_sync_source_policy.dart';
import 'package:pedometer/feature/home/model/sync_data_detail_model.dart';
import 'package:pedometer/feature/home/views/sync_history_detail_page.dart';
import 'package:pedometer/feature/home/views/sync_history_list_page.dart';
import 'package:pedometer/feature/home/views/sync_source_detail_page.dart';

/// Health 同步数据详情页 view model。
class SyncDataDetailViewModel extends GetxController implements IBaseViewModel {
  SyncDataDetailViewModel({
    SyncDataDetailData initialData = SyncDataDetailData.mock,
    TargetPlatform? platform,
  }) : platform = platform ?? defaultTargetPlatform,
       data = initialData.obs;

  final TargetPlatform platform;
  final Rx<SyncDataDetailData> data;

  List<SyncDataSource> get platformSources {
    final allowedTitles = HealthSyncSourcePolicy.sourcesFor(
      platform,
    ).map(HealthSyncSourcePolicy.titleFor).toSet();
    final filtered = data.value.sources
        .where((source) => allowedTitles.contains(source.title))
        .toList();
    return filtered.isEmpty ? data.value.sources : filtered;
  }

  @override
  void init() {}

  @override
  void unInit() {}

  @override
  void onClose() {
    unInit();
    super.onClose();
  }

  void useData(SyncDataDetailData nextData) {
    if (identical(data.value, nextData)) return;
    data.value = nextData;
  }

  void openSource(SyncDataSource source) {
    Get.toNamed(SyncSourceDetailPage.routeName, arguments: source);
  }

  void openHistory(SyncHistoryRecord record) {
    Get.toNamed(SyncHistoryDetailPage.routeName, arguments: record);
  }

  void openAllHistory() {
    Get.toNamed(SyncHistoryListPage.routeName);
  }
}
