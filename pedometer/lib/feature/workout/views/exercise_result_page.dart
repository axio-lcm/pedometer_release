import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/workout/components/exercise_result_components.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';
import 'package:pedometer/feature/workout/viewmodel/exercise_result_view_model.dart';
import 'package:share_plus/share_plus.dart';

/// 运动结束（运动完成）结果页：长按结束运动后进入，进入时在完成图标区域播放礼花。
class ExerciseResultPage extends StatefulWidget {
  static const String routeName = WorkoutRouteTable.pathResult;

  final ExerciseResultData data;
  final VoidCallback? onDone;
  final VoidCallback? onShare;

  const ExerciseResultPage({
    super.key,
    this.data = ExerciseResultData.mock,
    this.onDone,
    this.onShare,
  });

  @override
  State<ExerciseResultPage> createState() => _ExerciseResultPageState();
}

class _ExerciseResultPageState extends State<ExerciseResultPage> {
  final GlobalKey _iconAreaKey = GlobalKey();
  final GlobalKey _shareBoundaryKey = GlobalKey();
  ConfettiController? _confetti;
  bool _sharing = false;
  late final ExerciseResultViewModel _controller =
      Get.isRegistered<ExerciseResultViewModel>()
      ? Get.find<ExerciseResultViewModel>()
      : Get.put(ExerciseResultViewModel(fallbackData: widget.data));

  @override
  void initState() {
    super.initState();
    // 首帧渲染后，以完成图标区域为中心播放一次礼花。
    WidgetsBinding.instance.addPostFrameCallback((_) => _playConfetti());
  }

  @override
  void dispose() {
    _confetti?.kill();
    super.dispose();
  }

  void _playConfetti() {
    if (!mounted) return;
    final screen = MediaQuery.of(context).size;
    if (screen.isEmpty) return;

    // 默认大致取顶部图标区域；能拿到渲染框时精确定位到图标中心。
    var x = 0.5;
    var y = 0.26;
    final box = _iconAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final center = box.localToGlobal(box.size.center(Offset.zero));
      x = (center.dx / screen.width).clamp(0.0, 1.0);
      y = (center.dy / screen.height).clamp(0.0, 1.0);
    }

    _confetti = Confetti.launch(
      context,
      options: ConfettiOptions(
        particleCount: 80,
        spread: 360, // 以图标为中心向四周散开
        startVelocity: 26,
        x: x,
        y: y,
        colors: [
          AppColors.brandGreen,
          AppColors.brandGreenLight,
          AppColors.brandLime,
          AppColors.accentCyan,
          AppColors.accentOrange,
          AppColors.accentPurple,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _controller.data.copyWith(
      sportType: WorkoutResource.localizedWorkoutTypeTitle(
        _controller.data.sportType,
      ),
    );
    return Scaffold(
      backgroundColor: WorkoutResource.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _ExerciseResultBackground()),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: AppSpacing.xs,
                bottom: AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: AppTopNavigationBar(
                      title: data.sportType,
                      onBack: _back,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  RepaintBoundary(
                    key: _shareBoundaryKey,
                    child: ColoredBox(
                      color: WorkoutResource.background,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ExerciseCompleteHero(iconAreaKey: _iconAreaKey),
                            SizedBox(height: AppSpacing.xl),
                            ExerciseResultSummaryCard(data: data),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: ExerciseResultActionButtons(
                      onDone: widget.onDone ?? _back,
                      onShare: widget.onShare ?? _shareCurrentResult,
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _back() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back<void>();
    }
  }

  Future<void> _shareCurrentResult() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final box = context.findRenderObject() as RenderBox?;
      final origin = box == null || !box.hasSize
          ? const Rect.fromLTWH(0, 0, 1, 1)
          : box.localToGlobal(Offset.zero) & box.size;
      final pngBytes = await _captureResultPng();
      if (pngBytes == null || !mounted) return;
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              pngBytes,
              name: 'workout_result.png',
              mimeType: 'image/png',
            ),
          ],
          fileNameOverrides: const ['workout_result.png'],
          sharePositionOrigin: origin,
        ),
      );
      debugPrint(
        '[shareWorkoutResult] status=${result.status}, raw=${result.raw}',
      );
    } catch (error, stackTrace) {
      debugPrint('[shareWorkoutResult] failed: $error\n$stackTrace');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<Uint8List?> _captureResultPng() async {
    final context = _shareBoundaryKey.currentContext;
    if (context == null) return null;
    final boundary = context.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    if (boundary.debugNeedsPaint) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData?.buffer.asUint8List();
  }
}

class _ExerciseResultBackground extends StatelessWidget {
  const _ExerciseResultBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bgPrimary,
            AppColors.bgRadialBlue,
            AppColors.bgPrimary,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 80,
            left: -70,
            right: -70,
            height: 320,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.bgRadialGreen.withValues(alpha: 0.55),
                    AppColors.bgRadialBlue.withValues(alpha: 0.14),
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
