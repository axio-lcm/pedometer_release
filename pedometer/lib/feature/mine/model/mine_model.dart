import 'package:flutter/material.dart';
import 'package:pedometer/feature/mine/resources/mine_resource.dart';

/// 身体指标项：数值与单位分离，便于后续国际化；
/// [statusText] 非空时以状态胶囊（如 BMI「正常」）替代单位展示。
class BodyStat {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String unit;
  final String? statusText;

  const BodyStat({
    required this.icon,
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

  static const mock = MinePageData(
    bodyStats: [
      // TODO: 图标为占位，后续可替换为设计稿同款图标资源。
      BodyStat(
        icon: Icons.height_rounded,
        color: _cyan,
        label: MineText.height,
        value: '175',
        unit: MineText.heightUnit,
      ),
      BodyStat(
        icon: Icons.monitor_weight_outlined,
        color: _green,
        label: MineText.weight,
        value: '68.0',
        unit: MineText.weightUnit,
      ),
      BodyStat(
        icon: Icons.data_usage_rounded,
        color: _purple,
        label: MineText.bmi,
        value: '22.2',
        statusText: MineText.bmiNormal,
      ),
      BodyStat(
        icon: Icons.calendar_month_rounded,
        color: _orange,
        label: MineText.age,
        value: '28',
        unit: MineText.ageUnit,
      ),
    ],
    entries: [
      MineEntry(
        icon: Icons.palette_rounded,
        color: _purple,
        title: MineText.themeSetting,
      ),
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
