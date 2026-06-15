import 'dart:ui';

/// 当前位置 marker 的几何参数。
/// 方形画布、蓝点居中，朝「上」为朝向（marker.rotation = 罗盘朝向时整体旋转到手机指向）。
/// 视觉为 Google 风格：白边蓝点 + 向上张开的半透明扇形方向光锥。
class WorkoutLocationMarkerStyle {
  static const Size logicalSize = Size(64, 64);
  static const Offset dotCenter = Offset(32, 32);
  static const double dotRadius = 9;
  static const double whiteRingRadius = 13;

  /// 方向光锥：从圆点向上张开的扇形。
  static const double coneRadius = 31; // 光锥长度（接近画布上边）
  static const double coneHalfAngleRad = 0.52; // 半张角 ≈ 30°

  static const double renderPixelRatio = 3;

  /// 锚点为画布中心（圆点），保证光锥绕圆点旋转、圆点始终落在 GPS 坐标上。
  static final Offset anchor = Offset(
    dotCenter.dx / logicalSize.width,
    dotCenter.dy / logicalSize.height,
  );

  const WorkoutLocationMarkerStyle._();
}
