import 'package:get/get.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/common/storage/language_service.dart';
import 'package:pedometer/feature/home/model/health_repository.dart';
import 'package:pedometer/feature/home/model/sport_detail_model.dart';

/// 二级运动详情页 view model：日 / 周 / 月三态。
class SportDetailViewModel extends GetxController implements IBaseViewModel {
  final SportDetailVo vo = SportDetailVo();
  final HealthRepository repository;
  Worker? _languageWorker;

  SportDetailViewModel({HealthRepository? repository})
    : repository = repository ?? HealthRepository.defaultRepository();

  Rx<SportPeriod> get period => vo.period;
  Rx<SportPeriodData> get data => vo.data;
  RxInt get weekOffset => vo.weekOffset;
  RxInt get monthOffset => vo.monthOffset;

  bool get isWeek => vo.period.value == SportPeriod.week;

  /// 周视图「下一周」仅在已偏移到过去时可用（不能查看未来）。
  bool get titleNextEnabled => isWeek && vo.weekOffset.value < 0;

  /// 月切换为静默更新，避免标题动画。
  bool get animateTitleChanges => vo.period.value != SportPeriod.month;

  /// 当前周期的标题：周/月随偏移实时变化，日为当天日期。
  String get title => switch (vo.period.value) {
    SportPeriod.week => SportDetailFixtures.weekTitle(
      offset: vo.weekOffset.value,
    ),
    SportPeriod.month => SportDetailFixtures.monthTitle(
      offset: vo.monthOffset.value,
    ),
    SportPeriod.day => vo.data.value.dateTitle,
  };

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is SportPeriod) {
      vo.period.value = args;
    }
    HealthSyncRuntime.revision.addListener(_load);
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
  void unInit() {}

  @override
  void onClose() {
    HealthSyncRuntime.revision.removeListener(_load);
    _languageWorker?.dispose();
    unInit();
    super.onClose();
  }

  /// 切换周期，并重置周/月偏移到当前。
  void changePeriod(SportPeriod period) {
    vo.period.value = period;
    vo.weekOffset.value = 0;
    vo.monthOffset.value = 0;
    _load();
  }

  /// 上一周。
  void prevWeek() {
    vo.weekOffset.value -= 1;
    _load();
  }

  /// 下一周（不能超过本周）。
  void nextWeek() {
    if (vo.weekOffset.value < 0) {
      vo.weekOffset.value += 1;
      _load();
    }
  }

  /// 月视图切月。
  void changeMonth(int offset) {
    if (vo.monthOffset.value == offset) return;
    vo.monthOffset.value = offset;
    _load();
  }

  void _load() {
    vo.data.value = repository.sportPeriodData(
      vo.period.value,
      weekOffset: vo.weekOffset.value,
      monthOffset: vo.monthOffset.value,
    );
  }
}

/// 运动详情页状态对象。
class SportDetailVo {
  final Rx<SportPeriod> period = SportPeriod.day.obs;
  final RxInt weekOffset = 0.obs;
  final RxInt monthOffset = 0.obs;
  final Rx<SportPeriodData> data = SportDetailFixtures.day.obs;
}
