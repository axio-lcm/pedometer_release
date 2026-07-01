import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/common/config/app_config.dart';
import 'package:pedometer/feature/splash/viewmodel/startup_loading_view_model.dart';

class StartupLoadingPage extends GetView<StartupLoadingViewModel> {
  static const String routeName = '/startup-loading';

  const StartupLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StartupLoadingContent(onFinished: controller.onLoadingFinished);
  }
}

class StartupLoadingContent extends StatefulWidget {
  final Future<void> Function()? onFinished;
  final Duration duration;

  const StartupLoadingContent({
    super.key,
    this.onFinished,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<StartupLoadingContent> createState() => _StartupLoadingContentState();
}

class _StartupLoadingContentState extends State<StartupLoadingContent>
    with SingleTickerProviderStateMixin {
  static const _backgroundColor = Color(0xFF00050A);
  static Color get _progressFill => AppColors.brandGreen;
  static const _progressTrack = Color(0xFF15311F);

  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(_overlayStyle);
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _progressController.forward().whenComplete(() async {
      if (!mounted) return;
      await widget.onFinished?.call();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlayStyle,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              final progress = Curves.easeOutCubic.transform(
                _progressController.value,
              );
              final percent = (progress * 100).round();
              return Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _AppIconMark(size: 112.w),
                          SizedBox(height: AppSpacing.xl),
                          Text(
                            Constants.appName,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.86),
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.xxl,
                      0,
                      AppSpacing.xxl,
                      AppSpacing.xl + 36.h,
                    ),
                    child: _StartupProgressBar(
                      progress: progress,
                      percent: percent,
                      fillColor: _progressFill,
                      trackColor: _progressTrack,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static const _overlayStyle = SystemUiOverlayStyle(
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: _backgroundColor,
    systemNavigationBarIconBrightness: Brightness.light,
  );
}

class _AppIconMark extends StatelessWidget {
  final double size;

  const _AppIconMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24.r)),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/app_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _StartupProgressBar extends StatelessWidget {
  final double progress;
  final int percent;
  final Color fillColor;
  final Color trackColor;

  const _StartupProgressBar({
    required this.progress,
    required this.percent,
    required this.fillColor,
    required this.trackColor,
  });

  static const _designWidth = 327.0;
  static const _height = 54.0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width - AppSpacing.xxl * 2;
    final barWidth = width.clamp(240.0, _designWidth.w);
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Center(
      child: SizedBox(
        width: barWidth,
        height: _height.h,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: trackColor)),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: constraints.maxWidth * clampedProgress,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.brandGreenLight,
                              AppColors.brandGreen,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        '$percent%',
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          shadows: const [
                            Shadow(color: Color(0x66000000), blurRadius: 6),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
