/// 意见反馈请求体（加密前的明文参数）。
class FeedbackRequest {
  const FeedbackRequest({
    required this.userId,
    required this.email,
    required this.title,
    required this.content,
  });

  final String userId;
  final String email;
  final String title;
  final String content;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'title': title,
      'content': content,
    };
  }
}
