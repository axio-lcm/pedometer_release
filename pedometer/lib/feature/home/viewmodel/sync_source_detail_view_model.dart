import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/feature/home/model/health_repository.dart';
import 'package:pedometer/feature/home/model/health_sync_models.dart';
import 'package:pedometer/feature/home/model/health_sync_source_policy.dart';
import 'package:pedometer/feature/home/model/sync_data_detail_model.dart';

/// 单个健康数据来源详情页 view model：同步设置、授权状态与手动同步流程。
class SyncSourceDetailViewModel extends GetxController
    implements IBaseViewModel {
  SyncSourceDetailViewModel({
    HealthPluginSyncService? syncService,
    TargetPlatform? platform,
    SyncDataSource? initialSource,
  }) : service = syncService ?? HealthPluginSyncService(),
       platform = platform ?? defaultTargetPlatform,
       data = SyncSourceDetailData.forSource(
         initialSource ?? SyncDataDetailData.mock.sources.first,
       ).obs;

  static const _permissionTypes = [
    HealthSyncDataType.steps,
    HealthSyncDataType.distance,
    HealthSyncDataType.calories,
    HealthSyncDataType.activeMinutes,
  ];

  final HealthPluginSyncService service;
  final TargetPlatform platform;
  final Rx<SyncSourceDetailData> data;
  final selectedModeIndex = 0.obs;
  final manualSelections = <bool>[].obs;
  final syncing = false.obs;
  final syncMessage = RxnString();
  final syncSucceeded = false.obs;
  final permissionStatus = RxnString();

  bool get isManualSyncSelected {
    final options = data.value.modeOptions;
    if (options.isEmpty) return false;
    return options[selectedModeIndex.value].title == '手动同步';
  }

  List<ManualSyncSelectionItem> get manualItems {
    final items = data.value.manualItems;
    return [
      for (var i = 0; i < items.length; i++)
        ManualSyncSelectionItem(
          title: items[i].title,
          selected: i < manualSelections.length
              ? manualSelections[i]
              : items[i].selected,
        ),
    ];
  }

  @override
  void onInit() {
    super.onInit();
    init();
  }

  @override
  void onReady() {
    super.onReady();
    requestPermissions();
  }

  @override
  void init() {
    final args = Get.arguments;
    final source = args is SyncDataSource
        ? args
        : SyncDataDetailData.mock.sources.first;
    useSource(source);
  }

  @override
  void unInit() {}

  @override
  void onClose() {
    unInit();
    super.onClose();
  }

  void useSource(SyncDataSource source) {
    if (data.value.source.title == source.title &&
        manualSelections.isNotEmpty) {
      return;
    }

    final nextData = SyncSourceDetailData.forSource(source);
    data.value = nextData;
    final selectedIndex = nextData.modeOptions.indexWhere(
      (option) => option.selected,
    );
    selectedModeIndex.value = selectedIndex == -1 ? 0 : selectedIndex;
    manualSelections.assignAll([
      for (final item in nextData.manualItems) item.selected,
    ]);
    syncMessage.value = null;
    syncSucceeded.value = false;
    permissionStatus.value = null;
  }

  Future<void> requestPermissions() async {
    final source = _currentHealthSource;
    if (source == null) return;

    final title = data.value.source.title;
    if (!HealthSyncSourcePolicy.isSupported(source, platform)) {
      permissionStatus.value = '当前平台不支持 $title';
      return;
    }

    permissionStatus.value = '正在请求 $title 权限…';
    try {
      final available = await service.isAvailable(source: source);
      if (!available) {
        permissionStatus.value = '$title 不可用';
        return;
      }

      final granted = await service.requestAuthorization(
        source: source,
        types: _permissionTypes,
      );
      permissionStatus.value = granted ? '已授权 $title 健康数据' : '$title 未授权';
    } catch (error) {
      permissionStatus.value = error is MissingPluginException
          ? '$title 不可用'
          : '$title 授权失败';
    }
  }

  void selectSyncMode(int index) {
    if (index < 0 || index >= data.value.modeOptions.length) return;
    selectedModeIndex.value = index;
  }

  void toggleManualSelection(int index) {
    if (index < 0 || index >= manualSelections.length) return;
    manualSelections[index] = !manualSelections[index];
  }

  Future<void> syncHealthData() async {
    if (syncing.value) return;
    final source = _currentHealthSource;
    if (source == null) return;

    final title = data.value.source.title;
    syncing.value = true;
    syncSucceeded.value = false;
    syncMessage.value = '$title 同步中';

    try {
      final types = _selectedHealthTypes();
      final available = await service.isAvailable(source: source);
      if (!available) {
        _setSyncResult('$title 当前设备不可用', false);
        return;
      }

      final requested = await service.requestAuthorization(
        source: source,
        types: types,
      );
      if (!requested) {
        _setSyncResult('$title 未完成授权', false);
        return;
      }

      final now = DateTime.now();
      final syncedSource = await service.sync(
        source: source,
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now,
        types: types,
      );
      if (!syncedSource.hasData) {
        _setSyncResult('$title 未读取到健康数据，请在系统“健康”中允许读取后重试', false);
        return;
      }

      HealthSyncRuntime.replaceRealDataSource(syncedSource);
      _setSyncResult('$title 同步成功', true);
    } catch (error) {
      _setSyncResult('$title 同步失败：${_syncErrorText(error)}', false);
    } finally {
      syncing.value = false;
    }
  }

  HealthSyncSource? get _currentHealthSource {
    return HealthSyncSourcePolicy.sourceForTitle(data.value.source.title);
  }

  void _setSyncResult(String message, bool succeeded) {
    syncMessage.value = message;
    syncSucceeded.value = succeeded;
  }

  String _syncErrorText(Object error) {
    if (error is PlatformException) {
      return error.message ?? error.code;
    }
    return error.toString();
  }

  List<HealthSyncDataType> _selectedHealthTypes() {
    if (!isManualSyncSelected) return _permissionTypes;

    final selected = <HealthSyncDataType>[];
    for (final item in manualItems) {
      if (!item.selected) continue;
      switch (item.title) {
        case '步数':
          selected.add(HealthSyncDataType.steps);
        case '距离':
          selected.add(HealthSyncDataType.distance);
        case '卡路里':
          selected.add(HealthSyncDataType.calories);
        case '活动时间':
          selected.add(HealthSyncDataType.activeMinutes);
      }
    }
    return selected.isEmpty ? const [HealthSyncDataType.steps] : selected;
  }
}
