import 'package:flutter/material.dart';
import 'package:pedometer/common/component/asset_metric_icon.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/mine/model/mine_model.dart';
import 'package:pedometer/feature/mine/resources/mine_resource.dart';

/// 身体指标总览卡片：身高 / 体重 / BMI / 年龄 四列等宽展示。
class BodyStatsCard extends StatelessWidget {
  final List<BodyStat> stats;

  const BodyStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xxl,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  MineResource.bodyData,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const _BodyEditButton(),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                Expanded(child: BodyStatItem(stat: stats[i])),
                if (i != stats.length - 1)
                  SizedBox(
                    height: 126,
                    child: VerticalDivider(width: 1, color: AppColors.divider),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _BodyEditButton extends StatelessWidget {
  const _BodyEditButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        color: AppColors.brandGreenDark.withValues(alpha: 0.28),
        border: Border.all(color: AppColors.strokeGreen),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_outlined, color: AppColors.brandGreen, size: 15),
          SizedBox(width: AppSpacing.xxs),
          Text(
            MineResource.editBodyData,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.brandGreen,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// 单列身体指标：功能色图标 + 标签 + 大号白色数值 + 单位 / 状态胶囊。
class BodyStatItem extends StatelessWidget {
  final BodyStat stat;

  const BodyStatItem({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AssetMetricIcon(assetName: stat.iconAsset, size: 40),
        SizedBox(height: AppSpacing.md),
        Text(
          stat.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
        SizedBox(height: AppSpacing.sm),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            stat.value,
            maxLines: 1,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        if (stat.statusText != null)
          _StatusPill(text: stat.statusText!)
        else
          Text(
            stat.unit,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
      ],
    );
  }
}

/// 状态胶囊（如 BMI「正常」）：深绿底 + 霓虹绿文字。
class _StatusPill extends StatelessWidget {
  final String text;

  const _StatusPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xs),
        color: AppColors.brandGreenDark.withValues(alpha: 0.65),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.brandGreen,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 订阅会员横幅：绿色胶囊入口 + 皇冠图标 + 右侧圆形箭头。
class MembershipSubscriptionCard extends StatelessWidget {
  final VoidCallback? onTap;

  const MembershipSubscriptionCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 78,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF43F21A), Color(0xFF91FF00)],
          ),
        ),
        child: Row(
          children: [
            AssetMetricIcon(
              assetName: MineResource.membershipCrownIcon,
              size: 32,
            ),
            SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    MineResource.subscribeTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF07130A),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    MineResource.subscribeSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xCC07130A),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.md),
            AssetMetricIcon(
              assetName: MineResource.membershipArrowIcon,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

/// 设置入口分组卡片：玻璃卡片内纵向排列入口行，行间细分割线。
class MineSettingsCard extends StatelessWidget {
  final List<MineEntry> entries;

  /// [origin] 为被点击行在屏幕上的矩形，供 iOS 分享面板等定位锚点。
  final void Function(MineEntry entry, Rect origin)? onEntryTap;

  const MineSettingsCard({super.key, required this.entries, this.onEntryTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xxl,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            MineEntryRow(
              entry: entries[i],
              showDivider: i != entries.length - 1,
              onTap: onEntryTap == null
                  ? null
                  : (origin) => onEntryTap!(entries[i], origin),
            ),
        ],
      ),
    );
  }
}

/// 单个设置入口行：圆角玻璃底座图标 + 标题 + 右侧箭头 / 文字。
class MineEntryRow extends StatelessWidget {
  final MineEntry entry;
  final bool showDivider;

  /// 回调携带该行在屏幕上的矩形（供分享面板等锚点定位）。
  final ValueChanged<Rect>? onTap;

  static const double _iconBaseSize = 40;

  const MineEntryRow({
    super.key,
    required this.entry,
    required this.showDivider,
    this.onTap,
  });

  /// 计算当前行在屏幕坐标系中的矩形。
  Rect _resolveOrigin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return Rect.zero;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap == null ? null : () => onTap!(_resolveOrigin(context)),
          child: SizedBox(
            height: 66,
            child: Row(
              children: [
                Container(
                  width: _iconBaseSize,
                  height: _iconBaseSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    color: entry.color.withValues(alpha: 0.16),
                  ),
                  child: Icon(entry.icon, color: entry.color, size: 22),
                ),
                SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                if (entry.trailingText != null)
                  Text(
                    entry.trailingText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: _iconBaseSize + AppSpacing.lg,
            ),
            child: Divider(height: 1, color: AppColors.divider),
          ),
      ],
    );
  }
}
