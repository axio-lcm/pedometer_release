import 'package:get/get.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/feature/home/model/sync_data_detail_model.dart';

/// 单条同步历史详情页 view model。
class SyncHistoryDetailViewModel extends GetxController
    implements IBaseViewModel {
  SyncHistoryDetailViewModel({
    SyncHistoryDetailData initialData = SyncHistoryDetailData.mock,
  }) : data = initialData.obs;

  final Rx<SyncHistoryDetailData> data;

  @override
  void init() {}

  @override
  void unInit() {}

  @override
  void onClose() {
    unInit();
    super.onClose();
  }

  void useData(SyncHistoryDetailData nextData) {
    if (identical(data.value, nextData)) return;
    data.value = nextData;
  }
}
