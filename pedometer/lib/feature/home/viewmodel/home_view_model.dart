import 'package:get/get.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/feature/home/model/health_repository.dart';
import 'package:pedometer/feature/home/model/home_model.dart';

/// 首页 view model
class HomeViewModel extends GetxController implements IBaseViewModel {
  final HomeVo vo = HomeVo();
  final HealthRepository repository;

  HomeViewModel({HealthRepository? repository})
    : repository = repository ?? HealthRepository.defaultRepository();

  Rx<StepData> get step => vo.step;
  RxList<KpiItem> get kpis => vo.kpis;
  RxList<TrendPoint> get trend => vo.trend;
  RxList<AnalysisData> get analyses => vo.analyses;

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
    vo.step.value = snapshot.step;
    vo.kpis.assignAll(snapshot.kpis);
    vo.trend.assignAll(snapshot.trend);
    vo.analyses.assignAll(snapshot.analyses);
  }
}

/// 首页状态对象
class HomeVo {
  final Rx<StepData> step = const StepData(steps: 0, goal: 6000).obs;
  final RxList<KpiItem> kpis = <KpiItem>[].obs;
  final RxList<TrendPoint> trend = <TrendPoint>[].obs;
  final RxList<AnalysisData> analyses = <AnalysisData>[].obs;
}
