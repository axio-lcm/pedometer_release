import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/feature/home/model/health_repository.dart';
import 'package:pedometer/feature/home/viewmodel/home_view_model.dart';

void main() {
  setUp(() {
    // analyses 用到 AppColors → 需先装载（空表即可走 fallback）
    ResourceLoader.loadForTest(colors: {'common': {}}, strings: {'common': {}});
  });

  test('init seeds demo data matching the reference screen', () {
    final vm = HomeViewModel();
    vm.init();

    expect(vm.step.value.steps, 5276);
    expect(vm.step.value.percent, 88);
    expect(vm.kpis.length, 3);
    expect(vm.kpis[1].value, '293');
    expect(vm.trend.length, 7);
    expect(vm.trend.last.label, 'TUE');
    expect(vm.trend.last.highlight, isTrue);
    expect(vm.analyses.length, 2);
    expect(vm.analyses.first.samples.length, 7);
  });

  test('init reads dashboard data from the health repository', () {
    final vm = HomeViewModel(
      repository: HealthRepository(
        membershipService: const FixedMembershipService(false),
        mockDataSource: const MockHealthDataSource(),
        realDataSource: const MockHealthDataSource(),
      ),
    );
    vm.init();

    expect(vm.step.value.steps, 5276);
    expect(vm.kpis.map((item) => item.title), ['距离', '卡路里', '活动时间']);
    expect(vm.trend.last.highlight, isTrue);
  });
}
