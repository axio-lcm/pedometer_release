import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/storage/language_service.dart';
import 'package:pedometer/feature/subscription/resources/subscription_resource.dart';

class FreeTrialSwitchIntroOverlay extends StatefulWidget {
  final bool visible;
  final int trialDays;
  final VoidCallback onFinished;

  const FreeTrialSwitchIntroOverlay({
    super.key,
    required this.visible,
    this.trialDays = SubscriptionResource.defaultIntroOfferDays,
    required this.onFinished,
  });

  @override
  State<FreeTrialSwitchIntroOverlay> createState() =>
      _FreeTrialSwitchIntroOverlayState();
}

class _FreeTrialSwitchIntroOverlayState
    extends State<FreeTrialSwitchIntroOverlay> {
  Timer? _enableTimer;
  Timer? _finishTimer;
  bool _switchEnabled = false;

  @override
  void initState() {
    super.initState();
    if (widget.visible) _start();
  }

  @override
  void didUpdateWidget(covariant FreeTrialSwitchIntroOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.visible && widget.visible) _start();
    if (oldWidget.visible && !widget.visible) _reset();
  }

  @override
  void dispose() {
    _enableTimer?.cancel();
    _finishTimer?.cancel();
    super.dispose();
  }

  void _start() {
    _reset();
    _enableTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _switchEnabled = true);
    });
    _finishTimer = Timer(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      widget.onFinished();
    });
  }

  void _reset() {
    _enableTimer?.cancel();
    _finishTimer?.cancel();
    _switchEnabled = false;
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.visible,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: widget.visible ? 1 : 0,
        child: ColoredBox(
          color: const Color(0xFF00050A),
          child: Center(child: _localizedContent()),
        ),
      ),
    );
  }

  Widget _localizedContent() {
    if (!Get.isRegistered<LanguageService>()) return _content();

    return Obx(() {
      Get.find<LanguageService>().localeRevision.value;
      return _content();
    });
  }

  Widget _content() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CupertinoSwitch(
          value: _switchEnabled,
          activeTrackColor: AppColors.brandGreen,
          onChanged: (_) {},
        ),
        SizedBox(height: 14.h),
        Text(
          SubscriptionResource.threeDaysFreeTrialForDays(widget.trialDays),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.brandGreenLight,
            fontSize: 24.sp,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        Text(
          SubscriptionResource.freeTrialEnabled,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24.sp,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
