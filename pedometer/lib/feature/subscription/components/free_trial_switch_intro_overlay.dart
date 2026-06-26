import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/localized_text.dart';

class FreeTrialSwitchIntroOverlay extends StatefulWidget {
  final bool visible;
  final VoidCallback onFinished;

  const FreeTrialSwitchIntroOverlay({
    super.key,
    required this.visible,
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
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoSwitch(
                  value: _switchEnabled,
                  activeTrackColor: AppColors.brandGreen,
                  onChanged: (_) {},
                ),
                SizedBox(height: 14.h),
                Text(
                  lt('3-Day Free Trial', '3天免费试用'),
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
                  lt('is Enabled！', '已开启！'),
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
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const _GradientText({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Color(0xFF69EAFF),
          Color(0xFFFFFFFF),
          Color(0xFFEDF5FD),
          Color(0xFFF5CCFF),
        ],
      ).createShader(bounds),
      child: Text(text, textAlign: TextAlign.center, style: style),
    );
  }
}
