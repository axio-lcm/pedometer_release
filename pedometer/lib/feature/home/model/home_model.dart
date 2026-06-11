import 'package:flutter/material.dart';

/// 主步数数据
class StepData {
  final int steps;
  final int goal;
  const StepData({required this.steps, required this.goal});

  /// 达成比例 0.0–1.0（封顶 1.0）
  double get progress => goal <= 0 ? 0 : (steps / goal).clamp(0.0, 1.0);

  /// 达成百分比整数
  int get percent => (progress * 100).round();
}

/// KPI 卡数据（距离 / 卡路里 / 活动时间）
class KpiItem {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String unit;
  const KpiItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.unit,
  });
}

/// 趋势图单个数据点
class TrendPoint {
  final String label;
  final double value;
  final bool highlight;
  const TrendPoint({
    required this.label,
    required this.value,
    this.highlight = false,
  });
}

/// 分析小卡数据
class AnalysisData {
  final String title;
  final String value;
  final String unit;
  final String delta;
  final Color color;
  final List<double> samples;
  const AnalysisData({
    required this.title,
    required this.value,
    required this.unit,
    required this.delta,
    required this.color,
    required this.samples,
  });
}
