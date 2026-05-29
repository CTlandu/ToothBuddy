# ToothBuddy Feature Inventory

写于 2026-05-29。一份简洁 spec list，按用户视角的功能模块组织。每条标注：做什么、关键文件、实现思路、状态。

代码侧自检（2026-05-29）：
- `bash scripts/audit.sh` → 全过
- ToothBuddyCore 108/108 ✓、App 42/42 ✓
- xcodebuild 0 warning（warnings-as-errors 开启中）
- 唯一缺：Periphery 死代码扫描没装（可选，`brew install peripheryapp/periphery/periphery` 后补）

—— 文件路径全部相对 repo 根（`/Users/ctlandu/Documents/GitHub/ToothBuddy.swiftpm`）。

---

## 1. 刷牙主流程

### 1.1 2 分钟刷牙 session（计时 + 摄像头）
- **做什么**：用户点 "Start Brushing"，前置摄像头开启，2 分钟倒计时启动，画面实时显示口腔分区指示。摄像头帧不录制。
- **入口**：BrushView（Brush tab）
- **关键文件**：`BrushView.swift`、`BrushingStore.swift`、`CameraPreviewView.swift`、`CameraService.swift`
- **实现**：AVFoundation 抓帧 → 后台队列处理 → BrushingStore 持有 session 状态（@Published）→ SwiftUI 订阅渲染
- **状态**：✓ 已实现

### 1.2 Vision 口腔分区识别（6 区）
- **做什么**：识别用户脸部 + 手部位置，映射成 6 个口腔分区（左上、右上、左下、右下、前上、前下），刷到哪个区有视觉反馈。
- **关键文件**：`VisionFrameProcessor.swift`、`BrushingZoneMonitor.swift`、`ToothBuddyCore/Sources/ToothBuddyCore/ZoneGuidance.swift`
- **实现**：Vision 限频 ≤12fps；脸部关键点 + 手部姿态 → ZoneSample → 推送到 ZoneMonitor（singleton 流）
- **状态**：✓ 已实现；真机左右翻转需要 device smoke 校准

### 1.3 Sugar Bugs 小游戏（kid mode 限定）
- **做什么**：刷牙时画面上漂"糖虫"，刷到对应区就消灭，全清触发 confetti。
- **关键文件**：`BrushGameOverlay.swift`、`ToothBuddyCore/Sources/ToothBuddyCore/BrushGame.swift`、`SoundManager.swift`
- **实现**：纯函数游戏状态（spawn / clearing / fading 三态机）→ view 订阅状态渲染。kid 才显示，adult 隐藏。
- **状态**：✓ 已实现
- **Spec**：`specs/04-3-brush-game.md`

### 1.4 Live Activity（锁屏 + 灵动岛）
- **做什么**：刷牙时锁屏和灵动岛显示剩余秒数 + 当前分区。
- **关键文件**：`BrushingLiveActivity.swift`、`Shared/BrushingActivityAttributes.swift`、`Widget/BrushingLiveActivityWidget.swift`
- **实现**：ActivityKit `ActivityContent<T>` API；start → 每秒 update → end on stop。冷启动清残留。
- **状态**：✓ 已实现；只能真机验证

### 1.5 Done sheet（完成弹窗）
- **做什么**：到点或手动结束后弹全屏 sheet，kid 模式显示星星 + 反馈、adult 模式安静摘要。确认后写 Core Data + 触发 Health 导出 + 重排提醒 + 同步 Widget。
- **关键文件**：`BrushView.swift`（showDoneSheet 状态）、`BrushingStore.swift`（addRecord）
- **状态**：✓ 已实现

---

## 2. 习惯 & 连击系统

### 2.1 宽容连击（forgiving streak）
- **做什么**：漏刷一天不会立刻断；每攒 ~7 天积一次"豁免额度"；连续漏刷 2 天才真正断。
- **关键文件**：`ToothBuddyCore/Sources/ToothBuddyCore/StreakEngine.swift`、`BrushingStore.swift`
- **实现**：纯函数 `StreakEngine.compute(records, config)` → 输出 StreakResult（currentStreak / longestStreak / frozenDays）。算法：锚定今天 → 反向走 → 修剪 grace 预算。
- **状态**：✓ 已实现
- **Spec**：`specs/01-habit-engine.md`

### 2.2 最长记录（longest streak）
- **做什么**：单独追踪历史最高连击，只升不降。
- **关键文件**：`StreakEngine.swift`（compute 时全程扫描记录历史）
- **状态**：✓ 已实现

### 2.3 自适应提醒
- **做什么**：根据最近 14 次刷牙时间的中位数，自动学早晚提醒时间。<3 次用默认 08:00 / 20:30。
- **关键文件**：`ToothBuddyCore/Sources/ToothBuddyCore/ReminderPlanner.swift`、`NotificationScheduler.swift`
- **实现**：纯函数 → 输出 [ReminderPlan(kind, fireDate)] → 应用层调 UNUserNotificationCenter
- **状态**：✓ 已实现；用户暂时不能手动改时间

### 2.4 连击濒危提醒（streak-at-risk）
- **做什么**：晚 20:30 之前还没刷 + 当前 streak > 0，发一条"你的 N 天连击有风险"温和通知。
- **关键文件**：`ReminderPlanner.swift`（条件判断）、`NotificationScheduler.swift`（去重：和 evening routine 60 分钟内只发一条）
- **状态**：✓ 已实现

---

## 3. 多档案家庭

### 3.1 档案 CRUD（最多 8 个）
- **做什么**：每个设备最多创建 8 个档案，每档案有名字、颜色、symbol、可选出生年、创建人 label。切换档案 UI 全部刷新成该档案视角。
- **关键文件**：`ProfileStore.swift`、`ProfilePickerView.swift`、`Persistence.swift`（CDProfile）
- **实现**：Core Data CDProfile + UserDefaults 存 activeProfileID；所有 store 监听 activeProfileID 变化并 reload。
- **状态**：✓ 已实现
- **Spec**：`specs/02-family-layer.md`

### 3.2 kid / adult 模式（per-profile）
- **做什么**：每个档案标记 kid 或 adult。adult 模式去掉星星 / confetti / Sugar Bugs，换成安静的习惯曲线，内容默认 essentials tone。
- **关键文件**：`ToothBuddyCore/Sources/ToothBuddyCore/Profile.swift`（mode enum）、`BrushView.swift` / `HistoryView.swift` / `HabitCurveView.swift`
- **状态**：✓ 已实现
- **Spec**：`specs/05-adult-apple.md`

### 3.3 家庭面板（无管理员角色）
- **做什么**：列出本机所有档案，每个显示连击、活跃天数、完美天数。没有角色权限，谁都能看谁。
- **关键文件**：`GroupDashboardView.swift`、`GroupStore.swift`、`ToothBuddyCore/Sources/ToothBuddyCore/DashboardMetrics.swift`
- **实现**：纯聚合函数 `DashboardMetrics.compute(records, profileID, config)` → 每档案输出一行 metric
- **状态**：✓ 已实现（本地）；CloudKit 多端同步 P2.5 deferred

### 3.4 关怀提醒（刷头 / 牙医）
- **做什么**：每档案分别追踪上次换刷头（默认 90 天周期）+ 上次看牙医（默认 180 天）。临近 due 出提示 chip + 系统通知。
- **关键文件**：`CareStore.swift`、`ToothBuddyCore/Sources/ToothBuddyCore/CareDueCalculator.swift`、`CareReminderPlanner.swift`、`NotificationScheduler.rescheduleCare()`
- **状态**：✓ 已实现

### 3.5 PDF 报告导出（per-profile）
- **做什么**：导出某档案的刷牙历史 PDF：档案名 + 日期范围 + 总 session + 活跃天数 + 连击数据 + 日历网格（绿=完美、蓝=活跃、灰=漏）。可分享。
- **关键文件**：`ReportPDFRenderer.swift`、`ToothBuddyCore/Sources/ToothBuddyCore/ReportBuilder.swift`
- **实现**：纯 ReportBuilder → ReportData；UIGraphicsPDFRenderer 画 PDF；写临时文件给 share sheet
- **状态**：✓ 已实现；仅 smoke 测试，没单测

---

## 4. 内容引擎

### 4.1 Tips 静态库
- **做什么**：可滚动的分类刷牙小贴士（技巧 / 习惯 / 科学 / 营养 / 趣味），有阅读时长 + 可展开 markdown。
- **关键文件**：`TipsView.swift`（UI + 静态数据）
- **状态**：⚠️ 部分实现 —— 内容是静态数组、未接 ContentEngine 的"无重复"动态选择器
- **Spec**：`specs/03-content-engine.md`

### 4.2 Session 脚本 + TTS 配音
- **做什么**：2 分钟 session 期间，TTS 念脚本：开场 → 每区提示 → 中段一个内容（事实 / 笑话 / 小贴士，按 tone 区分）→ 收尾。
- **关键文件**：`BrushView.swift`（cue 时机）、`VoiceCoach.swift`（AVSpeechSynthesizer）、`ToothBuddyCore/Sources/ToothBuddyCore/SessionScript.swift`、`ContentEngine.swift`
- **实现**：纯函数 SessionScript.build(durationSeconds, tone, content) → ScriptCue 时间线；运行时按秒触发 TTS
- **状态**：⚠️ 部分实现 —— 静态脚本骨架已 OK，动态内容选择器在 Core 写好了但 BrushView 还没接上

### 4.3 内容历史（per-device 无重复）
- **做什么**：本机最近 8 条内容 ID 的环形 buffer，避免重复；同时存 tone（kid 默认 playful、adult 默认 essentials）
- **关键文件**：`ContentHistoryStore.swift`、`ToothBuddyCore/Sources/ToothBuddyCore/ContentSelector.swift`
- **实现**：UserDefaults 存 ring buffer + tone；ContentSelector 过滤掉最近 N 条
- **状态**：✓ 已实现

### 4.4 课程解锁（按活跃天数）
- **做什么**：口腔健康课，N 节；用户每攒 2 个活跃刷牙天解锁一节。
- **关键文件**：`ToothBuddyCore/Sources/ToothBuddyCore/CourseProgression.swift`
- **状态**：⚠️ 部分实现 —— 逻辑写好了，课程内容没整理、UI 锁/解锁状态徽章 TBD

---

## 5. 游戏化

### 5.1 成就徽章（kid 限定）
- **做什么**：First Brush / 7 天连击 / Level Up / Perfect Week 等可解锁徽章，每个有 icon + title + 描述。HistoryView 显示成就网格。
- **关键文件**：`GamificationStore.swift`、`Persistence.swift`（CDAchievementUnlock）
- **实现**：每档案独立 unlocked Set；条件触发解锁；Core Data 持久化
- **状态**：✓ 已实现（8 个成就）

### 5.2 等级（kid 限定，按 session 总数 0–5 级）
- **做什么**：1+ session → Lv1 Getting Started、5+ → Lv2 Rising Star、15+ → Lv3 Brushing Pro、30+ → Lv4 Super Brusher、50+ → Lv5 Tooth Champion
- **关键文件**：`GamificationStore.swift`（level computed property）
- **状态**：✓ 已实现

### 5.3 Sugar Bugs 全清胜利
- **做什么**：游戏所有糖虫清完 → confetti + 庆祝状态 + 可触发关联成就
- **关键文件**：`BrushGameOverlay.swift`、`ToothBuddyCore/Sources/ToothBuddyCore/BrushGame.swift`
- **状态**：✓ 已实现

### 5.4 ⏳ 积分换帽子（未实现，规划中）
- **做什么**：未来 in-app gamification —— 用户用积分解锁 Buddy 的不同帽款（棒球帽是第一个，已在 App Icon 里登场）
- **状态**：✗ 未实现，等 1.x 版本

---

## 6. Apple 生态集成

### 6.1 HealthKit 导出（只写不读）
- **做什么**：session 完成后，若用户授权，写一条 HKCategorySample（`.toothbrushingEvent`）到 Apple Health。按 record UUID 去重幂等。
- **关键文件**：`HealthExporter.swift`、`ToothBuddyCore/Sources/ToothBuddyCore/HealthExportDecider.swift`
- **实现**：只申请 share 权限、不申请 read。UserDefaults 存已导出 record ID set 做幂等
- **状态**：✓ 已实现

### 6.2 Siri / App Intents（3 个）
- **做什么**：
  - "I brushed my teeth in ToothBuddy" → 快速记录当前 slot（幂等）
  - "Start brushing in ToothBuddy" → 打开 app + 开始 session
  - "What's my streak?" → 读 streak 数
- **关键文件**：`ToothBuddyIntents.swift`、`BrushingIntentBridge.swift`、`AppShortcuts.xcstrings`（6 条中文短语）
- **实现**：iOS 16+ AppIntents，进程内执行，幂等按 slot 检查
- **状态**：✓ 已实现（含中英双语短语）

### 6.3 主屏 Widget（streak 显示）
- **做什么**：小号 / 中号 widget 显示当前档案 streak + 火焰 icon + 今日早/晚刷牙状态。点开进 Brush tab。
- **关键文件**：`Widget/StreakWidget.swift`、`ToothBuddyCore/Sources/ToothBuddyCore/WidgetSnapshot.swift`、`WidgetBridge.swift`
- **实现**：App Group `group.com.ctlandu.ToothBuddy` 共享 UserDefaults 存 WidgetSnapshot；widget 30 分钟 + app 主动 reload 取数；不直接查 Core Data
- **状态**：✓ 已实现

---

## 7. Onboarding

### 7.1 首启动 slides
- **做什么**：5 张可滑动全屏卡（welcome → 摄像头 → 计时器 → 成就 → 历史）+ 1 张 ready 收尾。可跳过。
- **关键文件**：`OnboardingView.swift`
- **实现**：TabView `.page` 风格 + AppStorage `hasCompletedOnboarding` flag
- **状态**：✓ 已实现

### 7.2 首档案创建 gate
- **做什么**：onboarding 完后若没档案，强制 ProfilePickerView gate 模式（输名字 + 选颜色 + 选 symbol），创建后才能进 app。
- **关键文件**：`ProfilePickerView.swift`（isGate 参数）
- **状态**：✓ 已实现

### 7.3 权限渐进申请
- **做什么**：不一次性弹一堆权限。摄像头 → 第一次进 BrushView 时申请；通知 → 第一次完成 session 后申请；Health → 在 HistoryView 的开关里申请
- **关键文件**：`BrushView.swift`、`NotificationScheduler.swift`、`HealthExporter.swift`
- **状态**：✓ 已实现

---

## 8. 持久化 & 状态

### 8.1 Core Data 单 store（CloudKit-ready）
- **做什么**：所有数据存本地 Core Data；用 NSPersistentCloudKitContainer 做容器，但目前只跑私有 store（CloudKit sync 留作 P2.5）
- **关键文件**：`Persistence.swift`（程序化 NSManagedObjectModel：CDProfile / CDBrushingRecord / CDAchievementUnlock / CDProfileCare / CDGroup）
- **实现**：没 .xcdatamodeld 文件、纯代码定义。所有属性 optional + 默认值（CloudKit 兼容必需）
- **状态**：✓ 已实现

### 8.2 档案隔离
- **做什么**：BrushingRecord / CDAchievementUnlock / CDProfileCare 都强制关联 profile；切档案触发各 store reload
- **关键文件**：`BrushingStore.swift` / `GamificationStore.swift` / `CareStore.swift`（都 NSFetchRequest predicate `profile.id == %@`）
- **状态**：✓ 已实现

### 8.3 全局 store（singleton 列表）
| Store | 作用 | 持久化 |
|---|---|---|
| BrushingStore | session 状态 + records + streak | Core Data |
| ProfileStore | 档案列表 + 当前选中 | Core Data + UserDefaults |
| GamificationStore | per-profile 成就解锁 | Core Data |
| CareStore | per-profile 关怀日期 | Core Data |
| GroupStore | 家庭组名（占位） | Core Data |
| ContentHistoryStore | per-device 内容历史 + tone | UserDefaults |
| BrushingIntentBridge | Siri → BrushView 桥 | 内存 |
| BrushingZoneMonitor | Vision 分区流 | 内存 |
| VoiceCoach | TTS 状态机 | 内存 |

---

## 9. 本地化

### 9.1 中英双语
- **做什么**：UI 文案 en / zh-Hans 双语，跟随系统语言切换
- **关键文件**：`Localizable.xcstrings`（~120 条）、`AppShortcuts.xcstrings`（6 条 Siri 短语）、`Support/Info.plist`（CFBundleLocalizations）
- **实现**：String Catalogs（Xcode 15+）；代码用 `String(localized:)` 和 `LocalizedStringKey`
- **状态**：✓ 已实现 UI；⚠️ 内容资产中文化 deferred（ContentLibrary、BrushingTip 长描述、Lesson 内容、Achievement.description、TTS 念稿都 fallback 英文 —— 之后单独 plan 处理）

---

## 10. 设计系统

### 10.1 Duolingo 风格 Duo* 原语
- **做什么**：DuoTheme 集中色板（ink / cream / green / blue / yellow / red / blush / plaque-green / foam-fill）、字体（Nunito 4 种字重）、布局常量（4pt offset shadow / 2pt outline / 14pt corner radius）
- **关键文件**：`DuoTheme.swift`、`DuoComponents.swift`、`DuoCharacters.swift`
- **状态**：✓ 已实现；新视图（GroupDashboard / HabitCurve / Onboarding / StreakWidget）全部用 Duo.*

### 10.2 旧 Theme（共存中）
- **做什么**：早期 Theme.* token（textPrimary / accentBlue / surfaceFrost 等）
- **关键文件**：`Theme.swift`
- **状态**：⚠️ 仍在用 —— BrushView / HistoryView / TipsView 还引用 Theme.*；视觉重构是文件粒度推进的，没全清完

### 10.3 Nunito 字体
- **做什么**：4 个字重的 Nunito 字体打包进 bundle，冷启动时 CTFontManagerRegisterGraphicsFont 注册
- **关键文件**：`MyApp.swift`（registerNunito）、`Nunito-*.ttf` 4 个文件
- **状态**：✓ 已实现

---

## Spec 文件覆盖

| Spec | 实现情况 |
|---|---|
| `specs/01-habit-engine.md` | ✓ 全实现 |
| `specs/02-family-layer.md` | ✓ 本地全实现；CloudKit 多端 P2.5 deferred |
| `specs/03-content-engine.md` | ⚠️ 部分（动态选择器和课程 UI 未接上）|
| `specs/04-camera-guidance.md` | ✓ 实现（含 04-2-vision-adapter）|
| `specs/04-2-vision-adapter.md` | ✓ 全实现 |
| `specs/04-3-brush-game.md` | ✓ 全实现 |
| `specs/05-adult-apple.md` | ✓ 全实现 |

---

## 总览

**完全实现的（用户可见全 ship）：** 1.x 主流程、2.x 习惯系统、3.x 多档案家庭、5.1–5.3 游戏化、6.x Apple 集成、7.x onboarding、8.x 持久化、9.1 本地化（UI 部分）、10.1 + 10.3 Duo 设计系统

**部分实现 / 内部规划：**
- 4.1 Tips 静态库 + 4.2 Session 脚本动态内容选择 + 4.4 课程解锁 UI —— ContentEngine 在 Core 里写好了，但 UI 层还没全接上
- 9.1 中文化 —— UI 全双语，内容资产（长描述、念稿）只英文
- 10.2 Theme / Duo 共存 —— 视觉重构没全清完

**未实现 / 规划中：** 5.4 积分换帽子（gamification 配饰系统）、3.x CloudKit 多端同步

—— end ——
