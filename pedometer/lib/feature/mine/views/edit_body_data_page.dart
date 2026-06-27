import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/mine/resources/mine_resource.dart';
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
        MineResource.invalidInput,
        MineResource.invalidBodyDataInputMessage,
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
                        title: MineResource.editBodyDataTitle,
                        onBack: _back,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Obx(
                          () => GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: controller.isSaving.value ? null : _save,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: AppSpacing.sm,
                              ),
                              child: Text(
                                MineResource.save,
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
                                label: MineResource.height,
                                controller: controller.heightController,
                                unit: MineResource.heightUnit,
                                hint: MineResource.heightInputHint,
                                hintLabel: MineResource.heightRangeHint,
                                onChanged: controller.onHeightChanged,
                              ),
                              Divider(height: 1, color: AppColors.divider),
                              _BodyField(
                                iconAsset: 'assets/profile_weight.svg',
                                iconColor: const Color(0xFF24F04E),
                                label: MineResource.weight,
                                controller: controller.weightController,
                                unit: MineResource.weightUnit,
                                hint: MineResource.weightInputHint,
                                hintLabel: MineResource.weightRangeHint,
                                decimal: true,
                                onChanged: controller.onWeightChanged,
                              ),
                              Divider(height: 1, color: AppColors.divider),
                              Obx(() => _BmiRow(bmi: controller.bmi.value)),
                              Divider(height: 1, color: AppColors.divider),
                              _BodyField(
                                iconAsset: 'assets/profile_age.svg',
                                iconColor: const Color(0xFFFF9F12),
                                label: MineResource.age,
                                controller: controller.ageController,
                                unit: MineResource.ageUnit,
                                hint: MineResource.ageInputHint,
                                hintLabel: MineResource.ageRangeHint,
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
                            decimal ? RegExp(r'^\d*\.?\d*') : RegExp(r'^\d*'),
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
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
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
    if (bmi < 18.5) return MineResource.bmiLow;
    if (bmi < 25) return MineResource.bmiNormal;
    if (bmi < 30) return MineResource.bmiHigh;
    return MineResource.bmiObese;
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
                  MineResource.bmi,
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
                  MineResource.bmiFormula,
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
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
                  MineResource.tipTitle,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  MineResource.bodyDataTip,
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
