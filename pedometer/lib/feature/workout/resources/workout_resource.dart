import 'package:flutter/material.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/resource_loader.dart';

/// 运动页模块静态资源（对齐 HomeResource / MainResource 写法）。
class WorkoutResource {
  WorkoutResource._();

  static Color get background => ResourceLoader.color(
    'workout',
    'workout_bg',
    fallbackModule: 'common',
    fallback: AppColors.bgPrimary,
  );
}
