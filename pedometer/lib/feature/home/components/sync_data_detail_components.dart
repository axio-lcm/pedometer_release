import 'package:flutter/material.dart';
import 'package:pedometer/common/component/asset_metric_icon.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/home/model/sync_data_detail_model.dart';

class SyncStatusHero extends StatelessWidget {
  final SyncDataDetailData data;

  const SyncStatusHero({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xxl),
      child: Column(
        children: [
          GlowIconBox(icon: Icons.sync_rounded),
          SizedBox(height: AppSpacing.lg),
          Text(
            data.statusTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.brandGreen,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            data.lastSyncText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class GlowIconBox extends StatelessWidget {
  final IconData icon;

  const GlowIconBox({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandGreen.withValues(alpha: 0.24),
            AppColors.brandGreenDark.withValues(alpha: 0.34),
          ],
        ),
        border: Border.all(color: AppColors.strokeGreen),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandGreen.withValues(alpha: 0.46),
            blurRadius: 42,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, color: AppColors.brandGreenLight, size: 46),
    );
  }
}

class SyncOverviewCard extends StatelessWidget {
  final List<SyncDataSource> sources;
  final ValueChanged<SyncDataSource>? onSourceView;

  const SyncOverviewCard({super.key, required this.sources, this.onSourceView});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xxl,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xl,
      ),
      child: _SourceColumn(sources: sources, onSourceView: onSourceView),
    );
  }
}

class _SourceColumn extends StatelessWidget {
  final List<SyncDataSource> sources;
  final ValueChanged<SyncDataSource>? onSourceView;

  const _SourceColumn({required this.sources, this.onSourceView});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: '数据来源'),
        SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < sources.length; i++) ...[
          DataSourceRow(
            data: sources[i],
            onView: onSourceView == null
                ? null
                : () => onSourceView!(sources[i]),
          ),
          if (i != sources.length - 1) SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing != null) ...[SizedBox(width: AppSpacing.sm), trailing!],
      ],
    );
  }
}

class DataSourceRow extends StatelessWidget {
  final SyncDataSource data;
  final VoidCallback? onView;

  const DataSourceRow({super.key, required this.data, this.onView});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SyncSourceIcon(data: data),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: AppSpacing.xxs),
              Text(
                data.status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
        if (onView != null) ...[
          SizedBox(width: AppSpacing.sm),
          DataSourceViewButton(onTap: onView),
        ],
      ],
    );
  }
}

class DataSourceViewButton extends StatelessWidget {
  final VoidCallback? onTap;

  const DataSourceViewButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.bgPrimary.withValues(alpha: 0.36),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.strokeCard),
        ),
        child: Text(
          '查看',
          maxLines: 1,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class SyncSourceIcon extends StatelessWidget {
  final SyncDataSource data;
  final double size;
  final double iconSize;

  const SyncSourceIcon({
    super.key,
    required this.data,
    this.size = 52,
    this.iconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.12),
            blurRadius: 14,
          ),
        ],
      ),
      // TODO: 替换为 Apple Health / Health Connect 官方图标资源。
      child: Icon(data.icon, color: data.iconColor, size: iconSize),
    );
  }
}

class MetricText extends StatelessWidget {
  final SyncMetric metric;

  const MetricText({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            metric.value,
            maxLines: 1,
            style: TextStyle(
              color: AppColors.brandGreen,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
        ),
        Text(
          metric.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}

class DataTypeCard extends StatelessWidget {
  final List<SyncDataType> items;

  const DataTypeCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xxl,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.lg,
      ),
      child: Column(
        children: [
          SectionHeader(
            title: '数据类型',
            trailing: _HeaderAction(
              label: '近 7 天数据',
              icon: Icons.keyboard_arrow_down_rounded,
              enclosedIcon: true,
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          for (var i = 0; i < items.length; i++)
            DataTypeListItem(
              data: items[i],
              showDivider: i != items.length - 1,
            ),
        ],
      ),
    );
  }
}

class DataTypeListItem extends StatelessWidget {
  final SyncDataType data;
  final bool showDivider;

  static const double _iconColumnWidth = 36;
  static const double _titleGap = 16;
  static const double _titleValueGap = 18;
  static const double _valueColumnWidth = 76;
  static const double _checkGap = 16;
  static const double _checkColumnWidth = 26;

  const DataTypeListItem({
    super.key,
    required this.data,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 60,
          child: Row(
            children: [
              SizedBox(
                width: _iconColumnWidth,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AppIconView(
                    icon: data.icon,
                    color: data.iconColor,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(width: _titleGap),
              Expanded(
                child: Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: _titleValueGap),
              SizedBox(
                width: _valueColumnWidth,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    data.value,
                    maxLines: 1,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: _checkGap),
              const SizedBox(
                width: _checkColumnWidth,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: SuccessCheckIcon(size: 26),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: _iconColumnWidth + _titleGap,
            ),
            child: Divider(height: 1, color: AppColors.divider),
          ),
      ],
    );
  }
}

class SyncHistoryCard extends StatelessWidget {
  final List<SyncHistoryRecord> histories;
  final ValueChanged<SyncHistoryRecord>? onHistoryTap;
  final VoidCallback? onViewAll;

  const SyncHistoryCard({
    super.key,
    required this.histories,
    this.onHistoryTap,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xxl,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.lg,
      ),
      child: Column(
        children: [
          SectionHeader(
            title: '同步历史',
            trailing: _HeaderAction(
              label: '查看全部',
              icon: Icons.chevron_right_rounded,
              enclosedIcon: true,
              onTap: onViewAll,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          if (histories.isEmpty)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                '暂无同步记录',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
            )
          else
            for (var i = 0; i < histories.length; i++)
              SyncHistoryItem(
                data: histories[i],
                showDivider: i != histories.length - 1,
                showResult: false,
                onTap: onHistoryTap == null
                    ? null
                    : () => onHistoryTap!(histories[i]),
              ),
        ],
      ),
    );
  }
}

class SyncHistoryItem extends StatelessWidget {
  final SyncHistoryRecord data;
  final bool showDivider;
  final VoidCallback? onTap;

  /// 是否展示右侧「成功同步 N 项数据」结果文案。
  final bool showResult;

  const SyncHistoryItem({
    super.key,
    required this.data,
    required this.showDivider,
    this.onTap,
    this.showResult = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            height: 74,
            child: Row(
              children: [
                const SuccessCheckIcon(size: 36, outlined: true),
                SizedBox(width: AppSpacing.lg),
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.time,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xxs),
                      Text(
                        data.mode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showResult) ...[
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 4,
                    child: Text(
                      data.result,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
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
            padding: EdgeInsetsDirectional.only(start: 48 + AppSpacing.lg),
            child: Divider(height: 1, color: AppColors.divider),
          ),
      ],
    );
  }
}

/// 同步历史「查看全部」列表卡片：复用同步历史行，沿用默认卡片边框样式。
class SyncHistoryListCard extends StatelessWidget {
  final List<SyncHistoryRecord> records;
  final ValueChanged<SyncHistoryRecord>? onRecordTap;

  const SyncHistoryListCard({
    super.key,
    required this.records,
    this.onRecordTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xxl,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          if (records.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                '暂无同步记录',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            for (var i = 0; i < records.length; i++)
              SyncHistoryItem(
                data: records[i],
                showDivider: i != records.length - 1,
                onTap: onRecordTap == null
                    ? null
                    : () => onRecordTap!(records[i]),
              ),
        ],
      ),
    );
  }
}

class DataSecurityFooter extends StatelessWidget {
  final String text;

  const DataSecurityFooter({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: AppColors.brandGreen,
            size: 22,
          ),
          SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class SuccessCheckIcon extends StatelessWidget {
  final double size;
  final bool outlined;

  const SuccessCheckIcon({
    super.key,
    required this.size,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: outlined ? Colors.transparent : AppColors.statusSuccess,
        border: outlined ? Border.all(color: AppColors.brandGreen) : null,
      ),
      child: Icon(
        Icons.check_rounded,
        color: outlined ? AppColors.brandGreen : AppColors.bgPrimary,
        size: size * 0.66,
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enclosedIcon;
  final VoidCallback? onTap;

  const _HeaderAction({
    required this.label,
    required this.icon,
    this.enclosedIcon = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = enclosedIcon
        ? Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.strokeCard),
              color: AppColors.surfaceIcon.withValues(alpha: 0.45),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          )
        : Icon(icon, color: AppColors.textSecondary, size: 20);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 118),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(width: AppSpacing.xs),
        iconWidget,
      ],
    );

    if (onTap == null) return content;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: content,
    );
  }
}
