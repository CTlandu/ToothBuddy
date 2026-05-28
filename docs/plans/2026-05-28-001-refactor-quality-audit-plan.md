---
title: "refactor: ToothBuddy quality audit — Swift 6 hardening, instrumentation, test coverage, dead code"
type: refactor
status: completed
completed: 2026-05-28
created: 2026-05-28
plan_depth: deep
origin: solo (no upstream brainstorm — this is a tech-debt audit pass, not a new product feature)
commits:
  - e03e6fd  # U1
  - f34a510  # U2
  - cfde023  # U3
  - 2b06832  # U4 + 部分 U5
  - 6a68a49  # U5
  - b0ccabf  # U6
  - 466577a  # U7
  - 7dd1274  # U8
---

# refactor: Quality Audit Pass — Swift 6 / Performance / Testing / Cleanup

## Summary

P1–P5 是 code-complete，build 0 warning、Core 108/108、App 18/18。这次不加任何用户可见功能，做一轮系统性的质量与可观测性加固，把"代码完成"升级成"可上架信心"。范围六个维度（明确**不做**无障碍）：(1) Swift 6 严格并发锁死回归通道；(2) 用 `OSSignposter` + MetricKit 把启动 / 相机 / Vision / 帧率从"声称"变成"可测量"；(3) 补 11 个 app 层 store / 服务的自动化测试；(4) 给"声称但未真验"的修复 (P5.3 reentrant / P5.2 quickLog 幂等 / P4.3 caps / P5.4 HealthKit 幂等) 加 regression 测试；(5) 清 dead code、legacy `Theme.*` namespace、orphan assets、未引用文件；(6) 量包体 / 字体 / 启动 baseline。

## Problem Frame

ToothBuddy 是单人长期产品，P1–P5 全部 ship 到 `origin/main` (latest `64af93e`)。**真实状态比 memory 里写的还干净**：

- `xcodebuild build` → **BUILD SUCCEEDED**, **0 code warnings** (`SWIFT_VERSION=6.0` 已在所有 target，Core 用 `.swiftLanguageModes: [.v6]`)
- `xcodebuild test` → **18/18 ✓**
- `cd ToothBuddyCore && swift test` → **108/108 ✓**
- TODO/FIXME 仅 1 处（`Persistence.swift:197` 是 P2.5 故意 park 的 CloudKit 标记）

但**距离"可上架信心"还有四道隐形债**：

1. **Swift 6 严发模式没有"上锁"**：现状靠 `SWIFT_VERSION=6.0` 隐含 `complete` 检查，但没开 `SWIFT_TREAT_WARNINGS_AS_ERRORS`，任何一次 dependency 升级 / Xcode bump 都可能悄悄引入并发警告而被忽略。Escape hatches (`@unchecked Sendable` × 1 / `nonisolated(unsafe)` × 2 / `@preconcurrency` × 2) 全在 `CameraService.swift` / `Persistence.swift` / `BrushingZoneMonitor.swift`，有合理注释但**没有 audit 行记录**说明它们仍然是最佳选项。
2. **零 instrumentation**：grep 全仓库 → 没有任何 `OSSignposter` / `os_signpost` / `MetricKit`。冷启动时间、`registerNunito()` 在 `MyApp.init()` 里的代价、相机会话 attach、Vision 12 fps 循环耗时、`BrushGameOverlay` Canvas+TimelineView 帧率、P4.3 声称的"≤8 bugs / ≤60 confetti caps"——全都靠"看起来对"。
3. **11 个 app 层 store/服务零自动化测试**：见 `BrushingStore.swift` / `GamificationStore.swift` / `ProfileStore.swift` / `NotificationScheduler.swift` / `HealthExporter.swift` / `BrushingZoneMonitor.swift` / `CameraService.swift` / `VisionFrameProcessor.swift` / `WidgetBridge.swift` / `VoiceCoach.swift` / `SoundManager.swift`。`Tests/ToothBuddyAppTests/` 只测了 `CareStore` / `ContentHistoryStore` / `GroupStore` / `Persistence` / `ReportPDFRenderer` + 1 个 link smoke。
4. **"声称-但-没测"的修复 silently 回归风险**：commit / CHANGELOG 里有多处"修复 X" / "确保 Y" / "≤ N"声明，但代码里查不到对应的自动化测试守门——比如 P5.3 BrushingStore reentrant `shared` 修复、P5.2 `quickLogForCurrentSlot` 每 slot 幂等、P5.4 HealthKit 写入幂等、P4.3 Canvas caps。

外加 5 项"显眼但不紧急"的卫生问题（详见 U6）：`FloatingToothBubblesView.swift` 完全没引用、legacy `Theme.*` 命名空间仍被 3 个 view 引用、`tooth.imageset` 还活着、3 个 untracked `*.jsx` / `*.html` 预览文件没有显式 `.gitignore`。

## Goals & Non-Goals

**In scope:**
- Swift 6 严发"上锁"：build-fail-on-warning + escape-hatch audit 行
- 性能 instrumentation：`OSSignposter` 在关键路径 + `MetricKit` 订阅生产数据
- App 层测试覆盖补完（11 个 store / 服务，目标 95%+ 关键 store 覆盖）
- "声称但没测"的 regression 测试补齐
- Dead code / orphan assets / legacy `Theme` 命名空间清理
- 包体 + 字体 + 冷启动 baseline 测量（一次性，留数据点不留代码改动）

**Out of scope (明确不做)：**
- **无障碍 / VoiceOver / Dynamic Type / 对比度** — 用户本轮明确排除
- P2.5b CloudKit / CKShare — 仍 park 在用户 Apple Dev 配置侧
- TestFlight / App Store 提交流程（另起 plan）
- 本地化（另起 plan）
- 新功能（音乐 / LLM / 微笑相册）
- 设计资产替换（icon / 截图 / 角色重绘）
- 修复任何不存在的 bug——这是 audit + 加固，不是 bug fix

## Requirements

| ID | Requirement | Verification |
|----|-------------|--------------|
| R1 | 任何新的并发警告 / 通用警告 都必须使 build 失败 | `xcodebuild build` 故意引入 warning 时 exits non-zero |
| R2 | Swift 6 escape hatches 全部有 audit 行注释（why this is the right choice 2026-05），列在 plan 的"Decision Log" | 代码 review + 注释 grep |
| R3 | 冷启动 / 相机 session 启动 / Vision 帧处理 / 刷牙 session / Canvas tick 都有 `OSSignposter` 区间 | Instruments → Points of Interest 看到对应 interval |
| R4 | App 装上 `MetricKit` subscriber 收 `MXAppLaunchMetric` / `MXAppResponsivenessMetrics` / `MXCPUMetric` | TestFlight 跑 24h 后能看到 payload |
| R5 | 11 个未测试 app 层 store / 服务每个至少有 happy-path + 1 个边界用例的单元测试 | `xcodebuild test` 数量从 18 涨到 ≥40 |
| R6 | "声称但没测"的修复 (P5.3 / P5.2 / P5.4 / P4.3) 各有命名为 `test_regression_<bug>` 的测试 | grep `test_regression_` 在 Tests/ 出 ≥4 处 |
| R7 | Dead code 删除：`FloatingToothBubblesView.swift`、未引用的 `Theme.*` 成员、`tooth.imageset` (前提是 `Theme.ToothImageView` 也删) | grep 后无任何引用 |
| R8 | Legacy `Theme.*` 命名空间彻底迁到 `Duo.*` 或保留有清晰 deprecation 注释 | `grep "Theme\." *.swift` 只剩有意保留项 |
| R9 | 3 个 untracked `*.jsx` / `*.html` 预览文件状态明确：要么进 `docs/` 要么显式 `.gitignore` 一行 | `git status` 干净 |
| R10 | Periphery 装上并在 `make audit` / `scripts/audit.sh` 一行可跑；首跑结果作为 baseline | `periphery scan` 退出码 0 或基线明确 |
| R11 | 包体 / 字体使用 / 冷启动 baseline 写入 `docs/audit-baseline-2026-05-28.md` | 文件存在 + 数据点完整 |
| R12 | Audit 期间所有现存测试（Core 108 + App 18）保持 100% 通过；不能因为加 instrumentation / 重命名 store 而打破现有契约 | `swift test && xcodebuild test` 全绿 |

## High-Level Technical Design

这次 plan 在架构上**不引入新抽象**——只加锁、加测、加观测、删多余。三层视图：

```
                        ┌─────────────────────────────────────┐
                        │  Audit Output (docs/, scripts/)    │
                        │   audit-baseline-2026-05-28.md     │
                        │   scripts/audit.sh                  │
                        └────────────▲────────────────────────┘
                                     │
        ┌────────────────────────────┼────────────────────────────┐
        │                            │                            │
┌───────▼────────┐         ┌─────────▼─────────┐        ┌─────────▼─────────┐
│ Build-time     │         │ Runtime           │        │ Test-time         │
│ enforcement    │         │ observability     │        │ regression net    │
│                │         │                   │        │                   │
│ • warnings as  │         │ • OSSignposter    │        │ • Store unit tests│
│   errors       │         │   on hot paths    │        │   (11 modules)    │
│ • escape-hatch │         │ • MetricKit       │        │ • test_regression_│
│   audit lines  │         │   subscriber      │        │   <bug> for       │
│ • SwiftStrict  │         │ • Logger →        │        │   claimed fixes   │
│   already      │         │   structured logs │        │ • Periphery as    │
│   enabled by   │         │                   │        │   CI gate         │
│   SWIFT_VER=6  │         │                   │        │                   │
└────────────────┘         └───────────────────┘        └───────────────────┘
        │                            │                            │
        └────────────────────────────┼────────────────────────────┘
                                     │
                        ┌────────────▼────────────┐
                        │ Existing codebase       │
                        │ (no architectural moves)│
                        └─────────────────────────┘
```

关键设计决策：

- **不引入新的依赖**（不加 Point-Free swift-concurrency-extras、不加 ViewInspector）。Periphery 是 dev 依赖（Homebrew），不进 app 二进制。
- **不重命名公共 API**，所有 store/service 现存签名保持。测试通过 `@testable import ToothBuddy` 进入。
- **Instrumentation 是加法**：所有 `OSSignposter` 调用都在生产代码里裸跑（开销 < 200ns），不需要 `#if DEBUG` 包裹；MetricKit subscriber 是 nonisolated background delivery。
- **Audit 数据 + 自动化 script 进 `docs/` + `scripts/`**，不进 app target——保持 bundle 干净。

## Key Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Warning-as-error 触发器** | `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES` in `project.yml` | Swift Forums + SE-0412 文档明确：Swift 6 mode 下 `SWIFT_STRICT_CONCURRENCY=complete` 已被隐含；锁回归的标准做法是 warnings-as-errors。代价低（现状 0 warning），收益高。 |
| **Instrumentation API** | `OSSignposter` (iOS 15+)，subsystem `com.ctlandu.ToothBuddy`，category `.pointsOfInterest` | iOS 16 baseline 完全满足；`.pointsOfInterest` 让 signpost 自动出现在 Instruments 同名 lane；现代 idiom 优于 `os_signpost`。 |
| **MetricKit 订阅时机** | `MyApp.init()` 装 subscriber，永不移除 | iOS 16.0–16.x 的 `MXMetricManager` 移除时崩 bug (Apple Forums #714616) 是已知风险；社区共识：subscribe once, 永不 remove。 |
| **Store 单元测试隔离** | 都用 in-memory `NSPersistentContainer` (URL = `/dev/null`)，参考已有的 `PersistenceTests.swift` 模式 | Donny Wals 推荐模式；和现有 6 个 app test 文件保持同种风格；无需重构 store。 |
| **HealthKit 测试** | 不真调用 HealthKit；测 `HealthExporter` 的"去重 set"和"canImport(HealthKit) 失败时无害降级"——HealthKit 副作用层不测 | 社区共识：HealthKit 没有事务，应在 protocol 后注入 fake；本项目 `HealthExporter` 已通过 `canImport(HealthKit)` 守门，直接测 decider + fake 即可。 |
| **Reentrant `shared` 回归测试** | `TaskGroup` 并发 `BrushingStore.shared` × N 次，断言 identity 唯一；不依赖 `withMainSerialExecutor` | 不引入新依赖；社区 (Hacking with Swift) 的并发测试模式 valid for 我们这一例。 |
| **P4.3 caps 测试位置** | 不在 Core (Core 是 pure rules)，在 app test 里测 `BrushGameOverlay` 的 sim state：100 spawn calls → 实际数组 ≤ 8 | Caps 是 UI 层的实现细节，应在 UI 层测；Core `BrushGame` 已有规则测试 87 个。 |
| **Periphery 调用方式** | Homebrew 装 + `scripts/audit.sh` 单条命令；不进 CI（暂时） | 单人项目，pre-submission 手动跑就够；进 CI 会破坏 Xcode-only 工作流的简洁性。 |
| **`Theme.*` legacy 处理** | 保留 namespace 但加 `@available(*, deprecated, message: "Use Duo.* instead")` 标记；不立即重构调用方 | 三个调用点 (`BrushView` / `ContentView` / `BrushGameOverlay`) 视觉效果 OK，强行迁会引入视觉风险；deprecation 注释会让任何新代码绕开它。 |
| **`tooth.imageset` 处理** | 删 + 一并删 `Theme.ToothImageView` + 改 `TipsView.swift:186` 用 `BuddyView` 替代 | `tooth.imageset` 是 SSC 时代留物，已与 Duolingo 视觉语言不一致；40K + 一个 view 删完是净收益。 |
| **预览文件去向** | `onboarding_preview.jsx` / `ToothBuddy_preview.jsx` 移到 `docs/web-previews/`；`toothbuddy-web.html` 保持 untracked 但写进 `.gitignore` 一行 | memory 明确 `toothbuddy-web.html` 是用户故意 untracked 的；两个 jsx 是设计 spike，进 `docs/` 跟其他 design 文档一起 |

---

## Output Structure

本次 plan 不创建新目录层级，但新增以下文件：

```
docs/
├── audit-baseline-2026-05-28.md      [NEW] U8 输出：包体/字体/启动 baseline
└── web-previews/                      [NEW] U6 移入
    ├── onboarding_preview.jsx
    └── ToothBuddy_preview.jsx
scripts/
└── audit.sh                           [NEW] U7 一键跑 Periphery + 构建 + Core test
Tests/ToothBuddyAppTests/
├── BrushingStoreTests.swift           [NEW] U4 + U5
├── GamificationStoreTests.swift       [NEW] U4
├── ProfileStoreTests.swift            [NEW] U4
├── NotificationSchedulerTests.swift   [NEW] U4
├── HealthExporterTests.swift          [NEW] U4 + U5
├── BrushGameOverlayCapsTests.swift    [NEW] U5
├── ZoneMonitorIntegrationTests.swift  [NEW] U4
└── WidgetBridgeTests.swift            [NEW] U4
Shared/
└── Signposts.swift                    [NEW] U2 全局 OSSignposter 单例
Support/
└── MetricsSubscriber.swift            [NEW] U3 MetricKit 入口
.gitignore                             [MODIFIED] U6 加 toothbuddy-web.html
project.yml                            [MODIFIED] U1 + U2 + U3 + U4
.periphery.yml                         [NEW] U7 Periphery 配置
```

删除：
- `FloatingToothBubblesView.swift`
- `Assets.xcassets/tooth.imageset/`
- `Theme.swift` 内 `ToothImageView` 与未引用项

---

## Implementation Units

### U1. Swift 6 严发上锁 + escape-hatch audit

**Goal:** 让任何未来 warning（并发或一般）直接 build fail；并把 5 处 escape hatch 的当下合理性钉死在代码注释里。

**Requirements:** R1, R2, R12

**Dependencies:** 无

**Files:**
- `project.yml` (修改)
- `CameraService.swift` (注释)
- `Persistence.swift` (注释 × 2 处)
- `BrushingZoneMonitor.swift` (注释)
- `ToothBuddyCore/Sources/ToothBuddyCore/` (检查无 escape hatch — 已确认)

**Approach:**
- `project.yml` 三个 target 的 `settings.base` 都加 `SWIFT_TREAT_WARNINGS_AS_ERRORS: "YES"`
- 现状 0 warning，开了不会破坏 build
- 每个 escape hatch 上方写一行 audit 注释，格式：`// AUDIT 2026-05-28: <why this is still the right choice>` — 例如 `CameraService` 的 `@unchecked Sendable` 注释里说明 "AVCaptureSession is internally synchronized; preview layer is main-only; actor wrapping would require restructuring all delegates"

**Patterns to follow:** 现有 `CameraService.swift` 顶部注释风格

**Test scenarios:**
- 手工验证：临时在 `MyApp.swift` 加一个 `print(unused: 1)` → `xcodebuild build` 必须 fail
- Test expectation: none — config 改动，由 build 系统验证

**Verification:** `xcodebuild build` 通过；`grep "AUDIT 2026-05-28" *.swift` 出 5 处

---

### U2. OSSignposter 仪表化关键路径

**Goal:** 让冷启动、profile 切换、刷牙 session 开始/结束、相机 attach、Vision 帧处理、Canvas tick 都在 Instruments → Points of Interest 里有可见 interval。

**Requirements:** R3

**Dependencies:** U1（先锁 Swift 6 再加新代码）

**Files:**
- `Shared/Signposts.swift` (新建，~30 行)
- `MyApp.swift` (init 包裹)
- `BrushView.swift` (session start/end)
- `CameraService.swift` (attach/detach)
- `VisionFrameProcessor.swift` (帧处理 interval)
- `BrushGameOverlay.swift` (sim step interval — 可选)
- `project.yml` (加 `Shared/Signposts.swift` 到 ToothBuddy target sources)

**Approach:**
- 单一全局 `let appSignposter = OSSignposter(subsystem: "com.ctlandu.ToothBuddy", category: .pointsOfInterest)`
- 每个 hot path 用 `withIntervalSignpost("Name") { ... }` 包裹
- 帧处理这种高频路径要用 `signposter.makeSignpostID()` 区分 overlapping intervals
- 不加 `#if DEBUG` — `OSSignposter` 在 release 也只是 ~200ns 开销，Apple 文档明确支持生产使用

**Patterns to follow:** 研究报告里的 `OSSignposter` 示例段；现有 `CameraService` 的注释风格

**Test scenarios:**
- 验证靠 Instruments 跑一次，看 Points of Interest lane 出 ≥6 个不同 interval name
- Test expectation: none — instrumentation 不引入新行为；现有 Core + App 测试必须 100% 通过证明无回归

**Verification:** `xcodebuild test` 18/18 不变；Instruments 手动跑一次截图入 `docs/audit-baseline-2026-05-28.md`

---

### U3. MetricKit subscriber

**Goal:** 装上 `MXMetricManager` 让 TestFlight / 上架后能收启动时间、卡顿、CPU 数据。

**Requirements:** R4

**Dependencies:** U1

**Files:**
- `Support/MetricsSubscriber.swift` (新建)
- `MyApp.swift` (init 里 `MetricsSubscriber.shared.start()`)
- `project.yml` (加 source + Info.plist 不需要改 — MetricKit 不需要 usage description)

**Approach:**
- `final class MetricsSubscriber: NSObject, MXMetricManagerSubscriber` — 单例
- `didReceive(_ payloads: [MXMetricPayload])` 和 `didReceive(_ payloads: [MXDiagnosticPayload])` 都标 `nonisolated`（研究报告明确：MetricKit 在任意后台队列回调）
- 当前阶段只 log 关键字段（`histogrammedTimeToFirstDraw` / `applicationHangTime` / `cumulativeCPUTime`）用 `Logger(subsystem:..., category: "metrics")`
- 永不调用 `MXMetricManager.shared.remove(_:)` — Apple Forums #714616 的 iOS 16 崩溃风险

**Patterns to follow:** 研究报告给的 `MetricsSubscriber` 骨架

**Test scenarios:**
- Test expectation: none — 真实数据要 TestFlight 跑 24h；本地只验 `MetricsSubscriber.shared.start()` 不崩、不阻塞 launch

**Verification:** App build 通过；`MyApp.swift` init 里能看到 `MetricsSubscriber.shared.start()` 调用

---

### U4. 补齐 11 个 app 层 store / 服务的单元测试

**Goal:** 把 app 层从 6 个测试文件扩到 ≥14 个，关键 store 都至少有 happy-path + 1 个边界。

**Requirements:** R5, R12

**Dependencies:** U1（warning-as-error 上锁后再写新代码，避免引入新警告）

**Files (新建 in `Tests/ToothBuddyAppTests/`):**
- `BrushingStoreTests.swift` — log 一条记录、跨 profile 隔离、records 不会重复入库
- `GamificationStoreTests.swift` — 分数/等级随 record 数前进、profile 切换重算
- `ProfileStoreTests.swift` — CRUD、active profile 切换、设备本地状态独立
- `NotificationSchedulerTests.swift` — 用 fake `UNUserNotificationCenter` 验断言 identifier × profile/kind 唯一性
- `HealthExporterTests.swift` — `canImport(HealthKit)` 失败/无权限时无副作用、export id set 幂等（不真触 HK）
- `ZoneMonitorIntegrationTests.swift` — `BrushingZoneMonitor.isBrushingActive` 在 mock signal stream 下的状态机
- `WidgetBridgeTests.swift` — `refresh()` 调用 App Group write、profile 切换时 reload
- `project.yml` (Tests target sources 加 8 个文件)

**Approach:**
- 全用 in-memory `NSPersistentContainer` (复用 `PersistenceTests.swift` 的工厂)
- store 单例避免：通过 `init(persistence: PersistenceController)` 注入（如果 store 当前没暴露 init，加一个 `internal init` for testing）
- HealthExporter 不真调 HealthKit；测包内的 decision / id set 逻辑
- ZoneMonitor 测的不是 Vision（那是 P4.2 真机 smoke），而是 `isActivelyBrushing` 状态机在合成 sample 下的行为

**Patterns to follow:** `Tests/ToothBuddyAppTests/PersistenceTests.swift` (128 行，已有 in-memory 模式) + `Tests/ToothBuddyAppTests/CareStoreTests.swift`

**Test scenarios per file:**
- **BrushingStoreTests:** Covers AC: log 后 records.count = 1；同一秒 log 两次去重；profile A log 不污染 profile B；reload 后保留；boundary: 跨 noon 边界的两次 log 算两个 slot
- **GamificationStoreTests:** 0 records → level 1；模拟 7 天满签到 → level 进位；profile 切换 → recompute
- **ProfileStoreTests:** create + setActive + delete → cascade；boundary: 删 active profile 后 activeProfile == nil；create 50 个 profile 不崩
- **NotificationSchedulerTests:** 用 fake `UNUserNotificationCenter` spy，验：1 record + 当前 streak → 至少 2 pending requests (morning + evening)；boundary: 无权限时 noop；reschedule 不会重复
- **HealthExporterTests:** Covers regression: 同一 session.id 调 2 次 export → 只生成 1 条 (id set)；`canImport(HealthKit)` 假装关闭时 export 无副作用且不抛
- **ZoneMonitorIntegrationTests:** 注入 mock `ZoneSample` 流，验 `isBrushingActive` true → 1.2s 无 motion → false；boundary: 连续 3 次低于阈值的 sample → debounce 不翻转
- **WidgetBridgeTests:** `refresh()` 写入 App Group UserDefaults → `WidgetSnapshot` 可读回；profile 切换触发额外 reload

**Verification:** `xcodebuild test` 数量 ≥ 40；CI grep `Tests/ToothBuddyAppTests/*.swift` 至少 14 个文件

---

### U5. "声称-但-没测"的 regression 测试

**Goal:** 把 4 处 CHANGELOG 里声称的修复 / 边界 / 幂等都转成命名清晰的 `test_regression_<bug>` 测试，未来回归会 fail。

**Requirements:** R6, R12

**Dependencies:** U4（部分 store test 文件作为载体复用）

**Files:**
- `Tests/ToothBuddyAppTests/BrushingStoreTests.swift` (在 U4 文件里加 `test_regression_reentrantSharedDoesNotCrash`)
- `Tests/ToothBuddyAppTests/BrushingStoreTests.swift` (加 `test_regression_quickLogForCurrentSlot_isIdempotent`)
- `Tests/ToothBuddyAppTests/HealthExporterTests.swift` (加 `test_regression_doubleExport_writesOnce`)
- `Tests/ToothBuddyAppTests/BrushGameOverlayCapsTests.swift` (新建 — caps regression)

**Approach:** 每个测试 doc-string 注明对应 commit / CHANGELOG 段落。

**Test scenarios:**
- `test_regression_reentrantSharedDoesNotCrash` — 用 `TaskGroup` 并发触发 100 次 `BrushingStore.shared`，断言 identity 唯一、不崩；覆盖 P5.3 commit message 里的 "reentrant static init trap" 修复
- `test_regression_quickLogForCurrentSlot_isIdempotent` — 调 `quickLogForCurrentSlot()` 3 次，断言 records 只多 1；覆盖 P5.2 spec § QuickLog
- `test_regression_doubleExport_writesOnce` — 同一 session 调 `HealthExporter.export` 2 次，断言 exported-id set 只增 1 项；覆盖 P5.4 spec idempotency
- `test_regression_canvasSimulationCaps_bugCountAtMost8` — 调 100 次 `spawnBug()`，断言 bugs.count ≤ 8；覆盖 P4.3 CHANGELOG "≤8 bugs"
- `test_regression_canvasSimulationCaps_confettiAtMost60` — 同理 60 上限

**Patterns to follow:** 命名规范 `test_regression_<short-snake-bug-id>`；每个 docstring 第一行引 commit hash / CHANGELOG 段；研究报告 Hacking with Swift 并发测试模式

**Verification:** `grep -r "func test_regression_" Tests/ToothBuddyAppTests/` 出 ≥ 5 处

---

### U6. Dead code + legacy Theme + orphan assets + untracked 预览文件

**Goal:** 把"显眼但不紧急"的卫生债一次性清掉。

**Requirements:** R7, R8, R9

**Dependencies:** U4（确保现有 test 通过后再删；删 `Theme.ToothImageView` 之前要先确认 TipsView 改完不破 UI）

**Files (删):**
- `FloatingToothBubblesView.swift` (整个文件)
- `Assets.xcassets/tooth.imageset/` (整个目录)
- `Theme.swift` (删除 `ToothImageView` 等只剩 `Theme.ToothImageView` 入口在用的项；保留还有引用的 `Theme.accentBlue` / `Theme.textPrimary` / `Theme.cameraGradient` / `Theme.appBackground` / `Theme.surfaceFrost`，但给每项加 `@available(*, deprecated, message: "Use Duo.* instead")`)

**Files (修改):**
- `TipsView.swift:186` (`ToothImageView(size: size)` → `BuddyView(size: CGSize(width: size, height: size * 1.14))` 或更简单的 SF Symbol fallback；以视觉一致为准)
- `project.yml` (sources 列表去掉 `FloatingToothBubblesView.swift`)
- `.gitignore` (加 `toothbuddy-web.html` 一行)

**Files (移动):**
- `onboarding_preview.jsx` → `docs/web-previews/onboarding_preview.jsx`
- `ToothBuddy_preview.jsx` → `docs/web-previews/ToothBuddy_preview.jsx`

**Approach:**
- 先跑 `git grep "FloatingToothBubbles"` 确认 0 引用再删
- `Theme.ToothImageView` 改 `TipsView.swift` 后再删本体
- legacy `Theme.*` 用 `@available(deprecated)` 标记，不强行迁——三个调用方视觉跑得 OK，强行替换风险大于收益
- `.gitignore` 行加完后 `git status` 必须干净

**Patterns to follow:** 现有 `.gitignore` 风格

**Test scenarios:**
- 删除后 `xcodebuild build` 必须 BUILD SUCCEEDED 且 0 warning（U1 已上锁，任何 deprecated 调用会立即 fail——这其实是 U6 + U1 联动的副作用）
- `xcodebuild test` 18 → 40+ (U4 已加) 必须全绿
- 视觉 smoke：模拟器跑一次 TipsView，确认替换 `ToothImageView` 后视觉可接受（由 user 做最终拍板）
- Test expectation: none — 删除工作；由 build + 视觉 smoke 验证

**Verification:** `grep -r "FloatingToothBubbles\|ToothImageView\|tooth.imageset" .` 仅在 `git log` 历史出现；`xcodebuild build && test` 全绿；`git status` 干净

---

### U7. Periphery 安装 + 首跑 + `scripts/audit.sh`

**Goal:** 持续 dead-code 检测的工具就绪；首跑作为 baseline。

**Requirements:** R10

**Dependencies:** U6（先清完手动发现的 dead code 再跑 Periphery，避免初次结果噪音淹没真信号）

**Files:**
- `.periphery.yml` (新建)
- `scripts/audit.sh` (新建)
- `README.md` (加一段 "Running the audit")

**Approach:**
- Homebrew 装：`brew install peripheryapp/periphery/periphery`（写进 README 而非自动化）
- `.periphery.yml` 配置 schemes / targets / `--retain-public` / 忽略 `Tests/` 和 `ToothBuddyCore/.build/`
- `scripts/audit.sh`：单文件 bash，一条线跑 `xcodegen generate` → `xcodebuild build` → `cd ToothBuddyCore && swift test` → `cd .. && periphery scan` → 总结状态
- 首跑结果作为 baseline 写入 `docs/audit-baseline-2026-05-28.md`

**Patterns to follow:** Periphery 官方 README 的 SwiftPM + Xcode project 双 target 配置

**Test scenarios:**
- 跑 `bash scripts/audit.sh` 必须退出 0（或 Periphery 报告内容为 baseline 接受范围）
- Test expectation: none — 工具脚本

**Verification:** 命令行跑 `scripts/audit.sh` 退出 0；`docs/audit-baseline-2026-05-28.md` 包含 Periphery 输出小节

---

### U8. Baseline 测量：包体 / 字体 / 冷启动

**Goal:** 留一份当下数字作为基线，给未来优化提供对比锚。一次性测，不留代码改动。

**Requirements:** R11

**Dependencies:** U1–U7 全部 ship（baseline 要测的是清理后的状态）

**Files:**
- `docs/audit-baseline-2026-05-28.md` (新建)

**Approach:**
- **包体**：Xcode → Product → Archive → Distribute → Development → enable "All compatible device variants" → 抓 `App Thinning Size Report.txt` 里的 compressed download / uncompressed install for iPhone 15 / iPhone 16
- **字体**：grep 全仓 `Nunito-(Regular|SemiBold|Bold|ExtraBold)` 出现次数，决定 4 个 weight 是否每个都真在 render；如果某个 weight 实际只有 0-1 处用且能 fallback，记下 "可移除 N KB"
- **冷启动**：Instruments → App Launch template → 真机或模拟器，记 process-start → first-frame 的 ms；同时跑 Time Profiler 看 `MyApp.init` 里 `registerNunito()` 占了多少
- 数据全写进 `docs/audit-baseline-2026-05-28.md`，每项一个小节，加日期 + 设备 + 数字 + 截图（Instruments 标签）

**Patterns to follow:** 研究报告里的 App Thinning + Instruments App Launch 路径

**Test scenarios:**
- Test expectation: none — 数据采集；准确性由人工 review

**Verification:** `docs/audit-baseline-2026-05-28.md` 存在；至少有 "包体" / "字体使用" / "冷启动" 三个有数据的小节

---

## Risks & Dependencies

| Risk | Severity | Mitigation |
|------|----------|------------|
| `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES` 在某个 Xcode 升级后引入新警告导致 build 失败 | 中 | 这其实是预期行为；如果新警告是误报，用 `// swiftlint:disable` 风格的 inline 抑制 + audit 注释 |
| `OSSignposter` 在生产代码默认开启可能轻微影响电池/性能 | 低 | Apple 文档明确 < 200ns/调用；hot path 上的总开销远低于 Vision 帧处理本身 |
| MetricKit subscriber 在 iOS 16.0–16.2 触发系统 bug 崩溃 | 低-中 | 永不 remove subscriber（已写进 U3 approach）；崩溃日志通过 MXCrashDiagnostic 自动收集 |
| `Theme.*` deprecation 标记会让三个现有 view 全部 warning → 因 U1 直接 build fail | 中 | U6 必须在 U1 之后；或者 deprecation 行加 `#if false` 暂时关掉直到迁移；plan 推荐顺序：U1 → U2 → U3 → U4 → U5 → U6（U6 时 deprecation 暂时只加给 `ToothImageView` 那条已删的；其余 `Theme.*` 留下注释 TODO，不加 deprecated）|
| 写 11 个 store 测试时发现 store 的 `init` 不接受注入 → 需要给 store 加 internal init | 中 | 可接受；改动小、不破公共 API |
| Periphery 误报大量 SwiftUI body / preview 为 unused | 中 | `.periphery.yml` 加 `--retain-public --retain-objc-accessible` + 显式 exclude；首次结果作为 baseline 接受 |
| HealthKit 测试中 `canImport(HealthKit)` 永远是 true on iOS（编译期），无法测降级路径 | 低 | 把降级逻辑抽到一个 protocol+impl，protocol 注入 fake；只测 protocol-injected 那一层 |

## Scope Boundaries

### 在范围内（本 plan 覆盖）
- 性能 instrumentation + baseline
- Swift 6 严发上锁 + escape hatch audit
- App 层 store/service 单元测试补完
- "声称-但-没测"的 regression 测试
- Dead code / legacy Theme deprecation / orphan assets / untracked 预览文件
- Periphery 工具就绪 + 一次性 baseline 数据

### Deferred to Follow-Up Work（明确推到下一轮，但属于"质量"主题）
- 把 legacy `Theme.*` 三个调用方真正迁到 `Duo.*`（视觉风险，需要 design pass）
- XCUITest 黄金路径覆盖（onboarding + log 一次 brushing + create profile）
- CI 集成 Periphery + `scripts/audit.sh`
- 把 `MetricsSubscriber` 的 payload 上传到某个 telemetry 服务（首版只 log，不上报）

### Outside this product's identity / 另开 plan
- **无障碍 / VoiceOver / Dynamic Type / 对比度审计**（用户本轮明确排除）
- **TestFlight / App Store 提交流程**（独立 plan）
- **本地化**（独立 spec）
- **P2.5b CloudKit 解封**（user-blocking on Apple Dev setup）
- **新功能：音乐同步、LLM 故事、微笑相册**（各自走 spec → confirm → plan 流程）
- **设计资产更新**（App icon、截图、角色重绘）

## Open Questions

| Question | Resolution path |
|----------|-----------------|
| Periphery 是否进 CI？ | 默认不进；用户后续决定 |
| `MetricsSubscriber` 当前阶段只 log，下一步是上报 Sentry / 自建后端 / 完全不上报？ | 等本 plan ship、TestFlight 跑一周看 payload 体量再定 |
| `BrushGameOverlay` caps 测试需要 expose 内部 sim state 吗？ | U5 决策时再看；如要 expose，加 `internal` 访问而非 `public` |
| U6 里 `TipsView` 的 `ToothImageView` 替换具体用什么？ | 实施时跑模拟器对比 `BuddyView` vs SF Symbol vs 完全删；用户拍板 |

## Verification (Plan-Level)

ship 全部 8 个 U 之后：
- `xcodebuild build` 0 warning 0 error
- `xcodebuild test` ≥ 40 tests pass
- `cd ToothBuddyCore && swift test` 108 tests pass（不变）
- `git status` 干净
- `bash scripts/audit.sh` 退出 0
- `docs/audit-baseline-2026-05-28.md` 包含包体 + 字体 + 冷启动 + Periphery + Instruments 截图五个小节
- 任何尝试引入并发警告的改动会立即被 build 拒绝（U1 已上锁）

## Sources & Research

- 研究报告 1：Swift 6 strict concurrency + iOS instrumentation（OSSignposter / MetricKit 文档 + Apple 官方）
- 研究报告 2：iOS app quality audit 社区共识 (Sundell / Wals / fatbobman / Spotify / Booking)
- 本仓库：`ROADMAP.md` + `PLAN.md` + `CHANGELOG.md` + memory: `project-progress` / `design-refactor`
- 工具：[Periphery](https://github.com/peripheryapp/periphery) 3.x，[swift-concurrency-extras](https://github.com/pointfreeco/swift-concurrency-extras)（参考但不引入）
- 关键 Apple 文档：[OSSignposter](https://developer.apple.com/documentation/os/ossignposter)、[MetricKit](https://developer.apple.com/documentation/MetricKit)、[Adopting Swift 6](https://developer.apple.com/documentation/swift/adoptingswift6)
- 关键社区写作：[Donny Wals - Singletons in Swift 6](https://www.donnywals.com/using-singletons-in-swift-6/)、[fatbobman - Swift 6 in a Camera App](https://fatbobman.com/en/posts/swift6-refactoring-in-a-camera-app/)、[SwiftLee - MetricKit launch-time tracking](https://www.avanderlee.com/swift/metrickit-launch-time/)
