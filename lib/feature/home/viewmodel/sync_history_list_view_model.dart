import 'package:get/get.dart';
import 'package:pedometer/common/config/localized_text.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/common/storage/language_service.dart';
import 'package:pedometer/feature/home/model/health_repository.dart';
import 'package:pedometer/feature/home/model/sync_data_detail_model.dart';
import 'package:pedometer/feature/home/views/sync_history_detail_page.dart';

/// 同步历史列表页 view model。
class SyncHistoryListViewModel extends GetxController
    implements IBaseViewModel {
  SyncHistoryListViewModel()
    : data = const SyncHistoryListData(records: []).obs;

  final Rx<SyncHistoryListData> data;
  Worker? _languageWorker;

  @override
  void onInit() {
    super.onInit();
    HealthSyncHistory.revision.addListener(_load);
    if (Get.isRegistered<LanguageService>()) {
      _languageWorker = ever<int>(
        Get.find<LanguageService>().localeRevision,
        (_) => _load(),
      );
    }
    init();
  }

  @override
  void init() {
    _load();
  }

  @override
  void unInit() {
    HealthSyncHistory.revision.removeListener(_load);
    _languageWorker?.dispose();
  }

  @override
  void onClose() {
    unInit();
    super.onClose();
  }

  void openRecord(SyncHistoryRecord record) {
    Get.toNamed(SyncHistoryDetailPage.routeName, arguments: record);
  }

  void _load() {
    data.value = SyncHistoryListData(
      records: [
        for (final entry in HealthSyncHistory.entries)
          SyncHistoryRecord(
            id: entry.id,
            time: _timeText(entry.time),
            mode: _localizedMode(entry.mode),
            result: lt(
              'Synced ${entry.itemCount} items',
              '同步 ${entry.itemCount} 项数据',
            ),
          ),
      ],
    );
  }

  String _timeText(DateTime date) {
    final now = DateTime.now();
    final prefix =
        date.year == now.year && date.month == now.month && date.day == now.day
        ? lt('Today', '今天')
        : '${date.month}/${date.day}';
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$prefix $hour:$minute';
  }

  String _localizedMode(String mode) {
    if (mode == '手动同步' || mode == 'Manual Sync') {
      return lt('Manual Sync', '手动同步');
    }
    if (mode == '自动同步' || mode == 'Auto Sync') {
      return lt('Auto Sync', '自动同步');
    }
    return mode;
  }
}
