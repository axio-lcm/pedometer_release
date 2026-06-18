import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/feature/home/model/health_repository.dart';
import 'package:pedometer/feature/home/model/health_sync_models.dart';
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

  /// 连接状态变更计数，用于驱动 [platformSources] 在保存设置后刷新展示。
  final _connectionRevision = 0.obs;

  List<SyncDataSource> get platformSources {
    // 读取以建立 Obx 依赖：连接状态变化时重新计算来源状态文案。
    _connectionRevision.value;
    final allowedTitles = HealthSyncSourcePolicy.sourcesFor(
      platform,
    ).map(HealthSyncSourcePolicy.titleFor).toSet();
    final filtered = data.value.sources
        .where((source) => allowedTitles.contains(source.title))
        .toList();
    final list = filtered.isEmpty ? data.value.sources : filtered;
    return [
      for (final source in list) source.copyWith(status: _statusFor(source)),
    ];
  }

  String _statusFor(SyncDataSource source) {
    final healthSource = HealthSyncSourcePolicy.sourceForTitle(source.title);
    if (healthSource == null) return source.status;
    return switch (HealthSyncRuntime.connectionStatusOf(healthSource)) {
      HealthAuthStatus.authorized => '已连接',
      HealthAuthStatus.denied => '未连接',
      HealthAuthStatus.unavailable => '设备不可用',
      HealthAuthStatus.unsupported => '不支持',
      HealthAuthStatus.unknown => '未连接',
    };
  }

  @override
  void onInit() {
    super.onInit();
    HealthSyncRuntime.connectionRevision.addListener(_onConnectionChanged);
  }

  void _onConnectionChanged() => _connectionRevision.value++;

  @override
  void init() {}

  @override
  void unInit() {
    HealthSyncRuntime.connectionRevision.removeListener(_onConnectionChanged);
  }

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
