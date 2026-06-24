import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/mine/resources/mine_resource.dart';

/// 建议 / 反馈页：低分评价或「建议」入口跳转到此。
///
/// UI 复刻自 al_led_banner 的 SuggestionPage：邮箱 / 主题 / 内容三段式标签输入
/// + 底部固定提交按钮；这里换用 pedometer 的设计令牌（AppColors / AppSpacing）。
class SuggestionPage extends StatefulWidget {
  static const String routeName = '/mine/suggestion';

  const SuggestionPage({super.key});

  @override
  State<SuggestionPage> createState() => _SuggestionPageState();
}

class _SuggestionPageState extends State<SuggestionPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();

  /// 邮箱校验错误文案；为 null 表示无错误（空或合法）。
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_onEmailFocusChange);
  }

  @override
  void dispose() {
    _emailFocusNode.removeListener(_onEmailFocusChange);
    _emailFocusNode.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// 失焦时校验邮箱：非空且不是合法邮箱才提示（空值的必填交给提交校验）。
  /// 重新聚焦编辑时先清掉旧提示，避免边改边报错。
  void _onEmailFocusChange() {
    if (_emailFocusNode.hasFocus) {
      if (_emailError != null) setState(() => _emailError = null);
      return;
    }
    final email = _emailController.text.trim();
    final next = (email.isEmpty || GetUtils.isEmail(email))
        ? null
        : MineResource.suggestionInvalidEmail;
    if (next != _emailError) setState(() => _emailError = next);
  }

  void _back() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back<void>();
    }
  }

  void _submit() {
    final email = _emailController.text.trim();
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (email.isEmpty || subject.isEmpty || message.isEmpty) {
      _toast(MineResource.suggestionFieldRequired);
      return;
    }
    if (!GetUtils.isEmail(email)) {
      _toast(MineResource.suggestionInvalidEmail);
      return;
    }
    FocusScope.of(context).unfocus();

    // TODO(反馈投递): 目前仅本地确认。接入后端 / 邮件后，将 email/subject/message 发往反馈接口。
    _toast(MineResource.suggestionSuccess);
    _back();
  }

  void _toast(String message) {
    Get.snackbar(
      MineResource.suggestionTitle,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: EdgeInsets.all(AppSpacing.lg),
      backgroundColor: AppColors.surfaceCardTop,
      colorText: AppColors.textPrimary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final messageHeight = MediaQuery.sizeOf(context).height * 0.28;

    return Scaffold(
      backgroundColor: MineResource.background,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          const Positioned.fill(child: _SuggestionBackground()),
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
                  child: AppTopNavigationBar(
                    title: MineResource.suggestionTitle,
                    onBack: _back,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LabeledField(
                          label: MineResource.suggestionEmailLabel,
                          hint: MineResource.suggestionEmailHint,
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          errorText: _emailError,
                        ),
                        SizedBox(height: AppSpacing.lg),
                        _LabeledField(
                          label: MineResource.suggestionSubjectLabel,
                          hint: MineResource.suggestionSubjectHint,
                          controller: _subjectController,
                        ),
                        SizedBox(height: AppSpacing.lg),
                        _LabeledField(
                          label: MineResource.suggestionMessageLabel,
                          hint: MineResource.suggestionMessageHint,
                          controller: _messageController,
                          minHeight: messageHeight,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    bottomInset + AppSpacing.lg,
                  ),
                  child: _SubmitButton(onTap: _submit),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 标签 + 圆角填充输入框（复刻 al_led_banner 的 _SuggestionField）。
class _LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final double? minHeight;
  final int? maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? errorText;

  const _LabeledField({
    required this.label,
    required this.hint,
    required this.controller,
    this.focusNode,
    this.minHeight,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final isMultiline = maxLines == null;
    final hasError = errorText != null;

    final textField = TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      expands: isMultiline,
      maxLines: isMultiline ? null : maxLines,
      minLines: isMultiline ? null : maxLines,
      textAlignVertical: isMultiline
          ? TextAlignVertical.top
          : TextAlignVertical.center,
      cursorColor: AppColors.brandGreen,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        height: 1.25,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textTertiary,
          fontSize: 16,
          height: 1.25,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: InputBorder.none,
        isDense: !isMultiline,
      ),
    );

    final field = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: hasError ? AppColors.accentPink : AppColors.strokeCard,
          width: 1,
        ),
      ),
      child: isMultiline && minHeight != null
          ? SizedBox(height: minHeight, child: textField)
          : textField,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            height: 1.2,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        field,
        if (hasError) ...[
          SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: AppColors.accentPink,
              ),
              SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  errorText!,
                  style: TextStyle(
                    color: AppColors.accentPink,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SubmitButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.full),
          gradient: LinearGradient(
            colors: [AppColors.brandGreenLight, AppColors.brandGreen],
          ),
        ),
        child: Text(
          MineResource.suggestionSend,
          style: TextStyle(
            color: AppColors.bgPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SuggestionBackground extends StatelessWidget {
  const _SuggestionBackground();

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
