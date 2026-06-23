import 'package:flutter/material.dart';
import 'package:pedometer/common/component/asset_metric_icon.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/home/components/sync_data_detail_components.dart';
import 'package:pedometer/feature/home/model/sync_data_detail_model.dart';

class SyncHistoryStatusHero extends StatelessWidget {
  final SyncHistoryDetailData data;

  const SyncHistoryStatusHero({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xxl),
      child: Column(
        children: [
          const GlowIconBox(icon: Icons.sync_rounded),
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
            data.time,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          SizedBox(height: AppSpacing.md),
          _ModePill(label: data.mode),
          SizedBox(height: AppSpacing.md),
          Text(
            data.result,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  final String label;

  const _ModePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 92),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.full),
        color: AppColors.brandGreenDark.withValues(alpha: 0.2),
        border: Border.all(color: AppColors.strokeGreen),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.brandGreen,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class CurrentSyncDataCard extends StatelessWidget {
  final List<SyncDataType> items;

  const CurrentSyncDataCard({super.key, required this.items});

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
          const SectionHeader(title: '本次同步数据'),
          SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < items.length; i++)
            SyncDataValueRow(
              data: items[i],
              showDivider: i != items.length - 1,
            ),
        ],
      ),
    );
  }
}

class SyncDataValueRow extends StatelessWidget {
  final SyncDataType data;
  final bool showDivider;

  const SyncDataValueRow({
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
                width: 30,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AppIconView(
                    icon: data.icon,
                    color: data.iconColor,
                    size: 22,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.xl),
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
              SizedBox(width: AppSpacing.lg),
              Flexible(
                child: Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsetsDirectional.only(start: 30 + AppSpacing.xl),
            child: Divider(height: 1, color: AppColors.divider),
          ),
      ],
    );
  }
}

class SourceAndMethodCard extends StatelessWidget {
  final List<SyncDataSource> sources;
  final List<SyncInfoItem> methodItems;

  const SourceAndMethodCard({
    super.key,
    required this.sources,
    required this.methodItems,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xxl,
      padding: EdgeInsets.all(AppSpacing.xxl),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              flex: 11,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeader(title: '数据来源'),
                  SizedBox(height: AppSpacing.xl),
                  for (var i = 0; i < sources.length; i++) ...[
                    DataSourceRow(data: sources[i]),
                    if (i != sources.length - 1)
                      SizedBox(height: AppSpacing.lg),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: VerticalDivider(color: AppColors.divider, width: 1),
            ),
            Expanded(
              flex: 8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < methodItems.length; i++) ...[
                    CompactInfoRow(item: methodItems[i]),
                    if (i != methodItems.length - 1)
                      SizedBox(height: AppSpacing.xl),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SyncInfoCard extends StatelessWidget {
  final List<SyncInfoItem> items;

  const SyncInfoCard({super.key, required this.items});

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
          const SectionHeader(title: '同步信息'),
          SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < items.length; i++)
            InfoRow(item: items[i], showDivider: i != items.length - 1),
        ],
      ),
    );
  }
}

class CompactInfoRow extends StatelessWidget {
  final SyncInfoItem item;

  const CompactInfoRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
          ),
        ),
      ],
    );
  }
}

class InfoRow extends StatelessWidget {
  final SyncInfoItem item;
  final bool showDivider;

  const InfoRow({super.key, required this.item, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 60,
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: item.icon == null
                    ? null
                    : AppIconView(
                        icon: item.icon!,
                        color: AppColors.brandGreen,
                        size: 36,
                      ),
              ),
              SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.lg),
              Flexible(
                flex: 2,
                child: Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: item.highlight
                        ? AppColors.brandGreen
                        : AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: item.highlight
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsetsDirectional.only(start: 36 + AppSpacing.xl),
            child: Divider(height: 1, color: AppColors.divider),
          ),
      ],
    );
  }
}
