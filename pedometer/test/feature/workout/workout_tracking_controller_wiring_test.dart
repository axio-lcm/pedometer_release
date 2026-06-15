import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pedometer/common/config/app_screen.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/feature/workout/viewmodel/workout_tracking_controller.dart';
import 'package:pedometer/feature/workout/views/workout_tracking_page.dart';

void main() {
  setUp(() {
    ResourceLoader.loadForTest(colors: {'common': {}}, strings: {'common': {}});
  });

  tearDown(Get.reset);

  Widget wrap(Widget child) {
    return AppScreenAdapter(
      builder: (_) => GetMaterialApp(home: child),
    );
  }

  testWidgets('live metric panel reflects controller distance changes',
      (tester) async {
    final controller = Get.put(WorkoutTrackingController());
    controller.currentPosition.value = const LatLng(31.0, 121.0);

    await tester.pumpWidget(wrap(const WorkoutTrackingPage()));
    await tester.pump();

    expect(find.text('0.00'), findsWidgets);

    controller.distanceMeters.value = 1234; // 1.23km
    await tester.pump();
    expect(find.text('1.23'), findsOneWidget);
  });
}
