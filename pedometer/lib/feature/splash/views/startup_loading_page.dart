import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_config.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/common/config/localized_text.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/feature/legal/legal_navigation.dart';
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
            final privacyConsentLoaded = controller.privacyConsentLoaded.value;
            final privacyConsentAccepted =
                controller.privacyConsentAccepted.value;
            if (privacyConsentLoaded && !privacyConsentAccepted) {
              return _StartupPrivacyConsent(controller: controller);
            }

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
                    status: privacyConsentLoaded
                        ? status
                        : StartupNetworkStatus.checking,
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

    return Center(
      child: SizedBox(width: contentWidth, child: child),
    );
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

class _StartupPrivacyConsent extends StatelessWidget {
  final StartupLoadingViewModel controller;

  const _StartupPrivacyConsent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            26.h,
            AppSpacing.xxl,
            26.h,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 52.h).clamp(
                0,
                double.infinity,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AppIconMark(size: 88.w),
                SizedBox(height: AppSpacing.lg),
                Text(
                  Constants.appName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                SizedBox(height: AppSpacing.xxl),
                const _PrivacyTextPanel(),
                SizedBox(height: AppSpacing.lg),
                Obx(
                  () => _PrivacyConsentActions(
                    checked: controller.privacyConsentChecked.value,
                    onToggle: controller.togglePrivacyConsentChecked,
                    onAgree: () {
                      if (controller.privacyConsentChecked.value) {
                        controller.acceptPrivacyConsent();
                        return;
                      }
                      _showPrivacyRequiredSheet(context);
                    },
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                _PrivacyExitButton(onTap: controller.rejectPrivacyConsent),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPrivacyRequiredSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.56),
      builder: (_) => const _PrivacyRequiredSheet(),
    );
  }
}

class _PrivacyConsentActions extends StatelessWidget {
  final bool checked;
  final VoidCallback onToggle;
  final VoidCallback onAgree;

  const _PrivacyConsentActions({
    required this.checked,
    required this.onToggle,
    required this.onAgree,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PrivacyCheckRow(checked: checked, onToggle: onToggle),
        SizedBox(height: AppSpacing.lg),
        _PrivacyAgreeButton(onTap: onAgree),
      ],
    );
  }
}

class _PrivacyTextPanel extends StatelessWidget {
  const _PrivacyTextPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceCardTop, AppColors.surfaceCardBottom],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.strokeCard),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandGreen.withValues(alpha: 0.12),
            blurRadius: 24.r,
            offset: Offset(0, 12.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Text(
          _startupPrivacyText(
            'startup_privacy_intro',
            'To keep the app running properly and improve your experience, we will process necessary device and app information, network and diagnostics information, and in-app usage data after you agree. Some data may be processed by service providers we use. We will not sell your personal information. Please read the Privacy Policy and User Agreement for details.',
          ),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            height: 1.48,
          ),
        ),
      ),
    );
  }
}

class _PrivacyCheckRow extends StatelessWidget {
  final bool checked;
  final VoidCallback onToggle;

  const _PrivacyCheckRow({required this.checked, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PrivacyCheckbox(checked: checked, onTap: onToggle),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _startupPrivacyText(
                    'startup_privacy_check_prefix',
                    'I have read and agree to the ',
                  ),
                  style: _checkTextStyle(),
                ),
                _PrivacyLink(
                  text: _startupPrivacyText(
                    'startup_privacy_policy',
                    'Privacy Policy',
                  ),
                  onTap: () => LegalNavigation.openPrivacyPolicy(
                    title: _startupPrivacyText(
                      'startup_privacy_policy',
                      'Privacy Policy',
                    ),
                  ),
                ),
                Text(
                  _startupPrivacyText('startup_privacy_check_and', ' and '),
                  style: _checkTextStyle(),
                ),
                _PrivacyLink(
                  text: _startupPrivacyText(
                    'startup_user_agreement',
                    'User Agreement',
                  ),
                  onTap: () => LegalNavigation.openUserAgreement(
                    title: _startupPrivacyText(
                      'startup_user_agreement',
                      'User Agreement',
                    ),
                  ),
                ),
                Text(
                  _startupPrivacyText(
                    'startup_privacy_check_suffix',
                    ', and agree to process necessary data as described.',
                  ),
                  style: _checkTextStyle(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  TextStyle _checkTextStyle() {
    return TextStyle(
      color: Colors.white.withValues(alpha: 0.82),
      fontSize: 14.sp,
      fontWeight: FontWeight.w700,
      height: 1.35,
    );
  }
}

class _PrivacyCheckbox extends StatelessWidget {
  final bool checked;
  final VoidCallback onTap;

  const _PrivacyCheckbox({required this.checked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30.w,
      height: 30.w,
      child: Material(
        color: checked ? AppColors.brandGreen : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xs),
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              border: Border.all(
                color: checked
                    ? AppColors.brandGreen
                    : Colors.white.withValues(alpha: 0.9),
                width: 2.w,
              ),
            ),
            child: checked
                ? Icon(
                    Icons.check_rounded,
                    color: const Color(0xFF00130A),
                    size: 22.w,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _PrivacyLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _PrivacyLink({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.brandGreenLight,
          fontSize: 14.sp,
          fontWeight: FontWeight.w900,
          height: 1.35,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.brandGreenLight,
          decorationThickness: 1.5,
        ),
      ),
    );
  }
}

class _PrivacyAgreeButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PrivacyAgreeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: Material(
        color: AppColors.brandGreen,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.full),
          onTap: onTap,
          child: Center(
            child: Text(
              _startupPrivacyText(
                'startup_agree_continue',
                'Agree and Continue',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF00130A),
                fontSize: 18.sp,
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

class _PrivacyRequiredSheet extends StatelessWidget {
  const _PrivacyRequiredSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.md,
          AppSpacing.xxl,
          AppSpacing.xxl,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.bgPrimary,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.strokeCard),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.32),
                blurRadius: 28.r,
                offset: Offset(0, 12.h),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _startupPrivacyText(
                    'startup_consent_required_title',
                    'Consent required',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  _startupPrivacyText(
                    'startup_consent_required_message',
                    'Please read and check the Privacy Policy and User Agreement before continuing.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                SizedBox(
                  height: 52.h,
                  child: Material(
                    color: AppColors.brandGreen,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      onTap: Get.back<void>,
                      child: Center(
                        child: Text(
                          _startupPrivacyText('startup_got_it', 'Got it'),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyExitButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PrivacyExitButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        _startupPrivacyText('startup_disagree_exit', 'Disagree and Exit'),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 15.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _startupPrivacyText(String key, String fallback) {
  return ResourceLoader.string('common', key, fallback: fallback);
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
