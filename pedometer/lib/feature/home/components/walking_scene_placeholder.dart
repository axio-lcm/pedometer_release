import 'package:flutter/material.dart';
import 'package:pedometer/common/config/app_colors.dart';

/// 步数卡内的步行场景前景层：展示 assets/home_overview_background.png。
/// 资源缺失时回退到轻量绘制的夜间森林占位（道路弧线 + 树剪影 + 光点）。
class WalkingSceneOverlay extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadiusGeometry borderRadius;
  final BoxFit fit;
  final AlignmentGeometry alignment;

  /// 在不改变容器宽高的前提下放大人物图（>1 放大），溢出部分由圆角裁剪。
  final double imageScale;

  /// 图片向下偏移的像素值（正值下移），用于让人物与底部容器贴合。
  final double imageOffsetY;

  const WalkingSceneOverlay({
    super.key,
    this.width,
    this.height = 90,
    this.borderRadius = BorderRadius.zero,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.bottomCenter,
    this.imageScale = 1.0,
    this.imageOffsetY = 0.0,
  });

  static const String _imageAsset = 'assets/home_overview_background.png';

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: height,
        width: width ?? double.infinity,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Transform.translate(
            offset: Offset(0, imageOffsetY),
            child: Transform.scale(
              scale: imageScale,
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                _imageAsset,
                fit: fit,
                alignment: alignment,
                errorBuilder: (context, error, stackTrace) =>
                    CustomPaint(painter: _ScenePainter()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WalkingScenePlaceholder extends WalkingSceneOverlay {
  const WalkingScenePlaceholder({
    super.key,
    super.width,
    super.height = 90,
    super.borderRadius = const BorderRadius.all(Radius.circular(20)),
    super.fit,
    super.alignment,
  });
}

class _ScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 道路弧线
    final road = Path()
      ..moveTo(size.width * 0.30, size.height)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.45,
        size.width * 0.70,
        size.height,
      );
    canvas.drawPath(
      road,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..shader = LinearGradient(
          colors: [
            AppColors.brandGreen.withValues(alpha: 0.0),
            AppColors.brandGreen.withValues(alpha: 0.45),
          ],
        ).createShader(Offset.zero & size),
    );

    // 树剪影
    final tree = Paint()
      ..color = AppColors.brandGreenDark.withValues(alpha: 0.7);
    for (final x in [0.12, 0.22, 0.80, 0.90]) {
      final cx = size.width * x;
      final p = Path()
        ..moveTo(cx, size.height * 0.5)
        ..lineTo(cx - 8, size.height)
        ..lineTo(cx + 8, size.height)
        ..close();
      canvas.drawPath(p, tree);
    }

    // 光点
    final dot = Paint()
      ..color = AppColors.brandGreenLight.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    for (final o in [
      const Offset(0.5, 0.3),
      const Offset(0.35, 0.6),
      const Offset(0.65, 0.55),
    ]) {
      canvas.drawCircle(Offset(size.width * o.dx, size.height * o.dy), 2, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
