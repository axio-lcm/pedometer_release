import 'dart:ui';

class WorkoutLocationMarkerStyle {
  static const Size logicalSize = Size(48, 36);
  static const Offset dotCenter = Offset(16, 15);
  static const Offset directionTip = Offset(47, 6);
  static const double dotRadius = 8;
  static const double whiteRingRadius = 12;
  static const double renderPixelRatio = 3;

  static final Offset anchor = Offset(
    dotCenter.dx / logicalSize.width,
    dotCenter.dy / logicalSize.height,
  );

  const WorkoutLocationMarkerStyle._();
}
