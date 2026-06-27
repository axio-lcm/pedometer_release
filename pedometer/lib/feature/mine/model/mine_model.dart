import 'package:flutter/material.dart';
import 'package:pedometer/feature/mine/resources/mine_resource.dart';

/// 身体指标项：数值与单位分离，便于后续国际化；
/// [statusText] 非空时以状态胶囊（如 BMI「正常」）替代单位展示。
class BodyStat {
  final String iconAsset;
  final Color color;
  final String label;
  final String value;
  final String unit;
  final String? statusText;

  const BodyStat({
    required this.iconAsset,
    required this.color,
    required this.label,
    required this.value,
    this.unit = '',
    this.statusText,
  });
}

/// 设置入口项：[trailingText] 非空时（如版本号）展示右侧文字，否则展示箭头。
class MineEntry {
  final IconData icon;
  final Color color;
  final String title;
  final String? trailingText;

  const MineEntry({
    required this.icon,
    required this.color,
    required this.title,
    this.trailingText,
  });
}

/// 我的页展示数据。
class MinePageData {
  final List<BodyStat> bodyStats;
  final List<MineEntry> entries;

  const MinePageData({required this.bodyStats, required this.entries});

  // 颜色字面量与 AppColors fallback 一致，保证可 const 化。
  static const _green = Color(0xFF24F04E);
  static const _cyan = Color(0xFF0CD9FF);
  static const _purple = Color(0xFF7A3DFF);
  static const _orange = Color(0xFFFF9F12);
  static const _pink = Color(0xFFFF4770);
  static const _blue = Color(0xFF3D7CFF);

  static MinePageData localized({
    double height = 175,
    double weight = 68.0,
    int age = 28,
  }) {
    final bmiValue = weight / ((height / 100) * (height / 100));
    final bmiStr = bmiValue.toStringAsFixed(1);
    final bmiStatus = bmiValue < 18.5
        ? MineResource.bmiLow
        : bmiValue < 25
        ? MineResource.bmiNormal
        : bmiValue < 30
        ? MineResource.bmiHigh
        : MineResource.bmiObese;
    final weightStr = weight.toStringAsFixed(1);
    final heightStr =
        height == height.truncateToDouble()
            ? height.toInt().toString()
            : height.toStringAsFixed(1);
    return MinePageData(
      bodyStats: [
        BodyStat(
          iconAsset: 'assets/profile_height.svg',
          color: _cyan,
          label: MineResource.height,
          value: heightStr,
          unit: MineResource.heightUnit,
        ),
        BodyStat(
          iconAsset: 'assets/profile_weight.svg',
          color: _green,
          label: MineResource.weight,
          value: weightStr,
          unit: MineResource.weightUnit,
        ),
        BodyStat(
          iconAsset: 'assets/profile_bmi.svg',
          color: _purple,
          label: MineResource.bmi,
          value: bmiStr,
          statusText: bmiStatus,
        ),
        BodyStat(
          iconAsset: 'assets/profile_age.svg',
          color: _orange,
          label: MineResource.age,
          value: '$age',
          unit: MineResource.ageUnit,
        ),
      ],
      entries: [
        // 暂时隐藏主题设置入口，保留以便后续恢复。
        // MineEntry(
        //   icon: Icons.palette_rounded,
        //   color: _purple,
        //   title: MineResource.themeSetting,
        // ),
        MineEntry(
          icon: Icons.language_rounded,
          color: _blue,
          title: MineResource.language,
        ),
        MineEntry(
          icon: Icons.share_rounded,
          color: _pink,
          title: MineResource.shareApp,
        ),
        MineEntry(
          icon: Icons.star_rounded,
          color: _orange,
          title: MineResource.rateUs,
        ),
        MineEntry(
          icon: Icons.chat_bubble_outline_rounded,
          color: _cyan,
          title: MineResource.suggestion,
        ),
        MineEntry(
          icon: Icons.description_outlined,
          color: _green,
          title: MineResource.userAgreement,
        ),
        MineEntry(
          icon: Icons.verified_user_outlined,
          color: _blue,
          title: MineResource.privacyPolicy,
        ),
        MineEntry(
          icon: Icons.info_outline_rounded,
          color: _cyan,
          title: MineResource.version,
          trailingText: '1.0.0',
        ),
      ],
    );
  }

  static const mock = MinePageData(
    bodyStats: [
      BodyStat(
        iconAsset: 'assets/profile_height.svg',
        color: _cyan,
        label: MineText.height,
        value: '175',
        unit: MineText.heightUnit,
      ),
      BodyStat(
        iconAsset: 'assets/profile_weight.svg',
        color: _green,
        label: MineText.weight,
        value: '68.0',
        unit: MineText.weightUnit,
      ),
      BodyStat(
        iconAsset: 'assets/profile_bmi.svg',
        color: _purple,
        label: MineText.bmi,
        value: '22.2',
        statusText: MineText.bmiNormal,
      ),
      BodyStat(
        iconAsset: 'assets/profile_age.svg',
        color: _orange,
        label: MineText.age,
        value: '28',
        unit: MineText.ageUnit,
      ),
    ],
    entries: [
      // 暂时隐藏主题设置入口，保留以便后续恢复。
      // MineEntry(
      //   icon: Icons.palette_rounded,
      //   color: _purple,
      //   title: MineText.themeSetting,
      // ),
      MineEntry(
        icon: Icons.language_rounded,
        color: _blue,
        title: MineText.language,
      ),
      MineEntry(
        icon: Icons.share_rounded,
        color: _pink,
        title: MineText.shareApp,
      ),
      MineEntry(
        icon: Icons.star_rounded,
        color: _orange,
        title: MineText.rateUs,
      ),
      MineEntry(
        icon: Icons.chat_bubble_outline_rounded,
        color: _cyan,
        title: MineText.suggestion,
      ),
      MineEntry(
        icon: Icons.description_outlined,
        color: _green,
        title: MineText.userAgreement,
      ),
      MineEntry(
        icon: Icons.verified_user_outlined,
        color: _blue,
        title: MineText.privacyPolicy,
      ),
      MineEntry(
        icon: Icons.info_outline_rounded,
        color: _cyan,
        title: MineText.version,
        trailingText: '1.0.0',
      ),
    ],
  );
}
