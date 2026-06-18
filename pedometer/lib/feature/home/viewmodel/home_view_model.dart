import 'package:get/get.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/feature/home/model/health_repository.dart';
import 'package:pedometer/feature/home/model/home_model.dart';
import 'package:pedometer/feature/home/model/sport_detail_model.dart';

/// 首页 view model
class HomeViewModel extends GetxController implements IBaseViewModel {
  final HomeVo vo = HomeVo();
  final HealthRepository repository;

  HomeViewModel({HealthRepository? repository})
    : repository = repository ?? HealthRepository.defaultRepository();

  RxList<TrendPoint> get trend => vo.trend;
  RxList<AnalysisData> get analyses => vo.analyses;
  Rx<SportPeriodData> get dayOverview => vo.dayOverview;

  @override
  void onInit() {
    super.onInit();
    HealthSyncRuntime.revision.addListener(_loadHealthData);
    init();
  }

  @override
  void init() {
    _loadHealthData();
  }

  @override
  void unInit() {}

  @override
  void onClose() {
    HealthSyncRuntime.revision.removeListener(_loadHealthData);
    unInit();
    super.onClose();
  }

  void _loadHealthData() {
    final snapshot = repository.homeSnapshot();
    vo.trend.assignAll(snapshot.trend);
    vo.analyses.assignAll(snapshot.analyses);
    vo.dayOverview.value = repository.sportPeriodData(SportPeriod.day);
  }
}

/// 首页状态对象
class HomeVo {
  final RxList<TrendPoint> trend = <TrendPoint>[].obs;
  final RxList<AnalysisData> analyses = <AnalysisData>[].obs;
  final Rx<SportPeriodData> dayOverview = SportDetailFixtures.day.obs;
}
