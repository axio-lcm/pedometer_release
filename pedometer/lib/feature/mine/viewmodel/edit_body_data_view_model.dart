import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pedometer/common/config/prefs_keys.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/feature/mine/viewmodel/mine_view_model.dart';

class EditBodyDataViewModel extends GetxController implements IBaseViewModel {
  // 输入控制器
  late final TextEditingController heightController;
  late final TextEditingController weightController;
  late final TextEditingController ageController;

  final RxDouble bmi = 0.0.obs;
  final RxBool isSaving = false.obs;

  @override
  void init() {}

  @override
  void unInit() {}

  @override
  void onInit() {
    super.onInit();
    heightController = TextEditingController();
    weightController = TextEditingController();
    ageController = TextEditingController();
    _load();
  }

  @override
  void onClose() {
    heightController.dispose();
    weightController.dispose();
    ageController.dispose();
    unInit();
    super.onClose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getDouble(PrefsKeys.bodyHeight) ?? 175.0;
    final w = prefs.getDouble(PrefsKeys.bodyWeight) ?? 68.0;
    final a = prefs.getInt(PrefsKeys.bodyAge) ?? 28;
    heightController.text = _formatHeight(h);
    weightController.text = _formatWeight(w);
    ageController.text = '$a';
    _recalcBmi();
  }

  void onHeightChanged(String _) => _recalcBmi();
  void onWeightChanged(String _) => _recalcBmi();

  void _recalcBmi() {
    final h = double.tryParse(heightController.text) ?? 0;
    final w = double.tryParse(weightController.text) ?? 0;
    if (h > 0 && w > 0) {
      bmi.value = w / ((h / 100) * (h / 100));
    } else {
      bmi.value = 0;
    }
  }

  Future<bool> save() async {
    final h = double.tryParse(heightController.text);
    final w = double.tryParse(weightController.text);
    final a = int.tryParse(ageController.text);

    if (h == null || h < 120 || h > 220) return false;
    if (w == null || w < 30 || w > 200) return false;
    if (a == null || a < 1 || a > 120) return false;

    isSaving.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(PrefsKeys.bodyHeight, h);
    await prefs.setDouble(PrefsKeys.bodyWeight, w);
    await prefs.setInt(PrefsKeys.bodyAge, a);
    isSaving.value = false;

    // 通知我的页刷新
    if (Get.isRegistered<MineViewModel>()) {
      Get.find<MineViewModel>().refreshLocalizedData();
    }
    return true;
  }

  String _formatHeight(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  String _formatWeight(double v) =>
      v.toStringAsFixed(1);
}
