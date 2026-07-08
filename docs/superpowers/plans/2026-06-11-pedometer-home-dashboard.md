# Pedometer 首页（Home Dashboard）实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 在 `pedometer` 项目中新增一个可运行、高保真的运动健康首页，架构严格对齐 `chat`（GetX MVVM + ResourceLoader/JSON 资源），视觉还原 `首页.png`。

**架构：** `common`（基建：resource_loader/config/mvvm/component/routers）+ `feature/home`（MVVM + CustomPainter 组件）+ `products`（init 启动壳 + phone 三栏 Tab 宿主 + 玻璃胶囊导航）。首屏数据由 `HomeViewModel` 注入 `HomeVo`（Rx）。

**技术栈：** Flutter（Material）、`get`（路由/状态）、`intl`、`flutter_localizations`、JSON 资源经 `rootBundle` 加载。

> 工作目录：所有路径相对 `/Users/alhdev/Desktop/pro/pedometer`。该目录非 git 仓库；首个 commit 步骤前先 `git init`（见任务 1）。

---

## 文件结构

| 文件 | 职责 |
|---|---|
| `pubspec.yaml`（改） | 加 `get`/`intl`/`flutter_localizations`；注册 resources 为 assets |
| `lib/main.dart`（改） | `AppStartup.run()` 入口 |
| `lib/common/config/resource_loader.dart` | JSON 资源加载（复刻 chat） |
| `lib/common/config/app_colors.dart` | `AppColors` + `AppStrings`（走 ResourceLoader） |
| `lib/common/config/app_dimens.dart` | `AppRadius` + `AppSpacing`（规范 §11） |
| `lib/common/config/app_theme.dart` | 深色 `ThemeData` |
| `lib/common/config/app_resource.dart` | `AppImage` 资源路径常量 |
| `lib/common/resources/color.json` / `string.json` | 全局设计令牌 |
| `lib/common/mvvm/ibase_view_model.dart` | VM 基类（复刻 chat） |
| `lib/common/component/glass_card.dart` | 共享 Liquid Glass 卡片 |
| `lib/common/routers/app_pages.dart` | GetPages 路由表 |
| `lib/feature/home/model/home_model.dart` | 数据模型 |
| `lib/feature/home/viewmodel/home_view_model.dart` | `HomeViewModel` + `HomeVo` |
| `lib/feature/home/resources/{color.json,string.json,home_resource.dart}` | 首页资源 |
| `lib/feature/home/components/*.dart` | 卡片 + CustomPainter |
| `lib/feature/home/views/home_page.dart` | 首页装配 |
| `lib/feature/home/index.dart` | barrel |
| `lib/products/init/{init.dart,app.dart}` | 冷启动 + 根 Widget |
| `lib/products/phone/resources/{color.json,string.json,main_resource.dart}` | 主页资源 |
| `lib/products/phone/components/glass_bottom_nav_bar.dart` | 三栏玻璃胶囊导航 |
| `lib/products/phone/views/main_page.dart` | 三栏 Tab 宿主 + 占位页 |
| `lib/products/phone/index.dart` | barrel |
| `test/*` | ResourceLoader / model / viewmodel / 首页 smoke 测试 |

---

## 任务 1：依赖与工程配置

**文件：**
- 修改：`pubspec.yaml`
- 初始化：git 仓库

- [ ] **步骤 1：初始化 git（便于后续 commit）**

```bash
cd /Users/alhdev/Desktop/pro/pedometer
git init
git add -A && git commit -m "chore: snapshot before home dashboard"
```

- [ ] **步骤 2：改 `pubspec.yaml` 的 dependencies**

将 `dependencies:` 段替换为：

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  cupertino_icons: ^1.0.8
  # GetX：路由 + 状态管理（对齐 chat）
  get: ^4.6.6
  # 数字 / 日期格式化与国际化
  intl: ^0.20.2
```

- [ ] **步骤 3：改 `pubspec.yaml` 的 flutter 段，注册资源目录为 assets**

把 `flutter:` 段中 `uses-material-design: true` 之后追加：

```yaml
  assets:
    - lib/common/resources/
    - lib/feature/home/resources/
    - lib/products/phone/resources/
    - assets/images/
```

- [ ] **步骤 4：创建 assets 占位目录（避免 pub get 报缺失）**

```bash
mkdir -p assets/images && touch assets/images/.gitkeep
```

- [ ] **步骤 5：拉取依赖，确认无误**

运行：`flutter pub get`
预期：`Got dependencies!`，无 version solving 错误。

- [ ] **步骤 6：Commit**

```bash
git add pubspec.yaml pubspec.lock assets/images/.gitkeep
git commit -m "chore: add get/intl deps and register resource assets"
```

---

## 任务 2：ResourceLoader 与全局 JSON 令牌

**文件：**
- 创建：`lib/common/config/resource_loader.dart`
- 创建：`lib/common/resources/color.json`
- 创建：`lib/common/resources/string.json`
- 测试：`test/common/resource_loader_test.dart`

- [ ] **步骤 1：创建 `lib/common/resources/color.json`（规范 §4 / §11.1 令牌）**

```json
{
  "bgPrimary": "#00050A",
  "bgRadialBlue": "#03131C",
  "bgRadialGreen": "#022414",
  "surfaceCard": "#C6161CC",
  "surfaceCardTop": "#D10C262E",
  "surfaceCardBottom": "#E1020B10",
  "surfaceIcon": "#D1081F26",
  "strokeCard": "#1FFFFFFF",
  "strokeGreen": "#8C26FF52",
  "divider": "#1AFFFFFF",
  "gridLine": "#1FFFFFFF",
  "brandGreen": "#24F04E",
  "brandGreenLight": "#6CFF3D",
  "brandGreenDark": "#063F22",
  "brandLime": "#B7FF24",
  "accentOrange": "#FF9F12",
  "accentCyan": "#0CD9FF",
  "accentPurple": "#7A3DFF",
  "accentPink": "#FF4770",
  "statusSuccess": "#43F56B",
  "statusWarning": "#FFB020",
  "statusError": "#FF4D5E",
  "textPrimary": "#F7F8F4",
  "textSecondary": "#C9C4BA",
  "textTertiary": "#8A918E",
  "textDisabled": "#5E6663",
  "white": "#FFFFFF",
  "black": "#000000",
  "transparent": "transparent"
}
```

> 说明：8 位 hex 为 `AARRGGBB`。如 `surfaceCard #C6161CC` = alpha 0xC6 + 0x06161C，对应规范 `rgba(6,22,28,0.78)`。

- [ ] **步骤 2：创建 `lib/common/resources/string.json`**

```json
{
  "app_name": "Pedometer",
  "loading": "加载中...",
  "error": "加载失败",
  "coming_soon": "{{label}}：敬请期待"
}
```

- [ ] **步骤 3：创建 `lib/common/config/resource_loader.dart`（复刻 chat，模块表改为 pedometer）**

```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 从各模块 resources 目录下的 color.json / string.json 加载静态资源。
class ResourceLoader {
  ResourceLoader._();

  static final Map<String, Map<String, String>> _colors = {};
  static final Map<String, Map<String, String>> _strings = {};
  static bool _initialized = false;

  static const _modules = <(String module, String assetDir)>[
    ('common', 'lib/common/resources'),
    ('home', 'lib/feature/home/resources'),
    ('phone', 'lib/products/phone/resources'),
  ];

  static Future<void> init() async {
    if (_initialized) return;
    for (final (module, assetDir) in _modules) {
      _colors[module] = await _loadJsonMap('$assetDir/color.json');
      _strings[module] = await _loadJsonMap('$assetDir/string.json');
    }
    _initialized = true;
  }

  /// 仅供测试：用内存数据直接装载，跳过 rootBundle。
  @visibleForTesting
  static void loadForTest({
    Map<String, Map<String, String>> colors = const {},
    Map<String, Map<String, String>> strings = const {},
  }) {
    _colors
      ..clear()
      ..addAll(colors);
    _strings
      ..clear()
      ..addAll(strings);
    _initialized = true;
  }

  static Future<Map<String, String>> _loadJsonMap(String assetPath) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map((key, value) => MapEntry('$key', '$value'));
    } catch (_) {
      return {};
    }
  }

  static Color color(
    String module,
    String key, {
    String? fallbackModule,
    Color fallback = Colors.transparent,
  }) {
    _ensureInit();
    var value = _colors[module]?[key];
    if ((value == null || value.isEmpty) && fallbackModule != null) {
      value = _colors[fallbackModule]?[key];
    }
    if (value == null || value.isEmpty) return fallback;
    return _parseColor(value);
  }

  static String string(
    String module,
    String key, {
    String? fallbackModule,
    String fallback = '',
  }) {
    _ensureInit();
    var value = _strings[module]?[key];
    if ((value == null || value.isEmpty) && fallbackModule != null) {
      value = _strings[fallbackModule]?[key];
    }
    return value ?? fallback;
  }

  static Color _parseColor(String value) {
    if (value == 'transparent') return Colors.transparent;
    final hex = value.replaceFirst('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
    return Colors.transparent;
  }

  static void _ensureInit() {
    assert(
      _initialized,
      'ResourceLoader.init() must be called before using module resources.',
    );
  }
}
```

- [ ] **步骤 4：编写失败测试 `test/common/resource_loader_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/common/config/resource_loader.dart';

void main() {
  setUp(() {
    ResourceLoader.loadForTest(
      colors: {
        'common': {'brandGreen': '#24F04E', 'transparent': 'transparent'},
        'home': {},
      },
      strings: {
        'common': {'app_name': 'Pedometer'},
        'home': {},
      },
    );
  });

  test('parses 6-digit hex into opaque color', () {
    expect(ResourceLoader.color('common', 'brandGreen'),
        const Color(0xFF24F04E));
  });

  test('falls back across modules then to fallback color', () {
    expect(
      ResourceLoader.color('home', 'brandGreen',
          fallbackModule: 'common'),
      const Color(0xFF24F04E),
    );
    expect(
      ResourceLoader.color('home', 'missing', fallback: Colors.red),
      Colors.red,
    );
  });

  test('reads string with fallback', () {
    expect(ResourceLoader.string('common', 'app_name'), 'Pedometer');
    expect(
      ResourceLoader.string('common', 'missing', fallback: 'x'),
      'x',
    );
  });
}
```

- [ ] **步骤 5：运行测试验证通过**

运行：`flutter test test/common/resource_loader_test.dart`
预期：All tests passed!（3 passed）

- [ ] **步骤 6：Commit**

```bash
git add lib/common/config/resource_loader.dart lib/common/resources test/common/resource_loader_test.dart
git commit -m "feat: add ResourceLoader and global design tokens"
```

---

## 任务 3：config 令牌类（颜色/尺寸/主题/资源路径）

**文件：**
- 创建：`lib/common/config/app_colors.dart`
- 创建：`lib/common/config/app_dimens.dart`
- 创建：`lib/common/config/app_theme.dart`
- 创建：`lib/common/config/app_resource.dart`

- [ ] **步骤 1：创建 `lib/common/config/app_colors.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:pedometer/common/config/resource_loader.dart';

/// 全局颜色令牌（common/resources/color.json）
class AppColors {
  AppColors._();

  static Color get bgPrimary => ResourceLoader.color('common', 'bgPrimary', fallback: const Color(0xFF00050A));
  static Color get bgRadialBlue => ResourceLoader.color('common', 'bgRadialBlue', fallback: const Color(0xFF03131C));
  static Color get bgRadialGreen => ResourceLoader.color('common', 'bgRadialGreen', fallback: const Color(0xFF022414));
  static Color get surfaceCardTop => ResourceLoader.color('common', 'surfaceCardTop', fallback: const Color(0xD10C262E));
  static Color get surfaceCardBottom => ResourceLoader.color('common', 'surfaceCardBottom', fallback: const Color(0xE1020B10));
  static Color get surfaceIcon => ResourceLoader.color('common', 'surfaceIcon', fallback: const Color(0xD1081F26));
  static Color get strokeCard => ResourceLoader.color('common', 'strokeCard', fallback: const Color(0x1FFFFFFF));
  static Color get strokeGreen => ResourceLoader.color('common', 'strokeGreen', fallback: const Color(0x8C26FF52));
  static Color get divider => ResourceLoader.color('common', 'divider', fallback: const Color(0x1AFFFFFF));
  static Color get gridLine => ResourceLoader.color('common', 'gridLine', fallback: const Color(0x1FFFFFFF));
  static Color get brandGreen => ResourceLoader.color('common', 'brandGreen', fallback: const Color(0xFF24F04E));
  static Color get brandGreenLight => ResourceLoader.color('common', 'brandGreenLight', fallback: const Color(0xFF6CFF3D));
  static Color get brandGreenDark => ResourceLoader.color('common', 'brandGreenDark', fallback: const Color(0xFF063F22));
  static Color get brandLime => ResourceLoader.color('common', 'brandLime', fallback: const Color(0xFFB7FF24));
  static Color get accentOrange => ResourceLoader.color('common', 'accentOrange', fallback: const Color(0xFFFF9F12));
  static Color get accentCyan => ResourceLoader.color('common', 'accentCyan', fallback: const Color(0xFF0CD9FF));
  static Color get accentPurple => ResourceLoader.color('common', 'accentPurple', fallback: const Color(0xFF7A3DFF));
  static Color get accentPink => ResourceLoader.color('common', 'accentPink', fallback: const Color(0xFFFF4770));
  static Color get statusSuccess => ResourceLoader.color('common', 'statusSuccess', fallback: const Color(0xFF43F56B));
  static Color get textPrimary => ResourceLoader.color('common', 'textPrimary', fallback: const Color(0xFFF7F8F4));
  static Color get textSecondary => ResourceLoader.color('common', 'textSecondary', fallback: const Color(0xFFC9C4BA));
  static Color get textTertiary => ResourceLoader.color('common', 'textTertiary', fallback: const Color(0xFF8A918E));
  static Color get textDisabled => ResourceLoader.color('common', 'textDisabled', fallback: const Color(0xFF5E6663));
  static Color get white => ResourceLoader.color('common', 'white', fallback: Colors.white);
}

/// 全局文案令牌（common/resources/string.json）
class AppStrings {
  AppStrings._();

  static String get appName => ResourceLoader.string('common', 'app_name', fallback: 'Pedometer');
  static String get loading => ResourceLoader.string('common', 'loading', fallback: '加载中...');
  static String get error => ResourceLoader.string('common', 'error', fallback: '加载失败');

  static String comingSoon(String label) {
    final tpl = ResourceLoader.string('common', 'coming_soon', fallback: '{{label}}：敬请期待');
    return tpl.replaceAll('{{label}}', label);
  }
}
```

- [ ] **步骤 2：创建 `lib/common/config/app_dimens.dart`（规范 §11.2 / §11.3）**

```dart
/// 圆角令牌（规范 §6.1）
class AppRadius {
  AppRadius._();
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 28.0;
  static const double full = 999.0;
}

/// 间距令牌（规范 §5.1）
class AppSpacing {
  AppSpacing._();
  static const double xxs = 4.0;
  static const double xs = 6.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}
```

- [ ] **步骤 3：创建 `lib/common/config/app_theme.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:pedometer/common/config/app_colors.dart';

/// 全局深色主题
class AppTheme {
  AppTheme._();

  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgPrimary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.brandGreen,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      );
}
```

- [ ] **步骤 4：创建 `lib/common/config/app_resource.dart`**

```dart
/// 资源文件路径常量
class AppImage {
  AppImage._();

  static const String path = 'assets/images';
  // TODO: 替换为真实 3D 步行场景资源
  static const String walkingScene = '$path/home_walking_scene.png';
}
```

- [ ] **步骤 5：静态检查**

运行：`flutter analyze lib/common/config`
预期：No issues found!

- [ ] **步骤 6：Commit**

```bash
git add lib/common/config
git commit -m "feat: add color/dimens/theme/resource config tokens"
```

---

## 任务 4：MVVM 基类与共享玻璃卡片

**文件：**
- 创建：`lib/common/mvvm/ibase_view_model.dart`
- 创建：`lib/common/component/glass_card.dart`

- [ ] **步骤 1：创建 `lib/common/mvvm/ibase_view_model.dart`（原样复刻 chat）**

```dart
/// view model 基类
abstract class IBaseViewModel {
  void init();
  void unInit();
}
```

- [ ] **步骤 2：创建 `lib/common/component/glass_card.dart`（规范 §11.4）**

```dart
import 'package:flutter/material.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';

/// Liquid Glass 半透明玻璃卡片：渐变 + 白描边 + 暗阴影（可选绿色发光）。
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool glow;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadius.xl,
    this.glow = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceCardTop, AppColors.surfaceCardBottom],
        ),
        border: Border.all(
          color: borderColor ?? AppColors.strokeCard,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          if (glow)
            BoxShadow(
              color: AppColors.brandGreen.withValues(alpha: 0.22),
              blurRadius: 28,
              spreadRadius: -4,
            ),
        ],
      ),
      child: child,
    );
  }
}
```

- [ ] **步骤 3：静态检查**

运行：`flutter analyze lib/common/mvvm lib/common/component`
预期：No issues found!

- [ ] **步骤 4：Commit**

```bash
git add lib/common/mvvm lib/common/component
git commit -m "feat: add IBaseViewModel base and shared GlassCard"
```

---

## 任务 5：首页数据模型

**文件：**
- 创建：`lib/feature/home/model/home_model.dart`
- 测试：`test/feature/home/home_model_test.dart`

- [ ] **步骤 1：创建 `lib/feature/home/model/home_model.dart`**

```dart
import 'package:flutter/material.dart';

/// 主步数数据
class StepData {
  final int steps;
  final int goal;
  const StepData({required this.steps, required this.goal});

  /// 达成比例 0.0–1.0（封顶 1.0）
  double get progress => goal <= 0 ? 0 : (steps / goal).clamp(0.0, 1.0);

  /// 达成百分比整数
  int get percent => (progress * 100).round();
}

/// KPI 卡数据（距离 / 卡路里 / 活动时间）
class KpiItem {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String unit;
  const KpiItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.unit,
  });
}

/// 趋势图单个数据点
class TrendPoint {
  final String label;
  final double value;
  final bool highlight;
  const TrendPoint({
    required this.label,
    required this.value,
    this.highlight = false,
  });
}

/// 分析小卡数据
class AnalysisData {
  final String title;
  final String value;
  final String unit;
  final String delta;
  final Color color;
  final List<double> samples;
  const AnalysisData({
    required this.title,
    required this.value,
    required this.unit,
    required this.delta,
    required this.color,
    required this.samples,
  });
}
```

- [ ] **步骤 2：编写失败测试 `test/feature/home/home_model_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer/feature/home/model/home_model.dart';

void main() {
  group('StepData', () {
    test('progress and percent for 5276/6000', () {
      const d = StepData(steps: 5276, goal: 6000);
      expect(d.percent, 88);
      expect(d.progress, closeTo(0.879, 0.001));
    });

    test('progress clamps to 1.0 when over goal', () {
      const d = StepData(steps: 8000, goal: 6000);
      expect(d.progress, 1.0);
      expect(d.percent, 100);
    });

    test('progress is 0 when goal is 0', () {
      const d = StepData(steps: 100, goal: 0);
      expect(d.progress, 0);
    });
  });
}
```

- [ ] **步骤 3：运行测试验证通过**

运行：`flutter test test/feature/home/home_model_test.dart`
预期：All tests passed!（3 passed）

- [ ] **步骤 4：Commit**

```bash
git add lib/feature/home/model test/feature/home/home_model_test.dart
git commit -m "feat: add home dashboard data models"
```

---

## 任务 6：首页 ViewModel + Vo

**文件：**
- 创建：`lib/feature/home/viewmodel/home_view_model.dart`
- 测试：`test/feature/home/home_view_model_test.dart`

- [ ] **步骤 1：创建 `lib/feature/home/viewmodel/home_view_model.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/mvvm/ibase_view_model.dart';
import 'package:pedometer/feature/home/model/home_model.dart';

/// 首页 view model
class HomeViewModel extends GetxController implements IBaseViewModel {
  final HomeVo vo = HomeVo();

  Rx<StepData> get step => vo.step;
  RxList<KpiItem> get kpis => vo.kpis;
  RxList<TrendPoint> get trend => vo.trend;
  RxList<AnalysisData> get analyses => vo.analyses;

  @override
  void onInit() {
    super.onInit();
    init();
  }

  @override
  void onClose() {
    unInit();
    super.onClose();
  }

  @override
  void init() {
    _seedDemoData();
  }

  @override
  void unInit() {}

  /// 注入首屏演示数据（对齐截图）。后续可替换为传感器 / Health 数据源。
  void _seedDemoData() {
    vo.step.value = const StepData(steps: 5276, goal: 6000);

    vo.kpis.assignAll(const [
      KpiItem(
        icon: Icons.place_rounded,
        color: Color(0xFF7A3DFF),
        title: '距离',
        value: '1.6',
        unit: 'km',
      ),
      KpiItem(
        icon: Icons.local_fire_department_rounded,
        color: Color(0xFFFF9F12),
        title: '卡路里',
        value: '293',
        unit: 'kcal',
      ),
      KpiItem(
        icon: Icons.timer_rounded,
        color: Color(0xFF0CD9FF),
        title: '活动时间',
        value: '28',
        unit: 'min',
      ),
    ]);

    vo.trend.assignAll(const [
      TrendPoint(label: 'WED', value: 4500),
      TrendPoint(label: 'THU', value: 6600),
      TrendPoint(label: 'FRI', value: 4200),
      TrendPoint(label: 'SAT', value: 8000),
      TrendPoint(label: 'SUN', value: 6500),
      TrendPoint(label: 'MON', value: 4100),
      TrendPoint(label: 'TUE', value: 7200, highlight: true),
    ]);

    vo.analyses.assignAll([
      AnalysisData(
        title: '卡路里分析',
        value: '293',
        unit: 'kcal',
        delta: '较昨日 +12%',
        color: AppColors.accentOrange,
        samples: const [0.30, 0.45, 0.38, 0.60, 0.55, 0.78, 0.92],
      ),
      AnalysisData(
        title: '活动时间分析',
        value: '28',
        unit: 'min',
        delta: '较昨日 +8%',
        color: AppColors.accentCyan,
        samples: const [0.40, 0.35, 0.55, 0.50, 0.70, 0.66, 0.88],
      ),
    ]);
  }
}

/// 首页状态对象
class HomeVo {
  final Rx<StepData> step = const StepData(steps: 0, goal: 6000).obs;
  final RxList<KpiItem> kpis = <KpiItem>[].obs;
  final RxList<TrendPoint> trend = <TrendPoint>[].obs;
  final RxList<AnalysisData> analyses = <AnalysisData>[].obs;
}
```

- [ ] **步骤 2：编写失败测试 `test/feature/home/home_view_model_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/feature/home/viewmodel/home_view_model.dart';

void main() {
  setUp(() {
    // analyses 用到 AppColors → 需先装载（空表即可走 fallback）
    ResourceLoader.loadForTest(colors: {'common': {}}, strings: {'common': {}});
  });

  test('init seeds demo data matching the reference screen', () {
    final vm = HomeViewModel();
    vm.init();

    expect(vm.step.value.steps, 5276);
    expect(vm.step.value.percent, 88);
    expect(vm.kpis.length, 3);
    expect(vm.kpis[1].value, '293');
    expect(vm.trend.length, 7);
    expect(vm.trend.last.label, 'TUE');
    expect(vm.trend.last.highlight, isTrue);
    expect(vm.analyses.length, 2);
    expect(vm.analyses.first.samples.length, 7);
  });
}
```

- [ ] **步骤 3：运行测试验证通过**

运行：`flutter test test/feature/home/home_view_model_test.dart`
预期：All tests passed!（1 passed）

- [ ] **步骤 4：Commit**

```bash
git add lib/feature/home/viewmodel test/feature/home/home_view_model_test.dart
git commit -m "feat: add HomeViewModel with seeded demo data"
```

---

## 任务 7：首页资源（JSON + HomeResource）

**文件：**
- 创建：`lib/feature/home/resources/color.json`
- 创建：`lib/feature/home/resources/string.json`
- 创建：`lib/feature/home/resources/home_resource.dart`

- [ ] **步骤 1：创建 `lib/feature/home/resources/color.json`**

```json
{
  "home_bg": "#00050A"
}
```

- [ ] **步骤 2：创建 `lib/feature/home/resources/string.json`**

```json
{
  "entry_overview": "运动总览",
  "entry_health_sync": "Health 同步",
  "today_steps": "今日步数",
  "goal_suffix": "步",
  "achieved": "达成",
  "trend": "趋势"
}
```

- [ ] **步骤 3：创建 `lib/feature/home/resources/home_resource.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/resource_loader.dart';

/// 首页模块静态资源
class HomeResource {
  HomeResource._();

  static Color get background =>
      ResourceLoader.color('home', 'home_bg', fallbackModule: 'common', fallback: AppColors.bgPrimary);

  static String get entryOverview => ResourceLoader.string('home', 'entry_overview', fallback: '运动总览');
  static String get entryHealthSync => ResourceLoader.string('home', 'entry_health_sync', fallback: 'Health 同步');
  static String get todaySteps => ResourceLoader.string('home', 'today_steps', fallback: '今日步数');
  static String get goalSuffix => ResourceLoader.string('home', 'goal_suffix', fallback: '步');
  static String get achieved => ResourceLoader.string('home', 'achieved', fallback: '达成');
  static String get trend => ResourceLoader.string('home', 'trend', fallback: '趋势');
}

/// 首页模块路由定义
class HomeRouteTable {
  HomeRouteTable._();

  static const String pathHome = '/home';
}
```

- [ ] **步骤 4：静态检查**

运行：`flutter analyze lib/feature/home/resources`
预期：No issues found!

- [ ] **步骤 5：Commit**

```bash
git add lib/feature/home/resources
git commit -m "feat: add home module resources and route table"
```

---

## 任务 8：CustomPainter 组件（圆环 / 趋势 / 小曲线 / 场景占位）

**文件：**
- 创建：`lib/feature/home/components/step_ring_painter.dart`
- 创建：`lib/feature/home/components/trend_chart_painter.dart`
- 创建：`lib/feature/home/components/mini_sparkline_painter.dart`
- 创建：`lib/feature/home/components/walking_scene_placeholder.dart`

- [ ] **步骤 1：创建 `lib/feature/home/components/step_ring_painter.dart`（规范 §7.3）**

```dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pedometer/common/config/app_colors.dart';

/// 绿色渐变步数圆环：暗绿底环 + round cap 前景 + 外发光。
class StepRingPainter extends CustomPainter {
  final double progress; // 0.0–1.0
  StepRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 16.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final arcRect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2;
    final sweep = 2 * math.pi * progress;

    // 底环
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.brandGreenDark.withValues(alpha: 0.55);
    canvas.drawCircle(center, radius, bg);

    // 外发光
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.brandGreen.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawArc(arcRect, startAngle, sweep, false, glow);

    // 前景渐变弧
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + 2 * math.pi,
        colors: [
          AppColors.brandGreenLight,
          AppColors.brandGreen,
          const Color(0xFF00B956),
        ],
        stops: const [0.0, 0.6, 1.0],
        transform: GradientRotation(startAngle),
      ).createShader(arcRect);
    canvas.drawArc(arcRect, startAngle, sweep, false, fg);
  }

  @override
  bool shouldRepaint(covariant StepRingPainter old) => old.progress != progress;
}
```

- [ ] **步骤 2：创建 `lib/feature/home/components/trend_chart_painter.dart`（规范 §7.5）**

```dart
import 'package:flutter/material.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/feature/home/model/home_model.dart';

/// 趋势图：低透明网格 + 平滑曲线 + 渐变面积 + 发光白节点。
class TrendChartPainter extends CustomPainter {
  final List<TrendPoint> points;
  final double maxValue; // Y 轴顶值（如 8000）
  TrendChartPainter({required this.points, this.maxValue = 8000});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // 网格线（0/2K/4K/6K/8K → 5 条）
    final grid = Paint()
      ..color = AppColors.gridLine
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      _dashedLine(canvas, Offset(0, y), Offset(size.width, y), grid);
    }

    final dx = size.width / (points.length - 1);
    Offset pos(int i) {
      final v = (points[i].value / maxValue).clamp(0.0, 1.0);
      return Offset(dx * i, size.height * (1 - v));
    }

    final path = Path()..moveTo(pos(0).dx, pos(0).dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = pos(i);
      final p1 = pos(i + 1);
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      path.quadraticBezierTo(p1.dx, p1.dy, p1.dx, p1.dy);
    }

    // 面积填充
    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.brandGreen.withValues(alpha: 0.58),
            AppColors.brandGreen.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size),
    );

    // 曲线
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = AppColors.brandGreen,
    );

    // 节点
    for (var i = 0; i < points.length; i++) {
      final c = pos(i);
      canvas.drawCircle(
        c,
        7,
        Paint()
          ..color = AppColors.brandGreen.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(c, 4, Paint()..color = AppColors.white);
      if (points[i].highlight) {
        canvas.drawCircle(
          c,
          5.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = AppColors.brandGreen,
        );
      }
    }
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint p) {
    const dash = 5.0, gap = 4.0;
    final total = (b - a).distance;
    final dir = (b - a) / total;
    var d = 0.0;
    while (d < total) {
      final s = a + dir * d;
      final e = a + dir * (d + dash).clamp(0, total);
      canvas.drawLine(s, e, p);
      d += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant TrendChartPainter old) =>
      old.points != points || old.maxValue != maxValue;
}
```

- [ ] **步骤 3：创建 `lib/feature/home/components/mini_sparkline_painter.dart`**

```dart
import 'package:flutter/material.dart';

/// 分析小卡曲线：平滑曲线 + 渐变填充 + 末端发光节点。
class MiniSparklinePainter extends CustomPainter {
  final List<double> samples; // 0.0–1.0
  final Color color;
  MiniSparklinePainter({required this.samples, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) return;
    final dx = size.width / (samples.length - 1);
    Offset pos(int i) => Offset(dx * i, size.height * (1 - samples[i].clamp(0.0, 1.0)));

    final path = Path()..moveTo(pos(0).dx, pos(0).dy);
    for (var i = 0; i < samples.length - 1; i++) {
      final p0 = pos(i);
      final p1 = pos(i + 1);
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      path.quadraticBezierTo(p1.dx, p1.dy, p1.dx, p1.dy);
    }

    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.5), color.withValues(alpha: 0.0)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = color,
    );

    final end = pos(samples.length - 1);
    canvas.drawCircle(end, 5, Paint()..color = color.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(end, 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant MiniSparklinePainter old) =>
      old.samples != samples || old.color != color;
}
```

- [ ] **步骤 4：创建 `lib/feature/home/components/walking_scene_placeholder.dart`（规范 §6 处理方式）**

```dart
import 'package:flutter/material.dart';
import 'package:pedometer/common/config/app_colors.dart';

/// 夜间森林步行场景占位：轻量绘制道路弧线 + 树剪影 + 光点。
/// TODO: 替换为真实 3D 步行人物 / 森林道路资源。
/// 建议资源路径：assets/images/home_walking_scene.png
class WalkingScenePlaceholder extends StatelessWidget {
  final double height;
  const WalkingScenePlaceholder({super.key, this.height = 90});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _ScenePainter()),
    );
  }
}

class _ScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 道路弧线
    final road = Path()
      ..moveTo(size.width * 0.30, size.height)
      ..quadraticBezierTo(
          size.width * 0.5, size.height * 0.45, size.width * 0.70, size.height);
    canvas.drawPath(
      road,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..shader = LinearGradient(
          colors: [
            AppColors.brandGreen.withValues(alpha: 0.0),
            AppColors.brandGreen.withValues(alpha: 0.45),
          ],
        ).createShader(Offset.zero & size),
    );

    // 树剪影
    final tree = Paint()..color = AppColors.brandGreenDark.withValues(alpha: 0.7);
    for (final x in [0.12, 0.22, 0.80, 0.90]) {
      final cx = size.width * x;
      final p = Path()
        ..moveTo(cx, size.height * 0.5)
        ..lineTo(cx - 8, size.height)
        ..lineTo(cx + 8, size.height)
        ..close();
      canvas.drawPath(p, tree);
    }

    // 光点
    final dot = Paint()..color = AppColors.brandGreenLight.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    for (final o in [const Offset(0.5, 0.3), const Offset(0.35, 0.6), const Offset(0.65, 0.55)]) {
      canvas.drawCircle(Offset(size.width * o.dx, size.height * o.dy), 2, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

- [ ] **步骤 5：静态检查**

运行：`flutter analyze lib/feature/home/components`
预期：No issues found!

- [ ] **步骤 6：Commit**

```bash
git add lib/feature/home/components
git commit -m "feat: add home CustomPainter components (ring/trend/sparkline/scene)"
```

---

## 任务 9：卡片组件（顶部入口 / KPI / 趋势卡 / 分析小卡 / 主圆环卡）

**文件：**
- 创建：`lib/feature/home/components/top_entry_card.dart`
- 创建：`lib/feature/home/components/kpi_card.dart`
- 创建：`lib/feature/home/components/mini_analysis_card.dart`
- 创建：`lib/feature/home/components/trend_chart_card.dart`
- 创建：`lib/feature/home/components/step_ring_hero_card.dart`

- [ ] **步骤 1：创建 `lib/feature/home/components/top_entry_card.dart`（规范 §7.1）**

```dart
import 'package:flutter/material.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';

/// 顶部入口卡：圆角玻璃底座图标 + 文案 + 右箭头。
class TopEntryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;
  const TopEntryCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: GlassCard(
        radius: AppRadius.lg,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **步骤 2：创建 `lib/feature/home/components/kpi_card.dart`（规范 §7.4）**

```dart
import 'package:flutter/material.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/home/model/home_model.dart';

/// 右侧 KPI 卡：圆形玻璃底座图标 + 标题 + 大数字 + 单位。
class KpiCard extends StatelessWidget {
  final KpiItem item;
  const KpiCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        item.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.unit,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **步骤 3：创建 `lib/feature/home/components/mini_analysis_card.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/home/components/mini_sparkline_painter.dart';
import 'package:pedometer/feature/home/model/home_model.dart';

/// 底部分析小卡：标题 + 大数字 + 变化 + 小曲线。
class MiniAnalysisCard extends StatelessWidget {
  final AnalysisData data;
  final IconData icon;
  const MiniAnalysisCard({super.key, required this.data, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: data.color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                data.value,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(data.unit, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${data.delta} ↑',
            style: TextStyle(color: data.color, fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 36,
            width: double.infinity,
            child: CustomPaint(
              painter: MiniSparklinePainter(samples: data.samples, color: data.color),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **步骤 4：创建 `lib/feature/home/components/trend_chart_card.dart`（规范 §7.5）**

```dart
import 'package:flutter/material.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/home/components/trend_chart_painter.dart';
import 'package:pedometer/feature/home/model/home_model.dart';
import 'package:pedometer/feature/home/resources/home_resource.dart';

/// 趋势大卡：标题 + 圆形箭头按钮 + Y/X 轴 + 趋势曲线。
class TrendChartCard extends StatelessWidget {
  final List<TrendPoint> points;
  const TrendChartCard({super.key, required this.points});

  static const List<String> _yLabels = ['8K', '6K', '4K', '2K', '0'];

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  HomeResource.trend,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.surfaceIcon,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.strokeCard),
                ),
                child: Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final y in _yLabels)
                      Text(y, style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                  ],
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: CustomPaint(
                    painter: TrendChartPainter(points: points),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final p in points)
                  Text(
                    p.label,
                    style: TextStyle(
                      color: p.highlight ? AppColors.brandGreen : AppColors.textTertiary,
                      fontSize: 11,
                      fontWeight: p.highlight ? FontWeight.w700 : FontWeight.w400,
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
```

- [ ] **步骤 5：创建 `lib/feature/home/components/step_ring_hero_card.dart`（规范 §7.3）**

```dart
import 'package:flutter/material.dart';
import 'package:pedometer/common/component/glass_card.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/home/components/step_ring_painter.dart';
import 'package:pedometer/feature/home/components/walking_scene_placeholder.dart';
import 'package:pedometer/feature/home/model/home_model.dart';
import 'package:pedometer/feature/home/resources/home_resource.dart';

/// 主步数圆环卡：圆环 + 标题 + 超大数字 + 目标 + 达成胶囊 + 场景占位。
class StepRingHeroCard extends StatelessWidget {
  final StepData step;
  const StepRingHeroCard({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xxl,
      glow: true,
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(220, 220),
                  painter: StepRingPainter(progress: step.progress),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      HomeResource.todaySteps,
                      style: TextStyle(color: AppColors.brandGreen, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      child: Text(
                        _formatThousand(step.steps),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '/ ${_formatThousand(step.goal)} ${HomeResource.goalSuffix}',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.brandGreen.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: AppColors.brandLime, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${HomeResource.achieved} ${step.percent}%',
                            style: TextStyle(
                              color: AppColors.brandLime,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const WalkingScenePlaceholder(),
        ],
      ),
    );
  }

  /// 千分位（无 intl 依赖的本地实现；后续可换 NumberFormat）。
  String _formatThousand(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
```

- [ ] **步骤 6：静态检查**

运行：`flutter analyze lib/feature/home/components`
预期：No issues found!

- [ ] **步骤 7：Commit**

```bash
git add lib/feature/home/components
git commit -m "feat: add home card components (entry/kpi/analysis/trend/hero)"
```

---

## 任务 10：首页装配 + barrel

**文件：**
- 创建：`lib/feature/home/views/home_page.dart`
- 创建：`lib/feature/home/index.dart`

- [ ] **步骤 1：创建 `lib/feature/home/views/home_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';
import 'package:pedometer/feature/home/components/kpi_card.dart';
import 'package:pedometer/feature/home/components/mini_analysis_card.dart';
import 'package:pedometer/feature/home/components/step_ring_hero_card.dart';
import 'package:pedometer/feature/home/components/top_entry_card.dart';
import 'package:pedometer/feature/home/components/trend_chart_card.dart';
import 'package:pedometer/feature/home/resources/home_resource.dart';
import 'package:pedometer/feature/home/viewmodel/home_view_model.dart';

/// 首页：暗色霓虹森林运动 Dashboard。
class HomePage extends GetView<HomeViewModel> {
  static const String routeName = HomeRouteTable.pathHome;
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeResource.background,
      body: Stack(
        children: [
          _background(),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _topEntries(),
                  const SizedBox(height: AppSpacing.lg),
                  _mainRow(),
                  const SizedBox(height: AppSpacing.lg),
                  Obx(() => TrendChartCard(points: controller.trend.toList())),
                  const SizedBox(height: AppSpacing.lg),
                  _analysisRow(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _background() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.6),
            radius: 1.2,
            colors: [AppColors.bgRadialBlue, AppColors.bgPrimary],
          ),
        ),
      ),
    );
  }

  Widget _topEntries() {
    return Row(
      children: [
        Expanded(
          child: TopEntryCard(
            icon: Icons.directions_run_rounded,
            iconColor: AppColors.brandGreen,
            label: HomeResource.entryOverview,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: TopEntryCard(
            icon: Icons.favorite_rounded,
            iconColor: AppColors.accentPink,
            label: HomeResource.entryHealthSync,
          ),
        ),
      ],
    );
  }

  Widget _mainRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Obx(() => StepRingHeroCard(step: controller.step.value)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 4,
            child: Obx(
              () => Column(
                children: [
                  for (var i = 0; i < controller.kpis.length; i++) ...[
                    Expanded(child: KpiCard(item: controller.kpis[i])),
                    if (i != controller.kpis.length - 1)
                      const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _analysisRow() {
    return Obx(() {
      final list = controller.analyses;
      if (list.length < 2) return const SizedBox.shrink();
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: MiniAnalysisCard(data: list[0], icon: Icons.local_fire_department_rounded)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: MiniAnalysisCard(data: list[1], icon: Icons.timer_rounded)),
        ],
      );
    });
  }
}
```

- [ ] **步骤 2：创建 `lib/feature/home/index.dart`**

```dart
export 'model/home_model.dart';
export 'resources/home_resource.dart';
export 'viewmodel/home_view_model.dart';
export 'views/home_page.dart';
```

- [ ] **步骤 3：静态检查**

运行：`flutter analyze lib/feature/home`
预期：No issues found!

- [ ] **步骤 4：Commit**

```bash
git add lib/feature/home/views lib/feature/home/index.dart
git commit -m "feat: assemble home page and module barrel"
```

---

## 任务 11：phone 产品层（主页资源 + 玻璃胶囊导航 + Tab 宿主）

**文件：**
- 创建：`lib/products/phone/resources/color.json`
- 创建：`lib/products/phone/resources/string.json`
- 创建：`lib/products/phone/resources/main_resource.dart`
- 创建：`lib/products/phone/components/glass_bottom_nav_bar.dart`
- 创建：`lib/products/phone/views/main_page.dart`
- 创建：`lib/products/phone/index.dart`

- [ ] **步骤 1：创建 `lib/products/phone/resources/color.json`**

```json
{
  "main_bg": "#00050A"
}
```

- [ ] **步骤 2：创建 `lib/products/phone/resources/string.json`**

```json
{
  "tab_home": "首页",
  "tab_activity": "运动",
  "tab_mine": "我的"
}
```

- [ ] **步骤 3：创建 `lib/products/phone/resources/main_resource.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/resource_loader.dart';

/// 主页（Tab 宿主）静态资源
class MainResource {
  MainResource._();

  static Color get background =>
      ResourceLoader.color('phone', 'main_bg', fallbackModule: 'common', fallback: AppColors.bgPrimary);

  static String get tabHome => ResourceLoader.string('phone', 'tab_home', fallback: '首页');
  static String get tabActivity => ResourceLoader.string('phone', 'tab_activity', fallback: '运动');
  static String get tabMine => ResourceLoader.string('phone', 'tab_mine', fallback: '我的');
}

/// 主页路由定义
class PhoneRouteTable {
  PhoneRouteTable._();

  static const String pathMain = '/main';
}
```

- [ ] **步骤 4：创建 `lib/products/phone/components/glass_bottom_nav_bar.dart`（规范 §7.11）**

```dart
import 'package:flutter/material.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_dimens.dart';

/// 三栏玻璃胶囊底部导航：首页选中态为绿色胶囊。
class GlassBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const GlassBottomNavBar({super.key, required this.currentIndex, required this.onTap});

  static const _icons = [Icons.home_rounded, Icons.directions_run_rounded, Icons.person_rounded];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Center(
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          width: 300,
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: const Color(0xDB030F14),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: AppColors.strokeCard),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < _icons.length; i++)
                Expanded(child: _item(i)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int i) {
    final selected = i == currentIndex;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(i),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: selected ? 64 : 44,
          height: 44,
          decoration: selected
              ? BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.brandGreenLight, AppColors.brandGreen],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  boxShadow: [
                    BoxShadow(color: AppColors.brandGreen.withValues(alpha: 0.4), blurRadius: 14),
                  ],
                )
              : null,
          child: Icon(
            _icons[i],
            size: 24,
            color: selected ? AppColors.bgPrimary : const Color(0xB3A5A5A5),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **步骤 5：创建 `lib/products/phone/views/main_page.dart`（三栏宿主 + 占位页）**

```dart
import 'package:flutter/material.dart';
import 'package:pedometer/common/config/app_colors.dart';
import 'package:pedometer/common/config/app_strings_ext.dart' show PlaceholderText;
import 'package:pedometer/feature/home/views/home_page.dart';
import 'package:pedometer/products/phone/components/glass_bottom_nav_bar.dart';
import 'package:pedometer/products/phone/resources/main_resource.dart';

/// 主页容器：底部三栏胶囊切换（首页 + 运动占位 + 我的占位）。
class MainPage extends StatefulWidget {
  static const String routeName = PhoneRouteTable.pathMain;
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MainResource.background,
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          const HomePage(),
          _Placeholder(label: MainResource.tabActivity),
          _Placeholder(label: MainResource.tabMine),
        ],
      ),
      bottomNavigationBar: GlassBottomNavBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

/// "敬请期待"占位页（对齐 chat 占位做法）。
class _Placeholder extends StatelessWidget {
  final String label;
  const _Placeholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Center(
        child: Text(
          PlaceholderText.comingSoon(label),
          style: TextStyle(color: AppColors.textTertiary, fontSize: 15),
        ),
      ),
    );
  }
}
```

> 注：`PlaceholderText.comingSoon` 见步骤 6（薄封装 `AppStrings.comingSoon`，避免页面直接耦合 config 命名）。

- [ ] **步骤 6：创建 `lib/common/config/app_strings_ext.dart`**

```dart
import 'package:pedometer/common/config/app_colors.dart';

/// 占位文案薄封装，复用全局 AppStrings。
class PlaceholderText {
  PlaceholderText._();
  static String comingSoon(String label) => AppStrings.comingSoon(label);
}
```

- [ ] **步骤 7：创建 `lib/products/phone/index.dart`**

```dart
export 'components/glass_bottom_nav_bar.dart';
export 'resources/main_resource.dart';
export 'views/main_page.dart';
```

- [ ] **步骤 8：静态检查**

运行：`flutter analyze lib/products/phone lib/common/config/app_strings_ext.dart`
预期：No issues found!

- [ ] **步骤 9：Commit**

```bash
git add lib/products/phone lib/common/config/app_strings_ext.dart
git commit -m "feat: add phone tab host with glass capsule bottom nav"
```

---

## 任务 12：启动壳 + 路由 + main 入口

**文件：**
- 创建：`lib/products/init/init.dart`
- 创建：`lib/products/init/app.dart`
- 创建：`lib/common/routers/app_pages.dart`
- 修改：`lib/main.dart`

- [ ] **步骤 1：创建 `lib/common/routers/app_pages.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/feature/home/viewmodel/home_view_model.dart';
import 'package:pedometer/products/phone/views/main_page.dart';

/// 统一路由管理
class AppPages {
  AppPages._();

  static const String initial = MainPage.routeName;

  static final List<GetPage> pages = [
    GetPage(
      name: MainPage.routeName,
      page: () => const MainPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<HomeViewModel>(() => HomeViewModel());
      }),
    ),
  ];

  static final GetPage unknownRoute = GetPage(
    name: '/404',
    page: () => const Scaffold(body: Center(child: Text('页面不存在'))),
  );
}
```

- [ ] **步骤 2：创建 `lib/products/init/app.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/app_theme.dart';
import 'package:pedometer/common/routers/app_pages.dart';

/// 根 Widget：深色主题 + 路由 + 国际化。
class PedometerApp extends StatelessWidget {
  const PedometerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: Get.key,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
      defaultTransition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 180),
      initialRoute: AppPages.initial,
      getPages: AppPages.pages,
      unknownRoute: AppPages.unknownRoute,
    );
  }
}
```

- [ ] **步骤 3：创建 `lib/products/init/init.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/products/init/app.dart';

/// 应用冷启动初始化（main 入口）。
class AppStartup {
  AppStartup._();

  static bool _bootstrapped = false;

  static Future<void> run() async {
    await bootstrap();
    runApp(const PedometerApp());
  }

  static Future<void> bootstrap() async {
    if (_bootstrapped) return;
    WidgetsFlutterBinding.ensureInitialized();
    await ResourceLoader.init();
    _bootstrapped = true;
  }
}
```

- [ ] **步骤 4：替换 `lib/main.dart` 全部内容**

```dart
import 'package:pedometer/products/init/init.dart';

Future<void> main() => AppStartup.run();
```

- [ ] **步骤 5：静态检查**

运行：`flutter analyze`
预期：No issues found!（全工程）

- [ ] **步骤 6：Commit**

```bash
git add lib/products/init lib/common/routers/app_pages.dart lib/main.dart
git commit -m "feat: wire app bootstrap, router and main entry"
```

---

## 任务 13：首页 smoke 测试与整体验证

**文件：**
- 创建：`test/feature/home/home_page_test.dart`
- 修改：`test/widget_test.dart`（删除默认计数器测试）

- [ ] **步骤 1：删除默认计数器测试，替换 `test/widget_test.dart`**

```dart
// 默认计数器测试已移除；首页测试见 test/feature/home/。
void main() {}
```

- [ ] **步骤 2：编写首页 smoke 测试 `test/feature/home/home_page_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pedometer/common/config/resource_loader.dart';
import 'package:pedometer/feature/home/viewmodel/home_view_model.dart';
import 'package:pedometer/feature/home/views/home_page.dart';
import 'package:pedometer/feature/home/resources/home_resource.dart';

void main() {
  setUp(() {
    ResourceLoader.loadForTest(
      colors: {'common': {}, 'home': {}, 'phone': {}},
      strings: {'common': {}, 'home': {}, 'phone': {}},
    );
    Get.put<HomeViewModel>(HomeViewModel());
  });

  tearDown(Get.reset);

  testWidgets('renders key home data', (tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(home: HomePage()),
    );
    await tester.pump();

    expect(find.text('5,276'), findsOneWidget);
    expect(find.text(HomeResource.todaySteps), findsOneWidget);
    expect(find.text('卡路里分析'), findsOneWidget);
    expect(find.textContaining('达成'), findsOneWidget);
  });
}
```

- [ ] **步骤 3：运行全部测试**

运行：`flutter test`
预期：All tests passed!（resource_loader 3 + model 3 + view_model 1 + home_page 1 = 8 passed）

- [ ] **步骤 4：全工程静态检查**

运行：`flutter analyze`
预期：No issues found!

- [ ] **步骤 5：真机/模拟器运行确认（验证收尾）**

运行：`flutter run -d <iPhone 模拟器>`（或在 IDE 启动）
预期：App 直达首页；可见绿色圆环（5,276/6,000、达成 88%）、三 KPI 卡、趋势渐变发光曲线、两分析小卡、底部三栏玻璃胶囊（首页绿色选中）；点击第 2/3 栏显示"敬请期待"占位且不崩溃。

- [ ] **步骤 6：Commit**

```bash
git add test
git commit -m "test: add home page smoke test and remove default counter test"
```

---

## 自检结果

**1. 规格覆盖度：**
- §1 架构对齐 → 任务 2–4、12（ResourceLoader/config/mvvm/启动壳）✅
- §3 文件结构 → 全部任务逐一落地 ✅
- §4 组件与数据流 → 任务 5/6（model/vm）、8/9（painter/card）、10（装配）✅
- §5 设计令牌 JSON → 任务 2（color/string.json）✅
- §6 依赖与 assets → 任务 1 ✅
- §7 i18n/防溢出 → KPI/入口/分析卡均 `Expanded/Flexible/FittedBox/ellipsis`，文案进 string.json ✅
- §8 范围边界（占位页）→ 任务 11 `_Placeholder` ✅
- §9 验收 → 任务 13 ✅

**2. 占位符扫描：** 无 “TODO/待定/后续补充” 型缺陷；唯一 `TODO` 为 `WalkingScenePlaceholder` 与 `AppImage.walkingScene` 处对真实 3D 资源的刻意替换标记（设计明确要求保留）。

**3. 类型一致性：** `StepData/KpiItem/TrendPoint/AnalysisData`（任务 5）在 vm（任务 6）、painter（任务 8）、card（任务 9）、page（任务 10）中签名一致；`HomeViewModel.step/kpis/trend/analyses`、`HomeResource.*`、`MainResource.*`、`AppColors.*`、`AppRadius/AppSpacing.*` 跨任务命名统一；`GlassBottomNavBar(currentIndex,onTap)` 与宿主调用一致。
