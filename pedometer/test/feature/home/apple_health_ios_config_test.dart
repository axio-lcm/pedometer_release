import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS Runner target enables HealthKit for Apple Health sync', () {
    final entitlementFile = File('ios/Runner/Runner.entitlements');
    final projectFile = File('ios/Runner.xcodeproj/project.pbxproj');
    final infoFile = File('ios/Runner/Info.plist');

    expect(entitlementFile.existsSync(), isTrue);
    expect(
      entitlementFile.readAsStringSync(),
      contains('com.apple.developer.healthkit'),
    );

    final projectText = projectFile.readAsStringSync();
    expect(
      'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements'
          .allMatches(projectText)
          .length,
      greaterThanOrEqualTo(3),
    );

    final infoText = infoFile.readAsStringSync();
    expect(infoText, contains('NSHealthShareUsageDescription'));
    expect(infoText, contains('NSHealthUpdateUsageDescription'));
  });
}
