import 'package:flutter/material.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/home/model/home_model.dart';

/// 右侧 KPI 卡：圆形玻璃底座图标 + 标题 + 大数字 + 单位。
/// 小屏下数字/单位用 FittedBox 缩放兜底，标题省略，保证不溢出。
class KpiCard extends StatelessWidget {
  final KpiItem item;
  const KpiCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.lg,
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 2),
                // 数字 + 单位：缩放兜底，永不溢出
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.value,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.unit,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
