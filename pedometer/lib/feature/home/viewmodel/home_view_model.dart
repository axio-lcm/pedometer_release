import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/feature/home/model/home_model.dart';

/// 首页 view model
class HomeViewModel extends GetxController implements IBaseViewModel {
  final HomeVo vo = HomeVo();

  Rx<StepData> get step => vo.step;
  RxList<KpiItem> get kpis => vo.kpis;
  RxList<TrendPoint> get trend => vo.trend;
  RxList<AnalysisData> get analyses => vo.analyses;

  @override
  void onInit() {
    super.onInit();
    init();
  }

  @override
  void onClose() {
    unInit();
    super.onClose();
  }

  @override
  void init() {
    _seedDemoData();
  }

  @override
  void unInit() {}

  /// 注入首屏演示数据（对齐截图）。后续可替换为传感器 / Health 数据源。
  void _seedDemoData() {
    vo.step.value = const StepData(steps: 5276, goal: 6000);

    vo.kpis.assignAll(const [
      KpiItem(
        icon: Icons.place_rounded,
        color: Color(0xFF7A3DFF),
        title: '距离',
        value: '1.6',
        unit: 'km',
      ),
      KpiItem(
        icon: Icons.local_fire_department_rounded,
        color: Color(0xFFFF9F12),
        title: '卡路里',
        value: '293',
        unit: 'kcal',
      ),
      KpiItem(
        icon: Icons.timer_rounded,
        color: Color(0xFF0CD9FF),
        title: '活动时间',
        value: '28',
        unit: 'min',
      ),
    ]);

    vo.trend.assignAll(const [
      TrendPoint(label: 'WED', value: 4500),
      TrendPoint(label: 'THU', value: 6600),
      TrendPoint(label: 'FRI', value: 4200),
      TrendPoint(label: 'SAT', value: 8000),
      TrendPoint(label: 'SUN', value: 6500),
      TrendPoint(label: 'MON', value: 4100),
      TrendPoint(label: 'TUE', value: 7200, highlight: true),
    ]);

    vo.analyses.assignAll([
      AnalysisData(
        title: '卡路里分析',
        value: '293',
        unit: 'kcal',
        delta: '较昨日 +12%',
        color: AppColors.accentOrange,
        samples: const [0.30, 0.45, 0.38, 0.60, 0.55, 0.78, 0.92],
      ),
      AnalysisData(
        title: '活动时间分析',
        value: '28',
        unit: 'min',
        delta: '较昨日 +8%',
        color: AppColors.accentCyan,
        samples: const [0.40, 0.35, 0.55, 0.50, 0.70, 0.66, 0.88],
      ),
    ]);
  }
}

/// 首页状态对象
class HomeVo {
  final Rx<StepData> step = const StepData(steps: 0, goal: 6000).obs;
  final RxList<KpiItem> kpis = <KpiItem>[].obs;
  final RxList<TrendPoint> trend = <TrendPoint>[].obs;
  final RxList<AnalysisData> analyses = <AnalysisData>[].obs;
}
