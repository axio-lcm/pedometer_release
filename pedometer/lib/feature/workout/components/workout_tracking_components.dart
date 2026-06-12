import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/workout/model/workout_model.dart';
import 'package:pedometer/feature/workout/resources/workout_resource.dart';

/// 红框标准区域对应的地图容器：底层后续替换为真实地图，浮层保持不变。
class WorkoutMapSection extends StatelessWidget {
  final WorkoutTrackingData data;

  const WorkoutMapSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 386,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(child: WorkoutMapView()),
          const Positioned.fill(child: _MapDarkOverlay()),
          Positioned(
            top: 14,
            left: 0,
            right: 0,
            child: Center(
              child: GpsStatusPill(
                label: data.gpsLabel,
                status: data.gpsStatus,
              ),
            ),
          ),
          const Positioned.fill(child: RoutePolylineLayer()),
          if (data.status != WorkoutStatus.ended)
            _AnimatedDistanceOverlayAnchor(data: data),
          if (data.status == WorkoutStatus.ended)
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
              child: WorkoutEndedMapSummary(data: data),
            ),
          const Positioned(left: 14, bottom: 14, child: MapControlButtons()),
        ],
      ),
    );
  }
}

/// TODO: 接入真实地图 SDK 后，仅替换此组件内部实现。
class WorkoutMapView extends StatelessWidget {
  const WorkoutMapView({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bgPrimary,
            AppColors.bgRadialBlue.withValues(alpha: 0.82),
            AppColors.bgPrimary,
          ],
        ),
      ),
      child: CustomPaint(painter: _MapPlaceholderPainter()),
    );
  }
}

class _MapDarkOverlay extends StatelessWidget {
  const _MapDarkOverlay();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.05),
          radius: 0.82,
          colors: [
            Colors.transparent,
            AppColors.bgPrimary.withValues(alpha: 0.42),
            AppColors.bgPrimary.withValues(alpha: 0.82),
          ],
          stops: const [0, 0.56, 1],
        ),
      ),
    );
  }
}

class GpsStatusPill extends StatelessWidget {
  final String label;
  final String status;

  const GpsStatusPill({super.key, required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.strokeGreen),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandGreen.withValues(alpha: 0.16),
            blurRadius: 18,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_outlined,
            color: AppColors.brandGreen,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          _SignalDot(color: AppColors.brandGreen),
          const SizedBox(width: 4),
          _SignalDot(color: AppColors.brandGreen),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SignalDot extends StatelessWidget {
  final Color color;

  const _SignalDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class RoutePolylineLayer extends StatelessWidget {
  const RoutePolylineLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _RoutePainter());
  }
}

class _AnimatedDistanceOverlayAnchor extends StatelessWidget {
  final WorkoutTrackingData data;

  const _AnimatedDistanceOverlayAnchor({required this.data});

  static const _duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final compact = data.status == WorkoutStatus.running;
    return AnimatedPositioned(
      duration: _duration,
      curve: Curves.easeOutCubic,
      top: compact ? 360 : 96,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedScale(
          duration: _duration,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          scale: compact ? 0.96 : 1,
          child: WorkoutDistanceOverlay(data: data, compact: compact),
        ),
      ),
    );
  }
}

class WorkoutDistanceOverlay extends StatelessWidget {
  final WorkoutTrackingData data;
  final bool compact;

  const WorkoutDistanceOverlay({
    super.key,
    required this.data,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      const compactFontSize = 15.0;
      const compactValueFontSize = 25.0;
      return SizedBox(
        width: 330,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                WorkoutResource.trackingDistanceLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: compactFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              data.distanceKm,
              maxLines: 1,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: compactValueFontSize,
                height: 1,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.85),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      WorkoutResource.trackingTarget(data.targetKm),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: compactFontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.edit_outlined,
                    color: AppColors.brandLime,
                    size: 15,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: 190,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            WorkoutResource.trackingDistanceLabel,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              data.distanceKm,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 78,
                height: 0.98,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.85),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  WorkoutResource.trackingTarget(data.targetKm),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.edit_outlined, color: AppColors.brandLime, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}

class WorkoutEndedMapSummary extends StatelessWidget {
  final WorkoutTrackingData data;

  const WorkoutEndedMapSummary({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.lg,
      padding: EdgeInsets.all(AppSpacing.lg),
      borderColor: AppColors.strokeGreen,
      child: Row(
        children: [
          Expanded(
            child: _EndedMetric(
              label: WorkoutResource.metricDistance,
              value: data.distanceKm,
            ),
          ),
          Expanded(
            child: _EndedMetric(
              label: WorkoutResource.metricDuration,
              value: data.duration,
            ),
          ),
          Expanded(
            child: _EndedMetric(
              label: WorkoutResource.metricPace,
              value: data.pace,
            ),
          ),
        ],
      ),
    );
  }
}

class _EndedMetric extends StatelessWidget {
  final String label;
  final String value;

  const _EndedMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class MapControlButtons extends StatelessWidget {
  const MapControlButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleGlassIconButton(icon: Icons.my_location_rounded, onTap: () {}),
        const SizedBox(height: 14),
        CircleGlassIconButton(icon: Icons.map_outlined, onTap: () {}),
      ],
    );
  }
}

class WorkoutMetricPanel extends StatelessWidget {
  final WorkoutTrackingData data;

  const WorkoutMetricPanel({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xl,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: WorkoutMetricItem(
              icon: Icons.schedule_rounded,
              iconColor: AppColors.brandGreen,
              label: WorkoutResource.metricDuration,
              value: data.duration,
            ),
          ),
          _MetricDivider(),
          Expanded(
            child: WorkoutMetricItem(
              icon: Icons.local_fire_department_rounded,
              iconColor: AppColors.accentOrange,
              label: WorkoutResource.metricCalorieKcal,
              value: data.calories,
            ),
          ),
          _MetricDivider(),
          Expanded(
            child: WorkoutMetricItem(
              icon: Icons.speed_rounded,
              iconColor: AppColors.accentCyan,
              label: WorkoutResource.metricPaceMinKm,
              value: data.pace,
            ),
          ),
        ],
      ),
    );
  }
}

class WorkoutMetricItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const WorkoutMetricItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 21),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 44, color: AppColors.divider);
  }
}

class WorkoutControlPanel extends StatelessWidget {
  final WorkoutTrackingData data;
  final VoidCallback? onPrimaryTap;

  const WorkoutControlPanel({super.key, required this.data, this.onPrimaryTap});

  @override
  Widget build(BuildContext context) {
    final hintText = switch (data.status) {
      WorkoutStatus.ready => WorkoutResource.trackingStartHint,
      WorkoutStatus.running => data.endHint,
      WorkoutStatus.paused => data.endHint,
      WorkoutStatus.ended => null,
    };
    return SizedBox(
      height: 108,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CircleGlassIconButton(icon: Icons.lock_rounded, onTap: () {}),
                NeonPauseButton(
                  showStartIcon: data.status != WorkoutStatus.running,
                  onTap: onPrimaryTap,
                ),
                CircleGlassIconButton(
                  icon: Icons.volume_up_rounded,
                  onTap: () {},
                ),
              ],
            ),
          ),
          if (hintText != null)
            Positioned(
              top: 112,
              left: 0,
              right: 0,
              child: Text(
                hintText,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

class CircleGlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  const CircleGlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 56,
    this.iconSize = 27,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.surfaceCardTop, AppColors.surfaceCardBottom],
          ),
          border: Border.all(color: AppColors.strokeCard),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.36),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: iconSize),
      ),
    );
  }
}

class NeonPauseButton extends StatelessWidget {
  final bool showStartIcon;
  final VoidCallback? onTap;

  const NeonPauseButton({super.key, required this.showStartIcon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 108,
        height: 108,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.brandLime,
              AppColors.brandGreen,
              AppColors.brandGreenDark,
            ],
            stops: const [0, 0.62, 1],
          ),
        ),
        child: Icon(
          showStartIcon ? Icons.play_arrow_rounded : Icons.pause_rounded,
          color: AppColors.bgPrimary,
          size: 56,
        ),
      ),
    );
  }
}

class WorkoutMusicCard extends StatelessWidget {
  final WorkoutTrackingData data;

  const WorkoutMusicCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.lg,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              color: AppColors.brandGreen.withValues(alpha: 0.18),
            ),
            child: Icon(
              Icons.music_note_rounded,
              color: AppColors.brandLime,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.musicTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.musicStatus,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.play_arrow_rounded,
              color: AppColors.brandGreen,
              size: 34,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.skip_next_rounded,
              color: AppColors.brandGreen,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = AppColors.gridLine.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final blockPaint = Paint()
      ..color = AppColors.brandGreenDark.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 9; i++) {
      final y = size.height * (0.16 + i * 0.095);
      final path = Path()
        ..moveTo(-20, y)
        ..quadraticBezierTo(
          size.width * 0.28,
          y - 22,
          size.width * 0.54,
          y + 12,
        )
        ..quadraticBezierTo(size.width * 0.78, y + 34, size.width + 20, y - 14);
      canvas.drawPath(path, roadPaint);
    }

    for (var i = 0; i < 7; i++) {
      final x = size.width * (0.08 + i * 0.14);
      final path = Path()
        ..moveTo(x, 0)
        ..quadraticBezierTo(x + 28, size.height * 0.38, x - 18, size.height)
        ..moveTo(x + 48, 0)
        ..quadraticBezierTo(x + 20, size.height * 0.5, x + 64, size.height);
      canvas.drawPath(path, roadPaint);
    }

    for (var i = 0; i < 12; i++) {
      final left = size.width * ((i * 37 % 100) / 100);
      final top = size.height * ((i * 23 % 92) / 100);
      final rect = Rect.fromLTWH(
        left,
        top,
        30 + (i % 3) * 14,
        20 + (i % 2) * 18,
      );
      canvas.save();
      canvas.rotate((i.isEven ? 1 : -1) * math.pi / 90);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        blockPaint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final route = Path()
      ..moveTo(size.width * 0.29, size.height * 0.62)
      ..cubicTo(
        size.width * 0.42,
        size.height * 0.58,
        size.width * 0.44,
        size.height * 0.48,
        size.width * 0.56,
        size.height * 0.46,
      )
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.44,
        size.width * 0.68,
        size.height * 0.54,
        size.width * 0.80,
        size.height * 0.45,
      );

    final glowPaint = Paint()
      ..color = AppColors.brandGreen.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final basePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.accentOrange,
          AppColors.brandGreenLight,
          AppColors.brandGreen,
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(route, glowPaint);
    canvas.drawPath(route, basePaint);
    _drawPoint(
      canvas,
      Offset(size.width * 0.29, size.height * 0.62),
      AppColors.accentOrange,
      8,
    );
    _drawPoint(
      canvas,
      Offset(size.width * 0.80, size.height * 0.45),
      AppColors.brandGreen,
      10,
    );
  }

  void _drawPoint(Canvas canvas, Offset center, Color color, double radius) {
    final glow = Paint()
      ..color = color.withValues(alpha: 0.34)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final fill = Paint()..color = color;
    final inner = Paint()..color = AppColors.textPrimary.withValues(alpha: 0.8);
    canvas.drawCircle(center, radius + 12, glow);
    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(center, radius * 0.46, inner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
