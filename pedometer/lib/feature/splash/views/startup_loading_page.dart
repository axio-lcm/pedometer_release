import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_config.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/common/config/localized_text.dart';
import 'package:pedometer/feature/splash/viewmodel/startup_loading_view_model.dart';

class StartupLoadingPage extends GetView<StartupLoadingViewModel> {
  static const String routeName = '/startup-loading';

  const StartupLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StartupLoadingContent(controller: controller);
  }
}

class StartupLoadingContent extends StatelessWidget {
  final StartupLoadingViewModel controller;

  const StartupLoadingContent({super.key, required this.controller});

  static const _backgroundColor = Color(0xFF00050A);
  static Color get _progressFill => AppColors.brandGreen;
  static const _progressTrack = Color(0xFF15311F);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlayStyle,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: SafeArea(
          child: Obx(() {
            final status = controller.networkStatus.value;
            final progress = controller.progress.value.clamp(0.0, 100.0);
            return Column(
              children: [
                const Expanded(child: _StartupBrandMark()),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    0,
                    AppSpacing.xxl,
                    AppSpacing.xl + 36.h,
                  ),
                  child: _StartupBottomStatus(
                    status: status,
                    progress: progress,
                    onRetry: controller.retryNetwork,
                  ),
                ),
              ],
            );
          }),
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

class _StartupBrandMark extends StatelessWidget {
  const _StartupBrandMark();

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}

class _StartupBottomStatus extends StatelessWidget {
  final StartupNetworkStatus status;
  final double progress;
  final VoidCallback onRetry;

  const _StartupBottomStatus({
    required this.status,
    required this.progress,
    required this.onRetry,
  });

  // 底部状态区统一宽度：进度条、重试、spinner 三态共用，保证宽度一致。
  static const _contentMaxWidth = 327.0;

  @override
  Widget build(BuildContext context) {
    final available = MediaQuery.sizeOf(context).width - AppSpacing.xxl * 2;
    final contentWidth = available.clamp(240.0, _contentMaxWidth.w);

    final child = switch (status) {
      StartupNetworkStatus.disconnected => _StartupNetworkRetry(
        onRetry: onRetry,
      ),
      StartupNetworkStatus.checking => const _StartupSpinner(),
      StartupNetworkStatus.connected => _StartupProgressBar(
        progress: progress / 100,
        percent: progress.round(),
        fillColor: StartupLoadingContent._progressFill,
        trackColor: StartupLoadingContent._progressTrack,
      ),
    };

    return Center(child: SizedBox(width: contentWidth, child: child));
  }
}

class _StartupSpinner extends StatelessWidget {
  const _StartupSpinner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54.h,
      child: Center(
        child: SizedBox(
          width: 28.w,
          height: 28.w,
          child: CircularProgressIndicator(
            strokeWidth: 3.w,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandGreen),
            backgroundColor: const Color(0xFF15311F),
          ),
        ),
      ),
    );
  }
}

class _StartupNetworkRetry extends StatelessWidget {
  final VoidCallback onRetry;

  const _StartupNetworkRetry({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          lt('Network unavailable', '网络不可用'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 17.sp,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          lt('Please check your connection and try again.', '请检查网络连接后重试。'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        _StartupRetryButton(onTap: onRetry),
      ],
    );
  }
}

class _StartupRetryButton extends StatelessWidget {
  final VoidCallback onTap;

  const _StartupRetryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54.h,
      child: Material(
        color: AppColors.brandGreen,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.full),
          onTap: onTap,
          child: Center(
            child: Text(
              lt('Try Again', '重试'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF00130A),
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
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

  static const _height = 54.0;

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return SizedBox(
      width: double.infinity,
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
                            colors: [AppColors.brandGreenLight, fillColor],
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
                        ),
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
}
