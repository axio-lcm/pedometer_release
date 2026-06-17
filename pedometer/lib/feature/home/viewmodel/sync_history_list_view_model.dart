import 'package:get/get.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/feature/home/model/sync_data_detail_model.dart';
import 'package:pedometer/feature/home/views/sync_history_detail_page.dart';

/// 同步历史列表页 view model。
class SyncHistoryListViewModel extends GetxController
    implements IBaseViewModel {
  SyncHistoryListViewModel({
    SyncHistoryListData initialData = SyncHistoryListData.mock,
  }) : data = initialData.obs;

  final Rx<SyncHistoryListData> data;

  @override
  void init() {}

  @override
  void unInit() {}

  @override
  void onClose() {
    unInit();
    super.onClose();
  }

  void useData(SyncHistoryListData nextData) {
    if (identical(data.value, nextData)) return;
    data.value = nextData;
  }

  void openRecord(SyncHistoryRecord record) {
    Get.toNamed(SyncHistoryDetailPage.routeName, arguments: record);
  }
}
