import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/component/asset_metric_icon.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/workout/components/workout_tracking_components.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';
import 'package:pedometer/feature/workout/viewmodel/workout_tracking_view_model.dart';
import 'package:pedometer/feature/workout/views/exercise_result_page.dart';

/// 点击「开始运动」后的运动记录中页面。
class WorkoutTrackingPage extends StatefulWidget {
  static const String routeName = WorkoutRouteTable.pathTracking;

  const WorkoutTrackingPage({super.key});

  @override
  State<WorkoutTrackingPage> createState() => _WorkoutTrackingPageState();
}

class _WorkoutTrackingPageState extends State<WorkoutTrackingPage> {
  WorkoutTrackingViewModel get controller =>
      Get.find<WorkoutTrackingViewModel>();

  final _mapSectionKey = GlobalKey<WorkoutMapSectionState>();
  bool _showMoreMenu = false;
  bool _controlsLocked = false;
  bool _finishingWorkout = false;
  String? _countdownLabel;
  int _countdownStep = 0;
  Timer? _countdownTimer;

  static const _countdownLabels = ['3', '2', '1', 'GO'];

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: WorkoutResource.background,
        body: Stack(
          children: [
            const Positioned.fill(child: _WorkoutTrackingBackground()),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Obx(
                      () => AppTopNavigationBar(
                        title: controller.workoutTitle.value,
                        onBack: _controlsLocked ? _ignoreLockedTap : _back,
                        rightIcon: Icons.more_horiz_rounded,
                        onRightTap: _controlsLocked
                            ? _ignoreLockedTap
                            : _toggleMoreMenu,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: AppSpacing.xl),
                      child: Column(
                        children: [
                          WorkoutMapSection(
                            key: _mapSectionKey,
                            data: controller.template,
                            controller: controller,
                            showMoreMenu: _showMoreMenu,
                            onDismissMoreMenu: _dismissMoreMenu,
                            onImportMusic: _importMusic,
                            onWorkoutRoute: _handleMoreAction,
                            controlsLocked: _controlsLocked,
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            child: Obx(() {
                              final data = controller.liveData;
                              return Column(
                                children: [
                                  WorkoutMetricPanel(data: data),
                                  const SizedBox(height: 28),
                                  WorkoutControlPanel(
                                    data: data,
                                    locked: _controlsLocked,
                                    onLockToggle: _toggleControlsLock,
                                    muted: controller.musicMuted.value,
                                    onMuteToggle: () =>
                                        controller.toggleMusicMute(),
                                    onPrimaryTap: _handlePrimaryTap,
                                    onEnd: _endWorkout,
                                  ),
                                  const SizedBox(
                                    height: AppBottomTabBarMetrics.bottomOffset,
                                  ),
                                  WorkoutMusicCard(
                                    data: data,
                                    onPlayPause: _controlsLocked
                                        ? null
                                        : controller.toggleMusic,
                                    onNext: _controlsLocked
                                        ? null
                                        : controller.nextMusic,
                                    onOpenList: _controlsLocked
                                        ? null
                                        : _openMusicList,
                                  ),
                                ],
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_countdownLabel != null)
              Positioned.fill(
                child: _WorkoutStartCountdownOverlay(
                  label: _countdownLabel!,
                  step: _countdownStep,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleMoreMenu() {
    if (_controlsLocked) return;
    setState(() => _showMoreMenu = !_showMoreMenu);
  }

  void _dismissMoreMenu() {
    if (!_showMoreMenu) return;
    setState(() => _showMoreMenu = false);
  }

  void _handlePrimaryTap() {
    if (_controlsLocked) return;
    if (_countdownLabel != null) return;
    if (controller.status.value == WorkoutStatus.ready) {
      _startCountdown();
      return;
    }
    controller.togglePrimary();
  }

  void _startCountdown() {
    _dismissMoreMenu();
    _countdownTimer?.cancel();
    setState(() {
      _countdownStep = 0;
      _countdownLabel = _countdownLabels.first;
    });
    _scheduleNextCountdownTick();
  }

  void _scheduleNextCountdownTick() {
    final delay = _countdownLabel == 'GO'
        ? const Duration(milliseconds: 650)
        : const Duration(seconds: 1);
    _countdownTimer = Timer(delay, () {
      if (!mounted) return;
      final nextStep = _countdownStep + 1;
      if (nextStep >= _countdownLabels.length) {
        setState(() => _countdownLabel = null);
        if (controller.status.value == WorkoutStatus.ready) {
          controller.start();
        }
        return;
      }
      setState(() {
        _countdownStep = nextStep;
        _countdownLabel = _countdownLabels[nextStep];
      });
      _scheduleNextCountdownTick();
    });
  }

  void _toggleControlsLock() {
    setState(() {
      _controlsLocked = !_controlsLocked;
      if (_controlsLocked) {
        _showMoreMenu = false;
      }
    });
  }

  void _ignoreLockedTap() {}

  void _handleMoreAction() {
    if (_controlsLocked) return;
    _dismissMoreMenu();
    Get.toNamed(WorkoutRouteTable.pathRouteHistory);
  }

  Future<void> _importMusic() async {
    if (_controlsLocked) return;
    _dismissMoreMenu();
    await controller.importMusic();
  }

  void _openMusicList() {
    if (_controlsLocked) return;
    _dismissMoreMenu();
    Get.toNamed(WorkoutRouteTable.pathMusicList);
  }

  // 返回：运动进行中时先弹确认框，确认后才退出；未开始则直接返回。
  void _back() {
    if (_controlsLocked) return;
    if (!controller.hasActiveSession) {
      if (Get.key.currentState?.canPop() ?? false) Get.back<void>();
      return;
    }
    _showExitConfirmDialog();
  }

  void _showExitConfirmDialog() {
    Get.dialog<void>(
      _ExitConfirmDialog(workoutType: controller.currentWorkoutType),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
    );
  }

  // 结束运动：聚合真实数据并跳结果页（替换记录中页，结果页「完成」回到运动主页）。
  void _endWorkout() {
    if (_controlsLocked || _finishingWorkout) return;
    unawaited(_finishWorkout());
  }

  Future<void> _finishWorkout() async {
    _finishingWorkout = true;
    controller.end();
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final snapshot = await _takeMapSnapshot();
    controller.saveRouteHistory(mapSnapshot: snapshot);
    if (!mounted) return;
    Get.offNamed(
      ExerciseResultPage.routeName,
      arguments: controller.toResultData(),
    );
  }

  Future<Uint8List?> _takeMapSnapshot() async {
    try {
      return await _mapSectionKey.currentState?.takeSnapshot();
    } catch (_) {
      return null;
    }
  }
}

class _WorkoutStartCountdownOverlay extends StatelessWidget {
  final String label;
  final int step;

  const _WorkoutStartCountdownOverlay({
    required this.label,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 360),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            final scale = Tween<double>(begin: 0.72, end: 1).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: scale, child: child),
            );
          },
          child: Text(
            label,
            key: ValueKey(step),
            style: TextStyle(
              color: AppColors.brandGreen,
              fontSize: 248,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

/// 运动进行中点击返回的确认弹窗：玻璃卡片风格，提供「继续运动」与「确认返回」。
class _ExitConfirmDialog extends StatelessWidget {
  final WorkoutType workoutType;

  const _ExitConfirmDialog({required this.workoutType});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          // 不透明背景：取玻璃卡片同色但去掉透明度。
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(AppColors.surfaceCardTop, AppColors.bgPrimary),
              Color.alphaBlend(
                AppColors.surfaceCardBottom,
                AppColors.bgPrimary,
              ),
            ],
          ),
          border: Border.all(color: AppColors.strokeCard, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTypeIcon(workoutType),
            SizedBox(height: AppSpacing.lg),
            Text(
              WorkoutResource.exitConfirmTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              WorkoutResource.exitConfirmMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: WorkoutResource.exitConfirmBack,
                    filled: false,
                    onTap: () {
                      Get.back<void>(); // 关闭弹窗
                      if (Get.key.currentState?.canPop() ?? false) {
                        Get.back<void>(); // 退出运动页
                      }
                    },
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _DialogButton(
                    label: WorkoutResource.exitConfirmContinue,
                    filled: true,
                    onTap: () => Get.back<void>(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 运动栏对应类型的图标（户外 / 室内 / 健走 / 徒步），优先用 SVG 资源。
  Widget _buildTypeIcon(WorkoutType type) {
    if (type.iconAsset != null) {
      return SizedBox(
        width: 56,
        height: 56,
        child: AssetMetricIcon(assetName: type.iconAsset!, size: 56),
      );
    }
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: type.color.withValues(alpha: 0.16),
        border: Border.all(color: type.color.withValues(alpha: 0.55)),
      ),
      child: Center(child: Icon(type.icon, color: type.color, size: 28)),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _DialogButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.full),
          color: filled ? AppColors.brandGreen : Colors.transparent,
          border: filled
              ? null
              : Border.all(color: AppColors.strokeCard, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: filled ? AppColors.bgPrimary : AppColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _WorkoutTrackingBackground extends StatelessWidget {
  const _WorkoutTrackingBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bgPrimary,
            AppColors.bgRadialBlue.withValues(alpha: 0.72),
            AppColors.bgPrimary,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 130,
            left: -90,
            right: -90,
            height: 360,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.bgRadialGreen.withValues(alpha: 0.32),
                    AppColors.bgRadialBlue.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
