import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/common/config/localized_text.dart';
import 'package:pedometer/common/network/api_exception.dart';

/// 接口结果的用户提示（统一走轻量 toast）。
abstract final class ApiFeedback {
  static void error(String message) => _show(message);

  static void success(String message) => _show(message);

  /// 从异常映射提示：[ApiException] 用其 message，其余用 [fallback]。
  static void fromException(Object e, {String? fallback}) {
    if (e is ApiException) {
      error(e.message);
    } else {
      error(fallback ?? lt('Operation failed', '操作失败'));
    }
  }

  static void _show(String message) {
    if (message.isEmpty) return;
    Get.rawSnackbar(
      message: message,
      snackPosition: SnackPosition.BOTTOM,
      margin: EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.lg,
      backgroundColor: AppColors.surfaceCardTop,
      duration: const Duration(seconds: 2),
    );
  }
}
