import 'package:flutter/material.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/workout/components/exercise_result_components.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';

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
  ConfettiController? _confetti;

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
    final data = widget.data;
    return Scaffold(
      backgroundColor: WorkoutResource.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _ExerciseResultBackground()),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTopNavigationBar(title: data.sportType, onBack: _back),
                  SizedBox(height: AppSpacing.sm),
                  ExerciseCompleteHero(iconAreaKey: _iconAreaKey),
                  SizedBox(height: AppSpacing.xl),
                  ExerciseResultSummaryCard(data: data),
                  SizedBox(height: AppSpacing.xl),
                  ExerciseResultActionButtons(
                    onDone: widget.onDone ?? _back,
                    // TODO: 接入真实分享逻辑。
                    onShare: widget.onShare,
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
