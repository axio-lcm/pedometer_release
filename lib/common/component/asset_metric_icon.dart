import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pedometer/common/config/app_icon_source.dart';

class AssetMetricIcon extends StatelessWidget {
  final String assetName;
  final double size;

  const AssetMetricIcon({
    super.key,
    required this.assetName,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetName,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

class AppIconView extends StatelessWidget {
  final AppIconSource icon;
  final Color color;
  final double size;

  const AppIconView({
    super.key,
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return switch (icon) {
      AssetAppIcon(:final assetName) => AssetMetricIcon(
        assetName: assetName,
        size: size,
      ),
      MaterialAppIcon(:final icon) => Icon(icon, color: color, size: size),
    };
  }
}
