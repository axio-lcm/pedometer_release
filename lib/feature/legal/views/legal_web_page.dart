import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:pedometer/common/component/app_top_navigation_bar.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/localized_text.dart';

class LegalWebPage extends StatefulWidget {
  static const String routeName = '/legal-web';

  const LegalWebPage({super.key});

  @override
  State<LegalWebPage> createState() => _LegalWebPageState();
}

class _LegalWebPageState extends State<LegalWebPage> {
  late final String _title;
  late final String _url;
  late final WebViewController _webController;
  double _progress = 0;
  Timer? _loadTimeoutTimer;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    _title = (args is Map ? args['title'] as String? : null) ?? '';
    _url = (args is Map ? args['url'] as String? : null) ?? '';

    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.bgPrimary)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) => _setProgress(value / 100),
          onPageStarted: (_) => _setProgress(0),
          onPageFinished: (_) => _setProgress(1),
          onWebResourceError: (error) {
            debugPrint(
              '[LegalWebPage] resource error '
              '${error.errorCode}: ${error.description}',
            );
          },
        ),
      );

    unawaited(_loadContent());
  }

  @override
  void dispose() {
    _loadTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppTopNavigationBar(
                title: _title,
                onBack: Get.back,
                animateTitleChanges: false,
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  if (_url.isEmpty)
                    Center(
                      child: Text(
                        lt('Failed to load', '加载失败'),
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  else
                    WebViewWidget(controller: _webController),
                  if (_progress < 1)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: _progress > 0 ? _progress : null,
                        minHeight: 2,
                        backgroundColor: AppColors.divider,
                        color: AppColors.brandGreen,
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

  void _setProgress(double value) {
    if (!mounted) return;
    setState(() => _progress = value);
  }

  Future<void> _loadContent() async {
    if (_url.isEmpty) return;

    _startLoadTimeout();
    await _webController.loadRequest(Uri.parse(_url));
  }

  void _startLoadTimeout() {
    _loadTimeoutTimer?.cancel();
    _loadTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted || _progress >= 1) return;
      _setProgress(1);
    });
  }
}
