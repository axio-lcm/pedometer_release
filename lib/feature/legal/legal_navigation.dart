import 'package:get/get.dart';

import 'package:pedometer/common/config/app_config.dart';
import 'package:pedometer/feature/legal/views/legal_web_page.dart';

abstract final class LegalNavigation {
  static Future<T?> openPrivacyPolicy<T>({required String title}) {
    return _open<T>(title: title, url: Constants.privacyPolicyUrl);
  }

  static Future<T?> openUserAgreement<T>({required String title}) {
    return _open<T>(title: title, url: Constants.userAgreementUrl);
  }

  static Future<T?> openSubscriptionTerms<T>({required String title}) {
    return _open<T>(title: title, url: Constants.subscriptionTermsUrl);
  }

  static Future<T?> _open<T>({required String title, required String url}) {
    return Get.toNamed<T>(
          LegalWebPage.routeName,
          arguments: {'title': title, 'url': url},
        ) ??
        Future<T?>.value();
  }
}
