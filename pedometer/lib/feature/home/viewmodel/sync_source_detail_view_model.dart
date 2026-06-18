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
  final authStatus = HealthAuthStatus.unknown.obs;

  /// 是否已确认连接（授权）。仅 [HealthAuthStatus.authorized] 才算已连接，
  /// iOS 上「未确认」不会被误判为已连接。
  bool get isConnected => authStatus.value == HealthAuthStatus.authorized;

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
    // 进入页面时不主动弹权限，仅恢复上一次确认过的连接状态（保存设置时才申请）。
    final healthSource = HealthSyncSourcePolicy.sourceForTitle(source.title);
    final restored = healthSource == null
        ? HealthAuthStatus.unknown
        : HealthSyncRuntime.connectionStatusOf(healthSource);
    authStatus.value = restored;
    permissionStatus.value = restored == HealthAuthStatus.unknown
        ? null
        : _authStatusText(restored, source.title);
  }

  String _authStatusText(HealthAuthStatus status, String title) {
    return switch (status) {
      HealthAuthStatus.authorized => '已授权 $title 健康数据',
      HealthAuthStatus.denied => '$title 未授权，请在系统「健康」中允许读取',
      HealthAuthStatus.unavailable => '$title 当前设备不可用',
      HealthAuthStatus.unsupported => '当前平台不支持 $title',
      HealthAuthStatus.unknown => '$title 授权状态待确认，同步后可验证是否读取到数据',
    };
  }

  void selectSyncMode(int index) {
    if (index < 0 || index >= data.value.modeOptions.length) return;
    selectedModeIndex.value = index;
  }

  void toggleManualSelection(int index) {
    if (index < 0 || index >= manualSelections.length) return;
    manualSelections[index] = !manualSelections[index];
  }

  /// 点击「保存设置」时触发：发起权限申请并同步。
  /// 能同步到数据即视为已授权（已连接），否则视为未授权（未连接）。
  Future<void> syncHealthData() async {
    if (syncing.value) return;
    final source = _currentHealthSource;
    if (source == null) return;

    final title = data.value.source.title;

    if (!HealthSyncSourcePolicy.isSupported(source, platform)) {
      _applyAuthStatus(source, HealthAuthStatus.unsupported, title);
      _setSyncResult('当前平台不支持 $title', false);
      return;
    }

    syncing.value = true;
    syncSucceeded.value = false;

    try {
      final types = _selectedHealthTypes();
      final available = await service.isAvailable(source: source);
      if (!available) {
        _applyAuthStatus(source, HealthAuthStatus.unavailable, title);
        _setSyncResult('$title 当前设备不可用', false);
        return;
      }

      // 步骤一：先完整跑完权限申请，等待用户在系统弹窗中操作完成。
      // （iOS 上无论允许/拒绝都返回 true，不能作为是否授权的判断依据。）
      syncMessage.value = '$title 权限申请中…';
      final requested = await service.requestAuthorization(
        source: source,
        types: types,
      );
      if (!requested) {
        // Android 明确拒绝（iOS 不会进入此分支）。
        _applyAuthStatus(source, HealthAuthStatus.denied, title);
        _setSyncResult('$title 未完成授权', false);
        return;
      }

      // 步骤二：权限就绪后再同步数据（不重复申请；读取带重试以规避 iOS 授权延迟）。
      syncMessage.value = '$title 同步中…';
      final now = DateTime.now();
      final syncedSource = await service.sync(
        source: source,
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now,
        types: types,
        ensureAuthorized: false,
      );
      if (!syncedSource.hasData) {
        // 同步不到数据：默认视为未授权 / 未连接。
        _applyAuthStatus(source, HealthAuthStatus.denied, title);
        _setSyncResult('$title 未读取到健康数据，请在系统「健康」中允许读取后重试', false);
        return;
      }

      // 同步到数据：默认视为已授权 / 已连接。
      _applyAuthStatus(source, HealthAuthStatus.authorized, title);
      HealthSyncRuntime.replaceRealDataSource(syncedSource);
      _setSyncResult('$title 同步成功', true);
    } catch (error) {
      _setSyncResult('$title 同步失败：${_syncErrorText(error)}', false);
    } finally {
      syncing.value = false;
    }
  }

  /// 更新本页授权状态与提示文案，并把连接状态同步到全局运行时（供来源列表显示）。
  void _applyAuthStatus(
    HealthSyncSource source,
    HealthAuthStatus status,
    String title,
  ) {
    authStatus.value = status;
    permissionStatus.value = _authStatusText(status, title);
    HealthSyncRuntime.setConnectionStatus(source, status);
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
