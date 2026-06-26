# 项目权限与 SDK 使用说明

> 项目：Pedometer（计步器）Flutter App
> 生成日期：2026-06-26

---

## 一、iOS 权限（Info.plist）

| 权限 Key | 用途说明 |
|---------|---------|
| `NSHealthShareUsageDescription` | 从 Apple Health 同步步数、距离、卡路里和活动时间，在首页及日/周/月统计中展示 |
| `NSHealthUpdateUsageDescription` | 授权后同步健康数据至 Apple Health |
| `NSLocalNetworkUsageDescription` | Debug 模式下连接 Dart VM Service |
| `NSLocationWhenInUseUsageDescription` | 户外运动时展示当前位置、记录运动轨迹 |
| `NSLocationTemporaryUsageDescriptionDictionary`（WorkoutPreciseLocation） | 在户外地图上显示精确位置，需要精准定位权限 |
| `NSMotionUsageDescription` | 读取设备步数、距离和活动数据，展示在运动统计中 |
| `NSBonjourServices`（`_dartobservatory._tcp`） | Debug 模式下 Dart 可观测性支持 |

---

## 二、Android 权限（AndroidManifest.xml）

| 权限 | 用途说明 |
|-----|---------|
| `INTERNET` | 网络请求 |
| `ACTIVITY_RECOGNITION` | 识别用户活动，用于计步 |
| `ACCESS_COARSE_LOCATION` | 通过基站/WiFi 获取大致位置 |
| `ACCESS_FINE_LOCATION` | GPS 精准定位，用于户外地图及轨迹记录 |
| `health.READ_STEPS` | 从 Health Connect 读取步数（Android 14+） |
| `health.READ_DISTANCE` | 从 Health Connect 读取距离 |
| `health.READ_TOTAL_CALORIES_BURNED` | 从 Health Connect 读取总卡路里消耗 |
| `health.READ_ACTIVE_CALORIES_BURNED` | 从 Health Connect 读取活动卡路里 |
| `health.READ_ACTIVITY_INTENSITY` | 从 Health Connect 读取活动强度 |
| `health.READ_EXERCISE` | 从 Health Connect 读取运动数据 |

---

## 三、Flutter 依赖包（pubspec.yaml）

### 3.1 UI 与设计

| 包名 | 版本 | 用途 |
|-----|-----|-----|
| `flutter_screenutil` | ^5.9.3 | 屏幕适配（设计基准 375×812） |
| `flutter_svg` | ^2.0.17 | SVG 图标渲染 |
| `fl_chart` | ^0.69.0 | 折线图/面积图，用于趋势、卡路里、活动分析 |
| `flutter_confetti` | ^0.5.1 | 运动完成时的彩纸动画 |
| `cupertino_icons` | ^1.0.8 | iOS 风格图标 |

### 3.2 状态管理与路由

| 包名 | 版本 | 用途 |
|-----|-----|-----|
| `get` | ^4.6.6 | GetX 状态管理与路由 |

### 3.3 国际化

| 包名 | 版本 | 用途 |
|-----|-----|-----|
| `flutter_localizations` | SDK 内置 | 多语言支持 |
| `intl` | ^0.20.2 | 日期/数字格式化 |

### 3.4 定位与地图

| 包名 | 版本 | 用途 |
|-----|-----|-----|
| `google_maps_flutter` | ^2.17.1 | Google 地图，户外运动轨迹展示 |
| `geolocator` | ^14.0.2 | 高精度定位及运行时权限请求 |
| `flutter_compass` | ^0.8.1 | 磁力计/指南针，地图当前方向箭头旋转 |

### 3.5 健康与运动数据

| 包名 | 版本 | 用途 |
|-----|-----|-----|
| `health` | ^13.3.1 | Apple Health（iOS）/ Health Connect（Android）数据同步 |
| `motion_fitness`（本地插件） | — | iOS CoreMotion / Android 传感器计步 |

### 3.6 系统功能

| 包名 | 版本 | 用途 |
|-----|-----|-----|
| `share_plus` | ^11.0.0 | 系统分享面板 |
| `in_app_review` | ^2.0.12 | 应用内评分（iOS SKStoreReviewController） |
| `shared_preferences` | ^2.5.5 | 本地偏好存储（语言选择等） |

### 3.7 媒体与文件

| 包名 | 版本 | 用途 |
|-----|-----|-----|
| `file_picker` | ^11.0.2 | 文件选择 |
| `just_audio` | ^0.10.5 | 音频播放 |

### 3.8 订阅与归因

| 包名 | 版本 | 用途 |
|-----|-----|-----|
| `pp_inapp_purchase` | ^1.1.0 | Apple 内购订阅（StoreKit v1） |
| `pp_asa_attribution` | ^1.0.2 | Apple Search Ads 归因追踪 |

### 3.9 网络与安全

| 包名 | 版本 | 用途 |
|-----|-----|-----|
| `dio` | ^5.9.2 | HTTP 网络请求 |
| `encrypt` | ^5.0.3 | AES 加密请求参数 |
| `connectivity_plus` | ^7.1.1 | 网络类型检测（上报 netType 字段） |

### 3.10 设备信息

| 包名 | 版本 | 用途 |
|-----|-----|-----|
| `device_info_plus` | ^12.4.0 | 设备型号/OS 版本（上报 deviceModel/OS 字段） |
| `package_info_plus` | ^9.0.1 | 应用包信息（上报 appId/appVersion 字段） |
| `uuid` | ^4.5.3 | 生成设备唯一标识符（userId） |

---

## 四、第三方 SDK 与服务

### 4.1 Google Maps

- **包**：`google_maps_flutter`
- **用途**：户外运动轨迹可视化、当前位置展示
- **配置**：API Key 通过环境变量 `GOOGLE_MAPS_API_KEY` 注入（AndroidManifest.xml + Info.plist）

### 4.2 Apple HealthKit（iOS）

- **包**：`health`
- **权限**：读取步数、距离、卡路里、活动时间（可写）
- **用途**：与系统健康数据双向同步

### 4.3 Android Health Connect

- **包**：`health`
- **权限**：10 项 READ 权限（见上方 Android 权限表）
- **用途**：读取健康数据，展示在统计页

### 4.4 Apple In-App Purchase（StoreKit v1）

- **包**：`pp_inapp_purchase`
- **用途**：订阅管理（Premium 会员购买、恢复购买）

### 4.5 Apple Search Ads 归因

- **包**：`pp_asa_attribution`
- **用途**：追踪来自 Apple Search Ads 的安装来源
- **实现**：首次启动时通过 AES 加密的 POST 请求上传归因数据（`isUploadedASAData` 标记防重复上传）

### 4.6 自定义插件：motion_fitness

| 平台 | 框架 | 功能 |
|-----|-----|-----|
| iOS | CoreMotion | `CMPedometer` 实时步数流 + 历史步数查询 |
| Android | SensorManager | `Sensor.TYPE_STEP_COUNTER` 硬件传感器，每日步数基线管理 |

---

## 五、未集成的常见 SDK（确认不含）

- Firebase Analytics / Crashlytics
- AppsFlyer / Adjust
- Amplitude / Mixpanel
- Sentry / Bugsnag

---

## 六、运行环境要求

| 平台 | 最低版本 |
|-----|---------|
| iOS | 15.0 |
| Android | API 26（Android 8.0） |

---

## 七、网络安全

- 所有 API 请求通过 **Dio** 发送
- 敏感参数使用 **AES 加密**后上传
- 请求头自动注入设备型号、OS 版本、网络类型、应用版本等信息
