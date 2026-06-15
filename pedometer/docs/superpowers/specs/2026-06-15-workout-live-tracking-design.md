# 户外运动实时追踪 — 设计规格

日期：2026-06-15
模块：`lib/feature/workout`

## 1. 背景与问题

`workout` 模块的地图部分（`WorkoutMapView`，`components/workout_tracking_components.dart:78`）已实现实时 GPS 流、当前位置 marker、GCJ-02 偏移纠正、抖动过滤，工作正常。

但运动追踪页的核心指标全是**静态 mock**：

| 需求 | 现状 |
|------|------|
| 点击开始，距离从 0 累计 | `_togglePrimaryControl` 只切换状态枚举，距离写死 `"2.35"` |
| 时长 | 写死 `"00:18:36"` |
| 卡路里 | 写死 `"186"` |
| 配速 | 写死 `"07'54''"` |
| 地图实时轨迹 | `_RoutePainter` 是装饰性假折线，非真实 GPS 轨迹 Polyline |
| 当前位置记为起点 | 无起点 marker |
| 方向指引 | marker 上有固定方向小三角，不随行进方向旋转 |

本规格把这些指标接到真实 GPS 计算上。

## 2. 已确认的取舍

- **卡路里**：固定默认体重 60kg，按速度查 MET 表估算（零额外输入）。
- **方向指引**：当前位置 marker 箭头随行进方向（GPS bearing）旋转。
- **配速**：实时配速（最近路段速度换算），非平均配速。
- **状态管理**：引入 `WorkoutTrackingController`（GetxController），与 `home` 模块的 GetX MVVM 一致。
- **零新增第三方依赖**：bearing 用 `Geolocator.bearingBetween`，距离用 `Geolocator.distanceBetween`。

## 3. 架构

新建 `WorkoutTrackingController`（GetxController）作为会话的**唯一数据源**。GPS 采集管线**保留**在已跑通的 `WorkoutMapView` 中（权限 / GCJ-02 / 抖动过滤 / 显示策略均已测试），每个被接受的定位点回调 `controller.onFix(rawPosition, displayLatLng)`，由控制器负责全部会话计算。地图与指标面板通过 `Obx` 观察控制器。此方案改动最小，不重写现有地图代码。

### 控制器 Rx 状态

- `status`（`WorkoutStatus`）：ready / running / paused / ended
- `startPoint`（`LatLng?`）：开始时钉住的起点（显示坐标）
- `pathPoints`（`List<LatLng>`）：累计轨迹（显示坐标，GCJ-02），驱动 Polyline
- `distanceMeters`（`double`）：累计距离
- `elapsed`（`Duration`）：计时（排除暂停时间）
- `calories`（`double`）
- `pace`（`Duration` per km，实时）
- `bearing`（`double`）：当前位置 marker 旋转角
- `currentPosition`（`LatLng?`）

### 控制器对外接口（草案）

- `onFix(Position raw, LatLng display)`：接收一个被接受的定位点。
- `start()` / `pause()` / `resume()` / `end()`：状态机驱动。
- 派生格式化 getter：`distanceKmText` / `durationText` / `caloriesText` / `paceText`。

## 4. 状态机（修正现有 bug）

现有 `_togglePrimaryControl` 把 `running → ready`，是 bug；正确语义如下：

| 当前态 | 操作 | 结果 |
|--------|------|------|
| ready | 点击开始 | **全部清零**（距离 / 时长 / 轨迹 / 卡路里 = 0），把当前 GPS 钉为起点，启动计时，→ running |
| running | 点击 | → paused（冻结计时、停止累计） |
| paused | 点击 | → running（继续计时与累计） |
| running / paused | 长按 3 秒 | → ended，用真实聚合数据跳结果页 |

主按钮 `NeonPauseButton` 的 `showStartIcon = status != running`，与上表一致，无需改其内部逻辑。

## 5. 距离累计

- 仅在 `status == running` 时累计。
- 每个定位点用 `Geolocator.distanceBetween`（原始 WGS84 测地线，比 GCJ-02 准）算与上一个被接受点的增量。
- **噪声门限**：增量 `< 2.5m` 视为 GPS 抖动，丢弃（避免站立不动时距离自涨）。
- 被接受的显示坐标追加进 `pathPoints`，驱动 Polyline。
- ready / paused 状态不累计，但仍可更新 `currentPosition` 用于相机跟随。

## 6. 时长 / 实时配速 / 卡路里

### 时长

- 1 秒周期 ticker（`Timer.periodic`）。running 累加，paused 冻结，`start()` 时清零。
- 格式 `HH:MM:SS`。

### 实时配速 — `WorkoutPacePolicy`（纯函数，可测）

- 维护最近样本 `(累计距离, 时间戳)` 的滚动窗口，窗口为最近约 **200m 或 20s**（取够稳定的一段）。
- `配速 = 窗口耗时 ÷ 窗口距离`，换算为分钟/公里。
- 窗口距离过小（数据不足）时显示 `--'--''`。

### 卡路里 — `WorkoutCaloriePolicy`（纯函数，可测）

- 默认体重 `defaultWeightKg = 60`。
- 按当前速度查 MET 表（示意，实现时定稿）：

  | 速度 km/h | MET |
  |-----------|-----|
  | < 4 | 2.5 |
  | 4–6 | 3.5 |
  | 6–8 | 6.0 |
  | 8–10 | 8.3 |
  | 10–12 | 9.8 |
  | > 12 | 11.0 |

- 每个 running tick 累加 `kcal = MET × weightKg × Δ小时`（`Δ小时 = tick 秒数 / 3600`）。

## 7. 地图渲染增强（`WorkoutMapView`）

- 新增 **Polyline** 绑定 `controller.pathPoints`，品牌绿，随运动实时生长。
- 新增**起点 marker**，钉在 `controller.startPoint`，样式区别于当前位置（如绿色起点旗 / 圆点 + “起点”）。
- **方向指引**：当前位置 marker 加 `rotation: controller.bearing` + `flat: true`，使箭头随行进方向旋转；anchor 取圆点中心保证旋转中心正确。
- bearing 由 `Geolocator.bearingBetween(上一点, 当前点)` 计算；移动量低于噪声门限时保持上一次 bearing，避免抖动乱转。
- 相机跟随当前位置（沿用现有行为）。

## 8. 数据绑定与结果页

- 子组件（`WorkoutMetricPanel` / `WorkoutControlPanel` / `WorkoutDistanceOverlay` / `WorkoutEndedMapSummary` 等）**契约不变**，仍接收 `WorkoutTrackingData`。
- `WorkoutTrackingPage` 在 `Obx` 中用控制器派生值 `copyWith` 出实时 `WorkoutTrackingData` 喂给子组件，改动收敛在页面层。
- 结果页 `ExerciseResultPage` 接收由控制器最终聚合的 `ExerciseResultData`（真实距离 / 时长 / 配速 / 卡路里），替换 `ExerciseResultData.mock`。

## 9. 新增 / 改动文件

新增：

- `lib/feature/workout/viewmodel/workout_tracking_controller.dart` — GetxController 会话控制器。
- `lib/feature/workout/model/workout_calorie_policy.dart` — MET 卡路里纯函数。
- `lib/feature/workout/model/workout_pace_policy.dart` — 滚动窗口实时配速纯函数。

改动：

- `views/workout_tracking_page.dart` — 用控制器替换本地 `_status` 与静态数据，Obx 绑定。
- `components/workout_tracking_components.dart` — `WorkoutMapView` 增加 Polyline / 起点 marker / bearing 旋转，并对接控制器 `onFix`。
- `model/workout_model.dart` — `WorkoutTrackingData.copyWith` 扩展可覆盖的实时字段。
- `views/exercise_result_page.dart` — 接收真实聚合结果。

## 10. 测试（TDD）

先写测试再实现，覆盖纯函数与状态机：

- `WorkoutCaloriePolicy`：各速度档 MET 取值、tick 累加正确性。
- `WorkoutPacePolicy`：窗口内配速计算、数据不足返回空、窗口滑出旧样本。
- 距离累计：噪声门限丢弃 < 2.5m 增量、paused 不累计。
- 状态机：`start()` 清零并钉起点、`pause/resume` 计时冻结/恢复、`end()` 聚合。

地图渲染（Polyline / marker / 旋转）依赖平台视图，用现有 widget 测试惯例（`_isWidgetTest` 短路）保证不创建真实 GoogleMap。

## 11. 范围外（明确不做）

- Google Maps API key 的原生配置（`AndroidManifest.xml` / `AppDelegate`）是既有基础设施，不在本次代码改动内；真实地图渲染依赖其已配置好。
- 设备罗盘朝向（`flutter_compass`）—— 本次用 GPS bearing，不引入。
- 运动记录持久化 / 历史保存 —— 不在本次范围。
- 体重输入 UI —— 本次用固定默认体重。
