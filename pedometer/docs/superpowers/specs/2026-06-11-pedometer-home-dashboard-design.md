# Pedometer 首页（Home Dashboard）设计文档

> 日期：2026-06-11
> 目标：在 `pedometer` 项目中新增一个高保真、可运行的运动健康首页，代码架构**严格对齐 chat 项目**（GetX MVVM + ResourceLoader/JSON 资源），视觉严格还原 `首页.png` 并遵守《Pedometer 计步器 App 首页模块设计规范 Skills》。

---

## 1. 背景与约束

- **现状**：`pedometer/lib` 仅有脚手架 `main.dart`（默认计数器），零三方依赖。
- **参考输入**：
  - 视觉目标：`首页.png`（暗色霓虹森林运动风格）。
  - 设计系统：《Pedometer 首页模块设计规范 Skills》（颜色/字体/间距/圆角/组件/i18n 令牌）。
  - 架构范本：`chat` 项目（`lib/common` + `lib/feature` + `lib/products` 分层）。
- **已确认决策**：
  1. 资源体系：**完整复刻 chat 的 ResourceLoader + JSON**（color.json / string.json + 兜底），而非纯静态 Token 类。
  2. 交付范围：**可运行首页 + 三层脚手架**（改 main.dart、建 Tab 宿主与路由、补 pubspec 依赖）。
  3. 底部导航：**自定义三栏玻璃胶囊**（规范 §7.11），不复用 chat 的标准 BottomNavigationBar。

## 2. 架构原则（对齐 chat）

- **分层**：`common`（共享基建）/ `feature`（业务模块）/ `products`（产品装配与启动）。
- **MVVM + GetX**：页面 `extends GetView<XxxViewModel>`；ViewModel `extends GetxController implements IBaseViewModel`，含 `init()/unInit()` 与 `onInit/onClose`，并配 `Vo` 值对象持有 `Rx` 字段。
- **资源**：每个模块 `resources/` 下放 `color.json`/`string.json`，由 `ResourceLoader` 在启动时一次性加载；`XxxResource` 静态 getter 经 `ResourceLoader.color/string` 取值并兜底到 `AppColors`。
- **路由**：集中在 `common/routers/app_pages.dart`，页面挂静态 `routeName`。
- **barrel**：每个模块根 `index.dart` 统一导出。

**与 chat 的刻意差异**：Pedometer 为离线 UI，不引入 http / sqlite / websocket / 权限 / Auth 中间件，因此 `common` 下不建 `api/http/event/tools`；`products/init/app.dart` 使用**深色** `GetMaterialApp`。其余约定一一对应。

## 3. 文件结构

```
lib/
├── main.dart                                  # → AppStartup.run()
├── common/
│   ├── config/
│   │   ├── app_colors.dart                    # AppColors + AppStrings（ResourceLoader 取值）
│   │   ├── app_dimens.dart                    # AppRadius + AppSpacing（规范 §11.2 / §11.3）
│   │   ├── app_theme.dart                     # 深色主题
│   │   ├── app_resource.dart                  # AppImage 资源路径常量
│   │   └── resource_loader.dart               # 与 chat 同款；_modules 为 pedometer 模块表
│   ├── mvvm/ibase_view_model.dart             # 原样复刻
│   ├── routers/app_pages.dart                 # GetPages；initial = 主页 Tab 宿主
│   ├── component/glass_card.dart              # 共享 Liquid Glass 卡片（规范 §11.4）
│   └── resources/{color.json, string.json}    # 全局设计令牌
├── feature/home/
│   ├── index.dart
│   ├── resources/{color.json, string.json, home_resource.dart}   # HomeResource + HomeRouteTable
│   ├── model/home_model.dart                  # StepData / KpiItem / TrendPoint / AnalysisData
│   ├── viewmodel/home_view_model.dart         # HomeViewModel + HomeVo
│   ├── views/home_page.dart                   # HomePage extends GetView<HomeViewModel>
│   └── components/
│       ├── top_entry_card.dart                # 顶部双入口卡（运动总览 / Health 同步）
│       ├── step_ring_hero_card.dart           # 主圆环卡 + StepRingPainter + WalkingScenePlaceholder
│       ├── kpi_card.dart                       # 右侧 KPI 卡（距离 / 卡路里 / 活动时间）
│       ├── trend_chart_card.dart              # 趋势卡 + TrendChartPainter
│       └── mini_analysis_card.dart            # 分析小卡 + MiniSparklinePainter
└── products/
    ├── init/
    │   ├── init.dart                          # AppStartup.run()（冷启动：绑定 + ResourceLoader.init）
    │   └── app.dart                           # PedometerApp（深色 GetMaterialApp + i18n delegates）
    └── phone/
        ├── index.dart
        ├── resources/{color.json, string.json, main_resource.dart}  # MainResource + PhoneRouteTable
        ├── views/main_page.dart               # 三栏 Tab 宿主（首页 + 运动占位 + 我的占位）
        └── components/glass_bottom_nav_bar.dart   # 三栏玻璃胶囊导航（规范 §7.11）
```

## 4. 组件与数据流

### 4.1 页面装配（home_page.dart）

`Stack` 分层：底层深蓝黑径向渐变背景（+ 绿色氛围光）→ `SafeArea` + `SingleChildScrollView`，自上而下：

1. 顶部双入口（`TopEntryCard` ×2，Row 等宽）。
2. 主区：左 `StepRingHeroCard`（Expanded）+ 右 `KpiCard` ×3（纵向）。
3. `TrendChartCard`（趋势大卡）。
4. `MiniAnalysisCard` ×2（卡路里 / 活动时间，Row 等宽）。

底部导航由 `MainPage` 宿主提供（不在 `home_page` 内）。

### 4.2 状态（HomeVo）

首屏演示数据，全部 `Rx`，由 `HomeViewModel.init()` 注入（对齐截图）：

- 步数 `5276` / 目标 `6000` / 达成 `88%`。
- KPI：距离 `1.6 km`、卡路里 `293 kcal`、活动 `28 min`。
- 趋势：7 个点 `WED–TUE`（TUE 高亮），值 `[4.5K, 6.6K, 4.2K, 8K, 6.5K, 4.1K, 7.2K]`。
- 分析：卡路里 `293 kcal / 较昨日 +12%`、活动 `28 min / 较昨日 +8%`，各带一组小曲线采样点。

> 数据来源后续可替换为 Health/传感器；当前 Vo 即数据契约。

### 4.3 绘制（全部 CustomPainter，不放图片）

- `StepRingPainter`：绿色渐变圆环 + round cap + 外发光 + 暗绿底环。
- `TrendChartPainter`：平滑曲线 + 同色渐变面积 + 发光白节点 + 低透明虚线网格。
- `MiniSparklinePainter`：小平滑曲线 + 渐变填充 + 末端节点（橙/青）。
- `WalkingScenePlaceholder`：轻量绿色道路弧线 + 树剪影 + 光点，附 `// TODO: 替换为真实 3D 资源 assets/images/home_walking_scene.png`。

## 5. 设计令牌落地（JSON）

`common/resources/color.json` 收录规范 §4 / §11.1 令牌（节选）：
`bgPrimary #00050A`、`bgRadialBlue #03131C`、`bgRadialGreen #022414`、`brandGreen #24F04E`、`brandGreenLight #6CFF3D`、`brandLime #B7FF24`、`accentOrange #FF9F12`、`accentCyan #0CD9FF`、`accentPurple #7A3DFF`、`accentPink #FF4770`、`textPrimary #F7F8F4`、`textSecondary #C9C4BA`、`textTertiary #8A918E`、`strokeCard #FFFFFF1F`、`gridLine #FFFFFF1F`。

`app_dimens.dart` 落地规范 §11.2/§11.3 的 `AppRadius`（xs8…full999）与 `AppSpacing`（xxs4…xxxl32）。

## 6. 依赖与配置

- pubspec 新增：`get ^4.6.6`、`intl`、`flutter_localizations`(sdk)。
- pubspec assets 注册各模块 `resources/` 目录（供 `rootBundle` 读取 JSON）：`lib/common/resources/`、`lib/feature/home/resources/`、`lib/products/phone/resources/`。
- 预留 `assets/images/`（3D 场景图位）。

## 7. i18n 与防溢出（规范 §9）

- 数字与单位拆分显示；标题/单位用 `Flexible/Expanded/FittedBox/TextOverflow.ellipsis` 兜底。
- 文案进 `string.json`，键名中性（`entry_overview`、`entry_health_sync`、`today_steps`、`trend`、`calories`、`active_time`…），为英/德长文本留宽。
- 布局走弹性约束，不写死中文宽度。

## 8. 范围边界

- **本次交付**：首页功能完整 + App 可运行。
- **占位**：底部第 2（运动/记录）、第 3（我的）栏为占位页（"敬请期待"风格），后续单独接入。
- **不做**：真实传感器/Health 数据、详情页、同步页、真实 3D 资源接入（仅留占位与 TODO）。

## 9. 验收标准

- `flutter analyze` 无错误；App 启动直达首页。
- 视觉对齐截图：深蓝黑背景、绿色圆环、三 KPI、趋势渐变发光曲线、两分析小卡、三栏玻璃胶囊（首页绿色选中）。
- 文本不溢出；数字/单位拆分；切换到占位 Tab 不崩溃。
