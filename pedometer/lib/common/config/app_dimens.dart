import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 圆角令牌（规范 §6.1）
class AppRadius {
  AppRadius._();
  static double get xs => 8.r;
  static double get sm => 12.r;
  static double get md => 16.r;
  static double get lg => 20.r;
  static double get xl => 24.r;
  static double get xxl => 28.r;
  static double get full => 999.r;
}

/// 间距
class AppSpacing {
  AppSpacing._();
  static double get xxs => 4.w;
  static double get xs => 6.w;
  static double get sm => 8.w;
  static double get md => 12.w;
  static double get lg => 16.w;
  static double get xl => 20.w;
  static double get xxl => 24.w;
  static double get xxxl => 32.w;
}

/// 底部胶囊 Tab 统一尺寸：首页主 Tab 与详情页日/周/月 Tab 共用。
class AppBottomTabBarMetrics {
  AppBottomTabBarMetrics._();

  static const double width = 300;
  static const double height = 62;
  static const double bottomOffset = 28;
  static const double selectedWidth = 64;
  static const double itemExtent = 44;
  static const double iconSize = 24;
}
