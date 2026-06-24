import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pedometer/common/config/app_config.dart';
import 'package:pedometer/common/network/api_exception.dart';
import 'package:pedometer/common/network/api_guard.dart';
import 'package:pedometer/common/network/models/feedback_request.dart';
import 'package:pedometer/common/network/utils/aes_tool.dart';
import 'package:pedometer/common/network/utils/dio_request.dart';
import 'package:pedometer/common/network/utils/headers_manager.dart';
import 'package:pedometer/feature/mine/resources/mine_resource.dart';

/// 意见反馈接口（移植自 al_led_banner，复用同一后端与加密约定）。
abstract final class FeedbackApi {
  /// 提交反馈：公共 Header + sct，body 为 AES 加密后的 { userId, email, title, content }。
  static Future<void> submitFeedback({
    required String email,
    required String title,
    required String content,
  }) async {
    final headerData = await HeaderManager.instance.getHeaderData();
    final headers = <String, dynamic>{
      ...headerData.toApiToolMap(),
      'sct': AesTool.kSctToken,
    };

    final request = FeedbackRequest(
      userId: headerData.userId,
      email: email,
      title: title,
      content: content,
    );

    final encryptedParams = AesTool.encrypt(jsonEncode(request.toJson()));
    ApiGuard.ensureSuccess(
      encryptedParams.isNotEmpty,
      MineResource.suggestionSendFailed,
    );

    final response = await dioRequest.postJson(
      APIs.feedback,
      parameters: {'data': encryptedParams},
      headers: headers,
    );

    if (kDebugMode) {
      debugPrint('FeedbackApi response: $response');
    }

    if (response == null) {
      throw ApiException(MineResource.suggestionSendFailed);
    }
    ApiGuard.ensureMapSuccess(
      Map<String, dynamic>.from(response),
      MineResource.suggestionSendFailed,
    );
  }
}
