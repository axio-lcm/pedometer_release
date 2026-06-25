import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/mine/model/language_catalog.dart';
import 'package:pedometer/feature/mine/resources/mine_resource.dart';
import 'package:pedometer/feature/mine/viewmodel/language_view_model.dart';

class LanguagePage extends GetView<LanguageViewModel> {
  static const String routeName = '/mine/language';

  const LanguagePage({super.key});

  void _back() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back<void>();
    }
  }

  List<LanguageOption> get _options => [
    LanguageOption(
      code: 'sys',
      title: MineResource.followSystem,
      subtitle: MineResource.followSystemSubtitle,
    ),
    ...LanguageCatalog.languages.map(
      (option) => LanguageOption(
        code: option.code,
        title: option.title,
        subtitle: MineResource.languageOptionSubtitle(
          option.code,
          option.subtitle,
        ),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MineResource.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _LanguageBackground()),
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
                    title: MineResource.languageTitle,
                    onBack: _back,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Obx(() {
                    final selected = controller.selectedCode.value;
                    final options = _options;
                    return GlassCard(
                      radius: AppRadius.xxl,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.sm,
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < options.length; i++) ...[
                            _LanguageRow(
                              option: options[i],
                              selected: selected == options[i].code,
                              onTap: () => controller.select(options[i].code),
                            ),
                            if (i != options.length - 1)
                              Divider(height: 1, color: AppColors.divider),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final LanguageOption option;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 76,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
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
            SizedBox(width: AppSpacing.sm),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? AppColors.brandGreen : AppColors.textTertiary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageBackground extends StatelessWidget {
  const _LanguageBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.6),
          radius: 1.2,
          colors: [AppColors.bgRadialBlue, AppColors.bgPrimary],
        ),
      ),
    );
  }
}
