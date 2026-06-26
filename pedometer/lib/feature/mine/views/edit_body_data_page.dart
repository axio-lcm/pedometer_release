import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/common/config/localized_text.dart';
import 'package:pedometer/feature/mine/viewmodel/edit_body_data_view_model.dart';

class EditBodyDataPage extends GetView<EditBodyDataViewModel> {
  static const routeName = '/mine/edit_body_data';

  const EditBodyDataPage({super.key});

  void _back() {
    if (Get.key.currentState?.canPop() ?? false) Get.back<void>();
  }

  Future<void> _save() async {
    final ok = await controller.save();
    if (ok) {
      _back();
    } else {
      Get.snackbar(
        lt('Invalid input', '输入有误'),
        lt('Please check the ranges and try again.', '请检查输入范围后重试。'),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surfaceCardTop,
        colorText: AppColors.textPrimary,
        margin: EdgeInsets.all(AppSpacing.lg),
        borderRadius: AppRadius.xl,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(child: _Background()),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AppTopNavigationBar(
                        title: lt('Edit Body Data', '编辑身体数据'),
                        onBack: _back,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Obx(
                          () => GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap:
                                controller.isSaving.value ? null : _save,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: AppSpacing.sm,
                              ),
                              child: Text(
                                lt('Save', '保存'),
                                style: TextStyle(
                                  color: AppColors.brandGreen,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GlassCard(
                          radius: AppRadius.xxl,
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.lg,
                          ),
                          child: Column(
                            children: [
                              _BodyField(
                                iconAsset: 'assets/profile_height.svg',
                                iconColor: const Color(0xFF0CD9FF),
                                label: lt('Height', '身高'),
                                controller: controller.heightController,
                                unit: 'cm',
                                hint: lt('120 – 220', '120 – 220'),
                                hintLabel: lt(
                                  'Range: 120 – 220 cm',
                                  '建议范围：120 – 220 cm',
                                ),
                                onChanged: controller.onHeightChanged,
                              ),
                              Divider(height: 1, color: AppColors.divider),
                              _BodyField(
                                iconAsset: 'assets/profile_weight.svg',
                                iconColor: const Color(0xFF24F04E),
                                label: lt('Weight', '体重'),
                                controller: controller.weightController,
                                unit: 'kg',
                                hint: lt('30 – 200', '30 – 200'),
                                hintLabel: lt(
                                  'Range: 30 – 200 kg',
                                  '建议范围：30 – 200 kg',
                                ),
                                decimal: true,
                                onChanged: controller.onWeightChanged,
                              ),
                              Divider(height: 1, color: AppColors.divider),
                              Obx(() => _BmiRow(bmi: controller.bmi.value)),
                              Divider(height: 1, color: AppColors.divider),
                              _BodyField(
                                iconAsset: 'assets/profile_age.svg',
                                iconColor: const Color(0xFFFF9F12),
                                label: lt('Age', '年龄'),
                                controller: controller.ageController,
                                unit: lt('yrs', '岁'),
                                hint: lt('1 – 120', '1 – 120'),
                                hintLabel: lt(
                                  'Range: 1 – 120',
                                  '建议范围：1 – 120 岁',
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: AppSpacing.lg),
                        _TipCard(),
                      ],
                    ),
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

// ─── 单个输入行 ────────────────────────────────────────────────────────────────

class _BodyField extends StatelessWidget {
  final String iconAsset;
  final Color iconColor;
  final String label;
  final TextEditingController controller;
  final String unit;
  final String hint;
  final String hintLabel;
  final bool decimal;
  final ValueChanged<String>? onChanged;

  const _BodyField({
    required this.iconAsset,
    required this.iconColor,
    required this.label,
    required this.controller,
    required this.unit,
    required this.hint,
    required this.hintLabel,
    this.decimal = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            iconAsset,
            width: 32,
            height: 32,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: decimal,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            decimal
                                ? RegExp(r'^\d*\.?\d*')
                                : RegExp(r'^\d*'),
                          ),
                        ],
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          hintText: hint,
                          hintStyle: TextStyle(
                            color: AppColors.textDisabled,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onChanged: onChanged,
                      ),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      unit,
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  hintLabel,
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
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

// ─── BMI 只读行 ────────────────────────────────────────────────────────────────

class _BmiRow extends StatelessWidget {
  final double bmi;

  const _BmiRow({required this.bmi});

  String get _value => bmi > 0 ? bmi.toStringAsFixed(1) : '--';

  String get _status {
    if (bmi <= 0) return '';
    if (bmi < 18.5) return lt('Low', '偏低');
    if (bmi < 25) return lt('Normal', '正常');
    if (bmi < 30) return lt('High', '偏高');
    return lt('Obese', '肥胖');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            'assets/profile_bmi.svg',
            width: 32,
            height: 32,
            colorFilter: const ColorFilter.mode(
              Color(0xFF7A3DFF),
              BlendMode.srcIn,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BMI',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    Text(
                      _value,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (bmi > 0)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(
                            color: AppColors.brandGreen.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          _status,
                          style: TextStyle(
                            color: AppColors.brandGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  lt('BMI = Weight(kg) / Height²(m)', 'BMI = 体重(kg) / 身高²(m)'),
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
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

// ─── 温馨提示 ──────────────────────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xl,
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.accentCyan,
            size: 18,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lt('Tip', '温馨提示'),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  lt(
                    'Body data is used to calculate calorie burn, health analysis and personalised advice. Please keep the data accurate.',
                    '身体数据将用于计算运动消耗、健康分析和个性化建议，请确保数据准确。',
                  ),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
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

// ─── 背景 ──────────────────────────────────────────────────────────────────────

class _Background extends StatelessWidget {
  const _Background();

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
