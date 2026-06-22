import 'package:flutter/material.dart';

sealed class AppIconSource {
  const AppIconSource();
}

class AssetAppIcon extends AppIconSource {
  final String assetName;

  const AssetAppIcon(this.assetName);
}

class MaterialAppIcon extends AppIconSource {
  final IconData icon;

  const MaterialAppIcon(this.icon);
}
