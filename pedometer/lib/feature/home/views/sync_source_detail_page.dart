import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/home/components/sync_data_detail_components.dart';
import 'package:pedometer/feature/home/model/sync_data_detail_model.dart';
import 'package:pedometer/feature/home/resources/home_resource.dart';

/// 单个健康数据来源的连接与同步设置页。
class SyncSourceDetailPage extends StatefulWidget {
  static const String routeName = HomeRouteTable.pathSyncSourceDetail;

  final SyncDataSource? source;

  const SyncSourceDetailPage({super.key, this.source});

  @override
  State<SyncSourceDetailPage> createState() => _SyncSourceDetailPageState();
}

class _SyncSourceDetailPageState extends State<SyncSourceDetailPage> {
  late final SyncSourceDetailData data;
  late int _selectedModeIndex;
  late List<bool> _manualSelections;

  bool get _isManualSyncSelected =>
      data.modeOptions[_selectedModeIndex].title == '手动同步';

  List<ManualSyncSelectionItem> get _manualItems {
    return [
      for (var i = 0; i < data.manualItems.length; i++)
        ManualSyncSelectionItem(
          title: data.manualItems[i].title,
          selected: _manualSelections[i],
        ),
    ];
  }

  @override
  void initState() {
    super.initState();
    data = SyncSourceDetailData.forSource(_resolveSource());
    final selectedIndex = data.modeOptions.indexWhere(
      (option) => option.selected,
    );
    _selectedModeIndex = selectedIndex == -1 ? 0 : selectedIndex;
    _manualSelections = [for (final item in data.manualItems) item.selected];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeResource.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _SyncSourceDetailBackground()),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTopNavigationBar(
                    title: data.source.title,
                    onBack: () {
                      if (Get.key.currentState?.canPop() ?? false) {
                        Get.back<void>();
                      }
                    },
                  ),
                  SizedBox(height: AppSpacing.md),
                  _SourceConnectionCard(data: data),
                  SizedBox(height: AppSpacing.lg),
                  _PermissionCard(items: data.permissions),
                  SizedBox(height: AppSpacing.lg),
                  _SyncModeCard(
                    options: data.modeOptions,
                    selectedIndex: _selectedModeIndex,
                    onChanged: _selectSyncMode,
                  ),
                  if (_isManualSyncSelected) ...[
                    SizedBox(height: AppSpacing.lg),
                    _ManualSelectionCard(
                      items: _manualItems,
                      onItemTap: _toggleManualSelection,
                    ),
                  ],
                  SizedBox(height: AppSpacing.xl),
                  const _SourceActionBar(),
                  SizedBox(height: AppSpacing.lg),
                  DataSecurityFooter(text: data.safetyText),
                  SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  SyncDataSource _resolveSource() {
    final argument = Get.arguments;
    if (widget.source != null) return widget.source!;
    if (argument is SyncDataSource) return argument;
    return SyncDataDetailData.mock.sources.first;
  }

  void _selectSyncMode(int index) {
    setState(() {
      _selectedModeIndex = index;
    });
  }

  void _toggleManualSelection(int index) {
    setState(() {
      _manualSelections[index] = !_manualSelections[index];
    });
  }
}

class _SyncSourceDetailBackground extends StatelessWidget {
  const _SyncSourceDetailBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bgPrimary,
            AppColors.bgRadialBlue,
            AppColors.bgPrimary,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 120,
            left: -80,
            right: -80,
            height: 360,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.bgRadialGreen.withValues(alpha: 0.46),
                    AppColors.bgRadialBlue.withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -110,
            right: -110,
            height: 360,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.brandGreenDark.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceConnectionCard extends StatelessWidget {
  final SyncSourceDetailData data;

  const _SourceConnectionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xxl,
      glow: true,
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          SyncSourceIcon(data: data.source, size: 60, iconSize: 32),
          SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '已连接 ${data.source.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.brandGreen,
                      size: 19,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      '连接成功',
                      style: TextStyle(
                        color: AppColors.brandGreen,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  '管理同步权限与同步方式',
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
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final List<SyncSourcePermission> items;

  const _PermissionCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xxl,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Health 同步权限'),
          SizedBox(height: AppSpacing.md),
          for (var i = 0; i < items.length; i++) ...[
            _PermissionRow(item: items[i]),
            if (i != items.length - 1)
              Divider(color: AppColors.divider, height: AppSpacing.lg),
          ],
          SizedBox(height: AppSpacing.sm),
          Text(
            '需授权后才可同步对应健康数据',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final SyncSourcePermission item;

  const _PermissionRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Icon(item.icon, color: item.iconColor, size: 24),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const _GreenSwitch(value: true),
        ],
      ),
    );
  }
}

class _GreenSwitch extends StatelessWidget {
  final bool value;

  const _GreenSwitch({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 26,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.full),
        color: value
            ? AppColors.brandGreen.withValues(alpha: 0.88)
            : AppColors.strokeCard,
        boxShadow: value
            ? [
                BoxShadow(
                  color: AppColors.brandGreen.withValues(alpha: 0.28),
                  blurRadius: 16,
                ),
              ]
            : null,
      ),
      child: Align(
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _SyncModeCard extends StatelessWidget {
  final List<SyncModeOption> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SyncModeCard({
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xxl,
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: '同步方式'),
          SizedBox(height: AppSpacing.md),
          for (var i = 0; i < options.length; i++) ...[
            _SyncModeOptionTile(
              option: options[i],
              selected: selectedIndex == i,
              onTap: () => onChanged(i),
            ),
            if (i != options.length - 1) SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _SyncModeOptionTile extends StatelessWidget {
  final SyncModeOption option;
  final bool selected;
  final VoidCallback onTap;

  const _SyncModeOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.brandGreen : AppColors.strokeCard;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.brandGreenDark.withValues(alpha: 0.16)
              : AppColors.bgPrimary.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            _RadioIndicator(selected: selected),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    option.subtitle,
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
          ],
        ),
      ),
    );
  }
}

class _RadioIndicator extends StatelessWidget {
  final bool selected;

  const _RadioIndicator({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.brandGreen : AppColors.textSecondary,
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.brandGreen,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}

class _ManualSelectionCard extends StatelessWidget {
  final List<ManualSyncSelectionItem> items;
  final ValueChanged<int> onItemTap;

  const _ManualSelectionCard({required this.items, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xxl,
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: '手动同步数据选择'),
          SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (var i = 0; i < items.length; i++)
                _ManualSyncChip(item: items[i], onTap: () => onItemTap(i)),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            '手动同步时，仅同步已勾选项目',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ManualSyncChip extends StatelessWidget {
  final ManualSyncSelectionItem item;
  final VoidCallback onTap;

  const _ManualSyncChip({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: item.selected
              ? AppColors.brandGreenDark.withValues(alpha: 0.2)
              : AppColors.bgPrimary.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: item.selected ? AppColors.brandGreen : AppColors.strokeCard,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.selected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: item.selected
                  ? AppColors.brandGreen
                  : AppColors.textSecondary,
              size: 19,
            ),
            SizedBox(width: AppSpacing.sm),
            Text(
              item.title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceActionBar extends StatelessWidget {
  const _SourceActionBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: '断开连接',
            foreground: AppColors.brandGreen,
            background: AppColors.bgPrimary.withValues(alpha: 0.42),
            borderColor: AppColors.strokeCard,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ActionButton(
            label: '保存设置',
            foreground: AppColors.bgPrimary,
            background: AppColors.brandGreen,
            borderColor: AppColors.brandGreen,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color foreground;
  final Color background;
  final Color borderColor;

  const _ActionButton({
    required this.label,
    required this.foreground,
    required this.background,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: background.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
