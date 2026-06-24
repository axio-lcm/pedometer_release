import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/common/network/api_feedback.dart';
import 'package:pedometer/common/network/api_runner.dart';
import 'package:pedometer/feature/mine/api/feedback_api.dart';
import 'package:pedometer/feature/mine/resources/mine_resource.dart';

/// 建议 / 反馈页 view model：表单输入与提交意图。
class SuggestionViewModel extends GetxController implements IBaseViewModel {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  /// 提交中状态：用于禁用按钮并展示 loading。
  final RxBool submitting = false.obs;

  @override
  void init() {}

  @override
  void unInit() {}

  @override
  void onClose() {
    unInit();
    emailController.dispose();
    subjectController.dispose();
    messageController.dispose();
    super.onClose();
  }

  /// 提交反馈：校验 → 加密上报。返回是否成功（成功后由页面负责返回）。
  Future<bool> submit() async {
    final email = emailController.text.trim();
    final title = subjectController.text.trim();
    final content = messageController.text.trim();

    if (email.isEmpty || title.isEmpty || content.isEmpty) {
      ApiFeedback.error(MineResource.suggestionFieldRequired);
      return false;
    }
    if (!GetUtils.isEmail(email)) {
      ApiFeedback.error(MineResource.suggestionInvalidEmail);
      return false;
    }
    if (submitting.value) return false;
    submitting.value = true;

    final ok = await runApiBool(
      () async {
        await FeedbackApi.submitFeedback(
          email: email,
          title: title,
          content: content,
        );
        return true;
      },
      fallback: MineResource.suggestionSendFailed,
    );

    submitting.value = false;
    if (ok) ApiFeedback.success(MineResource.suggestionSuccess);
    return ok;
  }
}
