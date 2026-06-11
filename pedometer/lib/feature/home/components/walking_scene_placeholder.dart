import 'package:flutter/material.dart';
import 'package:pedometer/common/config/app_colors.dart';

/// 夜间森林步行场景占位：轻量绘制道路弧线 + 树剪影 + 光点。
/// TODO: 替换为真实 3D 步行人物 / 森林道路资源。
/// 建议资源路径：assets/images/home_walking_scene.png
class WalkingScenePlaceholder extends StatelessWidget {
  final double height;
  const WalkingScenePlaceholder({super.key, this.height = 90});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _ScenePainter()),
    );
  }
}

class _ScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 道路弧线
    final road = Path()
      ..moveTo(size.width * 0.30, size.height)
      ..quadraticBezierTo(
          size.width * 0.5, size.height * 0.45, size.width * 0.70, size.height);
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
    final tree = Paint()..color = AppColors.brandGreenDark.withValues(alpha: 0.7);
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
      canvas.drawCircle(
          Offset(size.width * o.dx, size.height * o.dy), 2, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
