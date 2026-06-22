import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/component/asset_metric_icon.dart';
import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/home/components/sync_data_detail_components.dart';
import 'package:pedometer/feature/home/model/health_sync_models.dart';
import 'package:pedometer/feature/home/model/sync_data_detail_model.dart';
import 'package:pedometer/feature/home/resources/home_resource.dart';
import 'package:pedometer/feature/home/viewmodel/sync_source_detail_view_model.dart';

/// 单个健康数据来源的连接与同步设置页。
class SyncSourceDetailPage extends GetView<SyncSourceDetailViewModel> {
  static const String routeName = HomeRouteTable.pathSyncSourceDetail;

  final SyncDataSource? source;

  const SyncSourceDetailPage({super.key, this.source});

  @override
  Widget build(BuildContext context) {
    final source = this.source;
    if (source != null) {
      controller.useSource(source);
    }

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
              child: Obx(() {
                final data = controller.data.value;
                final message = controller.syncMessage.value;
                final authStatus = controller.authStatus.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTopNavigationBar(
                      title: data.source.title,
                      onBack: _back,
                    ),
                    SizedBox(height: AppSpacing.md),
                    _SourceConnectionCard(data: data, status: authStatus),
                    SizedBox(height: AppSpacing.lg),
                    _PermissionCard(
                      items: data.permissions,
                      statusText: controller.permissionStatus.value,
                      authorized: controller.isConnected,
                    ),
                    SizedBox(height: AppSpacing.lg),
                    _SyncModeCard(
                      options: data.modeOptions,
                      selectedIndex: controller.selectedModeIndex.value,
                      onChanged: controller.selectSyncMode,
                    ),
                    if (controller.isManualSyncSelected) ...[
                      SizedBox(height: AppSpacing.lg),
                      _ManualSelectionCard(
                        items: controller.manualItems,
                        onItemTap: controller.toggleManualSelection,
                      ),
                    ],
                    SizedBox(height: AppSpacing.xl),
                    if (message != null) ...[
                      _SyncResultBanner(
                        message: message,
                        succeeded: controller.syncSucceeded.value,
                      ),
                      SizedBox(height: AppSpacing.md),
                    ],
                    _SourceActionBar(
                      syncing: controller.syncing.value,
                      onSave: controller.syncHealthData,
                      onDisconnect: () =>
                          _confirmDisconnect(context, data.source.title),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    DataSecurityFooter(text: data.safetyText),
                    SizedBox(height: AppSpacing.xxl),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _back() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back<void>();
    }
  }

  /// 「断开连接」引导弹窗：说明需在系统设置中关闭授权，确认后跳转系统设置。
  Future<void> _confirmDisconnect(BuildContext context, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) => _DisconnectGuideDialog(title: title),
    );
    if (confirmed == true) {
      await controller.openHealthPrivacySettings();
    }
  }
}

/// 断开连接引导弹窗：App 无法直接撤销系统健康授权，引导用户去系统设置关闭。
class _DisconnectGuideDialog extends StatelessWidget {
  final String title;

  const _DisconnectGuideDialog({required this.title});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: GlassCard(
        radius: AppRadius.xl,
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '断开连接',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              '出于隐私保护，App 无法直接断开与 $title 的连接。\n请在系统「设置」中关闭对本 App 的健康数据授权。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: '取消',
                    foreground: AppColors.brandGreen,
                    background: AppColors.bgPrimary.withValues(alpha: 0.42),
                    borderColor: AppColors.strokeCard,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _ActionButton(
                    label: '去设置',
                    foreground: AppColors.bgPrimary,
                    background: AppColors.brandGreen,
                    borderColor: AppColors.brandGreen,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
  final HealthAuthStatus status;

  const _SourceConnectionCard({required this.data, required this.status});

  @override
  Widget build(BuildContext context) {
    final title = data.source.title;
    final connected = status == HealthAuthStatus.authorized;
    final titleText = connected ? '已连接 $title' : '未连接 $title';
    final (statusIcon, statusColor, statusLabel) = _statusDisplay(title);

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
                  titleText,
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
                    Icon(statusIcon, color: statusColor, size: 19),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        statusLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
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

  (IconData, Color, String) _statusDisplay(String title) {
    return switch (status) {
      HealthAuthStatus.authorized => (
        Icons.check_circle_outline_rounded,
        AppColors.brandGreen,
        '连接成功',
      ),
      HealthAuthStatus.denied => (
        Icons.cancel_outlined,
        AppColors.accentOrange,
        '未授权，请在系统「健康」中允许读取',
      ),
      HealthAuthStatus.unavailable => (
        Icons.error_outline_rounded,
        AppColors.accentOrange,
        '$title 当前设备不可用',
      ),
      HealthAuthStatus.unsupported => (
        Icons.block_rounded,
        AppColors.textSecondary,
        '当前平台不支持',
      ),
      HealthAuthStatus.unknown => (
        Icons.help_outline_rounded,
        AppColors.textSecondary,
        '授权状态待确认，请同步以验证',
      ),
    };
  }
}

class _PermissionCard extends StatelessWidget {
  final List<SyncSourcePermission> items;
  final String? statusText;
  final bool authorized;

  const _PermissionCard({
    required this.items,
    this.statusText,
    this.authorized = false,
  });

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
            _PermissionRow(item: items[i], authorized: authorized),
            if (i != items.length - 1)
              Divider(color: AppColors.divider, height: AppSpacing.lg),
          ],
          SizedBox(height: AppSpacing.sm),
          Text(
            statusText ?? '需授权后才可同步对应健康数据',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final SyncSourcePermission item;
  final bool authorized;

  const _PermissionRow({required this.item, required this.authorized});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          AppIconView(icon: item.icon, color: item.iconColor, size: 22),
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
          _GreenSwitch(value: authorized),
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

class _SyncResultBanner extends StatelessWidget {
  final String message;
  final bool succeeded;

  const _SyncResultBanner({required this.message, required this.succeeded});

  @override
  Widget build(BuildContext context) {
    final color = succeeded ? AppColors.brandGreen : AppColors.accentOrange;

    return GlassCard(
      radius: AppRadius.lg,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            succeeded
                ? Icons.check_circle_outline_rounded
                : Icons.error_outline_rounded,
            color: color,
            size: 20,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceActionBar extends StatelessWidget {
  final bool syncing;
  final VoidCallback onSave;
  final VoidCallback onDisconnect;

  const _SourceActionBar({
    required this.syncing,
    required this.onSave,
    required this.onDisconnect,
  });

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
            onTap: syncing ? null : onDisconnect,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ActionButton(
            label: '保存设置',
            foreground: AppColors.bgPrimary,
            background: AppColors.brandGreen,
            borderColor: AppColors.brandGreen,
            onTap: syncing ? null : onSave,
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
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.foreground,
    required this.background,
    required this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}
