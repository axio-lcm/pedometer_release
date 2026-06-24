import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/localized_text.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/common/storage/language_service.dart';
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

  /// 同步历史的起始时间下界。HealthKit / Health Connect 不会返回此日期之前的数据，
  /// 取一个早于 iPhone / Apple Watch 健康数据普及的日期，等价于「读取全部历史」。
  static final DateTime _historyStartDate = DateTime(2014, 1, 1);

  /// 同步代次：每次发起同步自增，后台精修完成时若代次已变化则丢弃过期结果，
  /// 避免旧的后台精修覆盖更新一次同步的数据。
  static int _syncToken = 0;

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
  Worker? _languageWorker;

  /// 是否已确认连接（授权）。仅 [HealthAuthStatus.authorized] 才算已连接，
  /// iOS 上「未确认」不会被误判为已连接。
  bool get isConnected => authStatus.value == HealthAuthStatus.authorized;

  bool get isManualSyncSelected {
    final options = data.value.modeOptions;
    if (options.isEmpty) return false;
    return selectedModeIndex.value == 1;
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
    if (Get.isRegistered<LanguageService>()) {
      _languageWorker = ever<int>(
        Get.find<LanguageService>().localeRevision,
        (_) => refreshLocalizedData(),
      );
    }
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
    _languageWorker?.dispose();
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

  void refreshLocalizedData() {
    final source = data.value.source;
    final selectedIndex = selectedModeIndex.value;
    final selections = manualSelections.toList();
    final nextData = SyncSourceDetailData.forSource(source);
    data.value = nextData;
    selectedModeIndex.value = nextData.modeOptions.isEmpty
        ? 0
        : selectedIndex.clamp(0, nextData.modeOptions.length - 1).toInt();
    if (nextData.manualItems.isEmpty) {
      manualSelections.clear();
    } else {
      manualSelections.assignAll([
        for (var i = 0; i < nextData.manualItems.length; i++)
          i < selections.length
              ? selections[i]
              : nextData.manualItems[i].selected,
      ]);
    }
    permissionStatus.value = authStatus.value == HealthAuthStatus.unknown
        ? null
        : _authStatusText(authStatus.value, source.title);
  }

  String _authStatusText(HealthAuthStatus status, String title) {
    return switch (status) {
      HealthAuthStatus.authorized => lt(
        '$title health data authorized',
        '已授权 $title 健康数据',
      ),
      HealthAuthStatus.denied => lt(
        '$title is not authorized. Please allow access in the system Health settings.',
        '$title 未授权，请在系统「健康」中允许读取',
      ),
      HealthAuthStatus.unavailable => lt(
        '$title is unavailable on this device',
        '$title 当前设备不可用',
      ),
      HealthAuthStatus.unsupported => lt(
        '$title is not supported on this platform',
        '当前平台不支持 $title',
      ),
      HealthAuthStatus.unknown => lt(
        '$title authorization is pending. Sync to verify data access.',
        '$title 授权状态待确认，同步后可验证是否读取到数据',
      ),
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
      _setSyncResult(
        lt('$title is not supported on this platform', '当前平台不支持 $title'),
        false,
      );
      return;
    }

    syncing.value = true;
    syncSucceeded.value = false;

    try {
      final types = _selectedHealthTypes();
      final available = await service.isAvailable(source: source);
      if (!available) {
        _applyAuthStatus(source, HealthAuthStatus.unavailable, title);
        _setSyncResult(
          lt('$title is unavailable on this device', '$title 当前设备不可用'),
          false,
        );
        return;
      }

      // 步骤一：先完整跑完权限申请，等待用户在系统弹窗中操作完成。
      // （iOS 上无论允许/拒绝都返回 true，不能作为是否授权的判断依据。）
      syncMessage.value = lt(
        'Requesting $title permission...',
        '$title 权限申请中...',
      );
      final requested = await service.requestAuthorization(
        source: source,
        types: types,
      );
      if (!requested) {
        // Android 明确拒绝（iOS 不会进入此分支）。
        _applyAuthStatus(source, HealthAuthStatus.denied, title);
        _setSyncResult(
          lt('$title authorization was not completed', '$title 未完成授权'),
          false,
        );
        return;
      }

      // 步骤二：权限就绪后再同步数据（不重复申请；读取带重试以规避 iOS 授权延迟）。
      syncMessage.value = lt('Syncing $title...', '$title 同步中...');
      final now = DateTime.now();
      final token = ++_syncToken;
      final stopwatch = Stopwatch()..start();
      // 第一阶段：快速读取并聚合（步数为多源求和，可能偏大），界面秒级返回。
      final result = await service
          .sync(
            source: source,
            // 「有多久同步多久」：从健康数据可能存在的最早时间开始读取，
            // 覆盖手机内的全部历史健康数据，而非仅最近 30 天。
            startDate: _historyStartDate,
            endDate: now,
            types: types,
            ensureAuthorized: false,
          )
          // 兜底：即便底层意外挂起，也不让界面永远停在「同步中」。
          .timeout(const Duration(minutes: 2));
      if (!result.source.hasData) {
        // 同步不到数据：默认视为未授权 / 未连接。
        _applyAuthStatus(source, HealthAuthStatus.denied, title);
        _setSyncResult(
          lt(
            'No health data was read from $title. Allow access in the system Health settings and try again.',
            '$title 未读取到健康数据，请在系统「健康」中允许读取后重试',
          ),
          false,
        );
        return;
      }

      // 同步到数据：默认视为已授权 / 已连接，立即展示快速结果。
      _applyAuthStatus(source, HealthAuthStatus.authorized, title);
      HealthSyncRuntime.replaceRealDataSource(result.source);
      stopwatch.stop();
      // 记录一条同步历史，供同步详情/历史列表/历史详情展示本次保存的数据。
      _recordHistory(source: source, types: types, elapsed: stopwatch.elapsed);
      _setSyncResult(lt('$title sync successful', '$title 同步成功'), true);

      // 第二阶段：后台逐天去重步数（仅 Apple Health 步数需要多源去重），
      // 完成后静默替换数据源刷新展示，不阻塞界面、不影响「同步中」状态。
      if (source == HealthSyncSource.appleHealth &&
          types.contains(HealthSyncDataType.steps)) {
        _refineStepsInBackground(
          points: result.points,
          source: source,
          startDate: _historyStartDate,
          endDate: now,
          token: token,
        );
      }
    } on TimeoutException {
      _setSyncResult(
        lt(
          '$title sync timed out. Please try again later.',
          '$title 同步超时，请稍后重试',
        ),
        false,
      );
    } catch (error) {
      _setSyncResult(
        lt(
          '$title sync failed: ${_syncErrorText(error)}',
          '$title 同步失败：${_syncErrorText(error)}',
        ),
        false,
      );
    } finally {
      syncing.value = false;
    }
  }

  /// 追加一条同步历史记录，快照取本次同步后的当日数据。
  void _recordHistory({
    required HealthSyncSource source,
    required List<HealthSyncDataType> types,
    required Duration elapsed,
  }) {
    final now = DateTime.now();
    final snapshot =
        HealthSyncRuntime.latestSummary ??
        HealthDailySummary(
          date: now,
          steps: 0,
          distanceKm: 0,
          caloriesKcal: 0,
          activeMinutes: 0,
          source: source,
        );
    HealthSyncHistory.record(
      SyncHistoryEntry(
        id: '${source.name}-${now.microsecondsSinceEpoch}',
        time: now,
        source: source,
        mode: isManualSyncSelected
            ? lt('Manual Sync', '手动同步')
            : lt('Auto Sync', '自动同步'),
        itemCount: types.length,
        snapshot: snapshot,
        elapsed: elapsed,
      ),
    );
  }

  /// 后台逐天去重步数，完成后静默替换数据源刷新展示。不阻塞界面、不改 [syncing]。
  ///
  /// 这是「即发即忘」的后台任务：即便用户已离开本页，更新的是全局运行时数据源，
  /// 仍能安全完成；期间若又发起新同步（[_syncToken] 变化）则丢弃这次过期结果。
  void _refineStepsInBackground({
    required List<HealthDataPoint> points,
    required HealthSyncSource source,
    required DateTime startDate,
    required DateTime endDate,
    required int token,
  }) {
    unawaited(() async {
      try {
        final refined = await service.refineSteps(
          points: points,
          source: source,
          startDate: startDate,
          endDate: endDate,
        );
        if (token != _syncToken) return;
        if (refined.hasData) {
          HealthSyncRuntime.replaceRealDataSource(refined);
        }
      } catch (_) {
        // 后台精修失败不影响已展示的快速数据。
      }
    }());
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
        case 'Steps':
        case '步数':
          selected.add(HealthSyncDataType.steps);
        case 'Distance':
        case '距离':
          selected.add(HealthSyncDataType.distance);
        case 'Calories':
        case '卡路里':
          selected.add(HealthSyncDataType.calories);
        case 'Active Time':
        case '活动时间':
        case 'Time':
        case '时间':
          selected.add(HealthSyncDataType.activeMinutes);
      }
    }
    return selected.isEmpty ? const [HealthSyncDataType.steps] : selected;
  }
}
