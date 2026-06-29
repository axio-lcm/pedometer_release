import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/localized_text.dart';

/// 购买加载弹窗
///
/// - type 0：免费试用订阅
/// - type 1：普通订阅
class PurchaseLoading extends StatefulWidget {
  final int type;

  const PurchaseLoading({super.key, required this.type});

  static bool _isShowing = false;
  static BuildContext? _dialogContext;
  static Future<void>? _dialogFuture;

  @override
  State<PurchaseLoading> createState() => _PurchaseLoadingState();

  static bool get isShowing => _isShowing;

  static Future<void> show({int type = 1}) {
    if (_isShowing) return _dialogFuture ?? Future.value();
    final context = Get.context;
    if (context == null) return Future.value();
    _isShowing = true;
    final future =
        showDialog<void>(
          context: context,
          useSafeArea: false,
          barrierDismissible: false,
          builder: (dialogContext) {
            _dialogContext = dialogContext;
            return PurchaseLoading(type: type);
          },
        ).whenComplete(() {
          _isShowing = false;
          _dialogContext = null;
          _dialogFuture = null;
        });
    _dialogFuture = future;
    return future;
  }

  static Future<void> dismiss() async {
    if (!_isShowing) return;
    final context = _dialogContext;
    if (context == null) return;
    try {
      Navigator.of(context, rootNavigator: true).pop();
    } catch (_) {}
    final future = _dialogFuture;
    if (future == null) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      return;
    }
    try {
      await future.timeout(const Duration(milliseconds: 350));
    } on TimeoutException {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    } catch (_) {}
  }
}

class _PurchaseLoadingState extends State<PurchaseLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _currentTextIndex = 0;

  List<String> get _texts => widget.type == 0
      ? [
          lt('3-Day Free Trial', '3天免费试用'),
          lt('Cancel anytime', '随时取消'),
          lt('No payment now', '现在无需付款'),
        ]
      : [
          lt('Cancel anytime', '随时取消'),
          lt('Cancel anytime', '随时取消'),
          lt('Cancel anytime', '随时取消'),
        ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);

    Future.delayed(const Duration(seconds: 1), _startTextAnimation);
  }

  void _startTextAnimation() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _currentTextIndex = (_currentTextIndex + 1) % _texts.length;
        });
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: AppColors.bgPrimary,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 100.w),
              SizedBox(
                width: 100.w,
                height: 100.w,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.rotate(
                          angle: _animation.value * 2 * 3.1415926,
                          child: SvgPicture.asset(
                            'assets/subscription/icon/loading.svg',
                            width: 128.w,
                            height: 128.w,
                          ),
                        ),
                        SvgPicture.asset(
                          'assets/subscription/icon/anquan.svg',
                          width: 50.w,
                          height: 60.w,
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: 15.w),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 1500),
                child: Text(
                  _texts[_currentTextIndex],
                  key: ValueKey<int>(_currentTextIndex),
                  style: TextStyle(
                    fontSize: 26.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
