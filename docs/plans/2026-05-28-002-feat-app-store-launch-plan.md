---
title: "feat: ToothBuddy 1.0 App Store 上架准备 — 资产 / 合规 / 双语 / TestFlight"
type: feat
status: completed
completed: 2026-05-28
created: 2026-05-28
plan_depth: deep
origin: solo (no upstream brainstorm — operational launch plan, not a new product feature)
commits:
  - 0f7d0fc  # U1 first pass (plain tooth)
  - fdd6a2c  # U1 final (cap + brush + face)
  - 9204494  # U2 Launch Screen
  - ec8c814  # U3 Category + permission copy
  - 1ff55ba  # U4 Privacy + Support markdown
  - 0ba8a5d  # U5 String Catalog infra
  - b74f10f  # iOS 17 bump (unblocks U7)
  - 91a673d  # U6 (1/2) Onboarding + ContentView + BrushView
  - b24900f  # U6 (2/2) History + Group + Tips + Profile + HabitCurve + GameOverlay
  - dc66529  # U7 AppShortcuts zh-Hans
  - 754650f  # U8 Notification + Widget + Achievement titles
  - 223cd38  # U9 + U10 + U11-13 docs (listing + screenshots + testflight)
remaining_user_actions:
  - Replace [VERCEL] placeholder URLs in app-store-listing.md once Vercel pages live
  - Capture 20 screenshots (5 × 2 locales × 2 devices) per docs/app-store-screenshots/README.md
  - Optional 30s App Preview video
  - Archive + upload via Xcode Organizer
  - TestFlight Internal + smoke checklist
  - Submit for App Store review
---

# feat: ToothBuddy 1.0 App Store Launch

## Summary

P1–P5 代码完成、quality audit 也刚 ship。**距离"用户能在 App Store 搜到并下载"还差全部非代码工作 + 一块本地化代码改动**。这个 plan 把"产品 ship 完"和"真正 ship 给用户"之间的所有缺口一次补齐：app icon、launch screen、healthcare-fitness 分类切换、强化的权限文案、隐私政策网页（用户自己 Vercel 托管，本 plan 提供 markdown 源 + 占位 URL）、英文 + 简体中文双语（infrastructure + UI 文案）、App Store metadata 中英两套、双设备双语截图、TestFlight 内测、Beta App Review、首次正式提审。**明确不在范围**：CloudKit（P2.5b 独立 plan）、新产品功能、内容资产中文化（TTS scripts / Tips library / Course lessons / Achievement descriptions——独立的内容工程 plan）。

---

## Problem Frame

**现状（2026-05-28，audit pass 完成后）**：
- 代码已 ship 到 `origin/main`，P1–P5 全部 code-complete，42 app test ✓ / 108 Core test ✓ / 0 warning
- `docs/app-store-review-notes.md` 已写得很详细（HealthKit 流程 / 权限 / 离线性质 / 测试步骤）
- `Support/PrivacyInfo.xcprivacy` 已补（commit `e7b90e0`）
- `Support/Info.plist` 已有 `NSCameraUsageDescription` / `NSHealthUpdateUsageDescription` / `NSSupportsLiveActivities` / `UILaunchScreen={}`
- DEVELOPMENT_TEAM 89A8S223WV 已配置

**距离能上架还差的 5 类东西**：

1. **视觉资产** — `Assets.xcassets/AppIcon.appiconset` 不存在（`ASSETCATALOG_COMPILER_APPICON_NAME=""` 是占位）；`UILaunchScreen` 是空 dict（默认黑屏一闪）
2. **合规分类微调** — `LSApplicationCategoryType=public.app-category.medical` 会触发 Apple 医疗类严格审查（含 2026 春新增的 "Regulated Medical Device declaration"），与产品 "engagement-grade not clinical" 定位不符，应降到 `healthcare-fitness`；Camera/Health 权限文案要从"够用"升到"reviewer 友好的具体描述"
3. **法务文档** — Apple 强制要求 Privacy Policy URL（HealthKit 使用强制了 5.1.3）、Support URL；都没有
4. **双语化（用户明确加进来的范围）** — 0 Localizable.strings、0 .lproj、Siri phrases 3 处英文硬编码、11 个 view 文件英文字面量、Widget/Live Activity/通知文案英文硬编码。**做完=app 内 UI 主流路径全中文化**
5. **商店资产** — Metadata（title/subtitle/description/keywords/category/age rating）双语版没写；截图（iPhone 6.9" + iPad 13"）一张没有；App Preview video 可选但强力对抗 4.2 minimum functionality 拒因

**"声称-但-没真验"的法律风险**：当前 Info.plist 的 medical 分类 + audit notes 反复声明 "guidance-grade not clinical" 是矛盾的。审查时如果 reviewer 顺着 medical 分类问"是不是医疗器械 app"就走错通道了。U3 优先级 P0。

## Goals & Non-Goals

**In scope**:
- App icon（SVG 源 + 3 variants PNG + AppIcon.appiconset 集成）
- Launch screen（简单 SwiftUI 风格 + UILaunchScreen 配置）
- Category 切到 `healthcare-fitness` + 强化所有权限 usage description
- Privacy Policy + Support page（Markdown 源进仓库，HTML 渲染由用户 Vercel 托管）
- 本地化基础设施（String Catalog + `en` + `zh-Hans` + CFBundleLocalizations）
- App 内主流路径 UI 文案双语化（onboarding / 主屏 / brush / done sheet / profile / history / tips / group / widget / live activity / 通知 / Siri phrases / achievement names）
- App Store Connect metadata 中英双语（title / subtitle / promotional text / description / keywords / category / age rating / privacy nutrition label / required URLs）
- App Store 截图（iPhone 6.9" + iPad 13"，每语言 3-5 张）
- TestFlight 内测流程（先 internal 100 名额，再考虑 external）
- 首次 App Store 提审 + 评审注释打磨

**Out of scope（独立 plan / 后续）**:
- **内容资产中文化**：`ContentLibrary` (`ContentEngine.swift`)、`CourseLibrary` (`CourseProgression.swift`)、`TipsView.swift` 里 `BrushingTip` 数组的长文本、`Achievement.description`、TTS 朗读的英文 prompt——这些是"内容工程"不是字符串本地化。中文 locale 下显示英文 fallback，运行不破，体验有缺口；单开内容 plan 解决
- **CloudKit / P2.5b**：仍 park
- **新产品功能**（音乐、LLM、微笑相册）
- **iOS 26 Liquid Glass Icon Composer 升级**（可选未来）
- **App Preview video 第二版**（先做一版够用，迭代后续）
- **Marketing URL 站**（非必需）
- **Apple Watch / iPad-原生体验**（iPad 用 universal 跑就行，不做 iPad-only UI 优化）
- **Push notifications / APNs**（产品全离线，不做）
- **Apple Search Ads / ASO 优化**（上架后再说）

---

## Requirements

| ID | Requirement | Verification |
|----|-------------|--------------|
| R1 | `Assets.xcassets/AppIcon.appiconset` 存在并包含 Light + Dark + Tinted 三套 1024×1024 PNG；`project.yml` 设 `ASSETCATALOG_COMPILER_APPICON_NAME="AppIcon"` | `xcodebuild build` 在 dev sim / 真机 home screen 显示真 icon 不是占位 |
| R2 | Launch screen 不再是黑屏一闪，至少有 ToothBuddy 字样 + 品牌色 | 模拟器冷启动看一眼 |
| R3 | `LSApplicationCategoryType` 改成 `public.app-category.healthcare-fitness` | grep Info.plist + App Store Connect 选择对应类目 |
| R4 | Camera / Health / Notification usage description 都符合 Apple 2026 "具体描述" 标准（≥ 1 句，说明 what / when / where data goes） | 与 docs/app-store-review-notes.md 对照逐字核 |
| R5 | Privacy Policy markdown 源在 `docs/legal/privacy-policy.md`；Support page 同理；包含 HealthKit / Camera / 通知 / 离线声明 / 联系邮箱 | 文件存在 + 内容覆盖 |
| R6 | App 内增加 `en.lproj` + `zh-Hans.lproj`（由 String Catalog 编译生成）；`Info.plist` 含 `CFBundleLocalizations=[en, zh-Hans]`；`CFBundleDevelopmentRegion=en` | `plutil -p` 看 plist 字段 |
| R7 | 主流路径所有 UI 字符串通过 `String Catalog` 注册：onboarding / brush 主屏 / done sheet / profile picker + create / history / tips / group dashboard / widget / live activity / 系统通知 body / 3 个 Siri intent phrases + Achievement 标题 | 模拟器切语言到 zh-Hans，主流路径全中文显示，不漏不混 |
| R8 | App Store Connect metadata 文档（仓库内 `docs/app-store-listing.md`）含两份完整 metadata: en + zh-Hans，覆盖 title / subtitle / promotional text / description / keywords / what's new / age rating questionnaire 答案 / privacy nutrition label 答案 / support URL / privacy URL / category / sub-category | 文件存在 + 字段齐全 |
| R9 | App Store 截图：iPhone 6.9" (1320×2868) 3-5 张 + iPad 13" (2064×2752) 3-5 张 × 双语 = 12-20 张总 | 文件在 `docs/app-store-screenshots/` |
| R10 | App Preview video（可选）：15-30s，含 brushing session + Vision overlay + Live Activity + Sugar Bugs 至少一处亮眼镜头 | 视频文件存在或显式 deferred |
| R11 | TestFlight 内测 build 至少 1 个 ship；自己 + 邀请的 testers 至少跑一遍主流路径 | App Store Connect 内测 build 状态 + tester 反馈记录 |
| R12 | docs/app-store-review-notes.md 是上传给 App Review 时实际复制的版本：含 HealthKit 写-only 申明、相机不录帧申明、无网络申明、无账号无 demo 申明、`Regulated Medical Device declaration = No` 申明 | 文档存在 + 内容覆盖 |
| R13 | Audit 全部 42 + 108 测试持续通过；本地化与 App Icon 改动后 build 0 warning（U1 warnings-as-errors 锁仍有效） | `bash scripts/audit.sh` 退出 0 |
| R14 | `LocalizedStringResource` 在 AppIntents 用法符合 Swift 6 strict concurrency（不引入新警告破坏 R13） | build clean |

---

## Key Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **本地化技术栈** | String Catalog (`.xcstrings`)，不用 legacy `.strings` + `.stringsdict` | Apple 在 WWDC23 Session 10155 推荐；Xcode 26 v1.1 自动 symbol；plural 形式 UI 处理；greenfield 无迁移成本 |
| **本地化 API 用法** | View 内 `Text("Hello")` 等隐式 `LocalizedStringKey`；纯 `String` 用 `String(localized: "...")`；跨边界（AppIntents 参数标题 / phrases）用 `LocalizedStringResource` | 研究报告明确建议；与 SwiftUI 现有 idiom 一致 |
| **Siri phrases 本地化文件** | 单独 `AppShortcuts.xcstrings`，不混在 `Localizable.xcstrings` | Apple 文档要求；Forums #803490 案例；Chinese 可加多 phrase 变体 |
| **CFBundleDevelopmentRegion** | `en`（保持英文为源；zh-Hans 是翻译目标） | 仓库已有英文 source code；如改 zh-Hans 为源会要求把所有字面量翻成中文 |
| **App Icon 路径** | 经典 `AppIcon.appiconset`（Light + Dark + Tinted 三套 1024×1024 PNG）；不上 iOS 26 Liquid Glass `.icon` | iOS 16+ target，Liquid Glass 是 iOS 26+；单 size 1024 由 Xcode 自动派生；之后可选升级 Liquid Glass |
| **Icon 视觉概念** | 单牙齿（白）+ Duo.green 圆角矩形 BG + chunky ink outline + 4pt offset shadow；不加牙刷（更简洁、远观可辨识） | 一致 Duolingo 风格；牙齿是产品 logo 唯一识别物；加牙刷会让 1024×1024 缩到 home screen 60×60 时变糊 |
| **Icon 工具链** | 我用 SVG 在文本里写定义 → `rsvg-convert` (Homebrew librsvg) 转 PNG → 三套（Light/Dark/Tinted）手工调（Dark = 浅色牙齿在深绿 BG；Tinted = 灰阶） | Research 报告推荐 `rsvg-convert`；项目里没现成 design tool；纯 SVG 可入库可 diff |
| **Launch screen** | `UILaunchScreen` dict + 自定义 `UIColorName` 用 Duo.green + Image="LaunchLogo" 用 AppIcon 的衍生版 | iOS 13+ 推荐 UILaunchScreen dict 替代 Storyboard；最简单一致；不用拉 storyboard |
| **Category** | `public.app-category.healthcare-fitness`，sub-category `Health & Fitness > Health & Fitness` | 用户在 scope confirmation 隐式同意（agent assumed + 未推翻）；medical 类触发 Regulated Medical Device declaration 不符产品定位 |
| **Regulated Medical Device declaration** | `No` | 产品 audit notes / spec 明确 guidance-grade not clinical |
| **Age rating** | `4+`，questionnaire 全 None | Adult mode 排除 Kids Category；Sugar Bugs 是 confetti/star 不触发 9+ |
| **Privacy Nutrition Label** | 4 个 section 都答 "Data Not Collected" | HealthKit 写 Apple's DB 不算 collected；相机 frames 永不离设备；无 analytics；无第三方 SDK |
| **Privacy Policy & Support 网页托管** | 用户 Vercel + 自定义域名；本 plan 提供 markdown 源 + 用占位 URL `https://toothbuddy.app/privacy` 和 `https://toothbuddy.app/support`，等用户给真实 URL 后单 commit 替换 | 用户明确说有 Vercel；GitHub Pages 是 fallback |
| **首版本地化范围 split** | **P0（本 plan 内做）**：UI 文案 = view 标签 / 按钮 / 导航 / 提示 toast / Achievement 标题 / Live Activity / Widget / 通知 body / Siri phrases。**Deferred（独立 plan）**：内容资产 = ContentLibrary 文章 / Tips 长描述 / Course lessons / Achievement.description / TTS 朗读 prompt | 内容资产是创作型翻译需要专门 polish；UI 文案是机械翻译够用；先 ship 上架最小有用版本 |
| **中文 locale 下内容资产 fallback** | 显示英文原文，不空也不报错；Tips 列表 / Lesson 详情看到英文段落，header / button 全中文——用户能识别"内容暂时英文"的边界 | 比让"今天的笑话"空着或显示乱码体面 |
| **截图风格** | 不加 device frame mockup；用真机 / sim 截图 + 顶部 9:41 + 满电 + Wi-Fi + 飞行模式（避免运营商 logo）；可在底部加一行品牌标语（en/zh-Hans 各一版） | Apple 文档明确反对 misrepresent 的 mockup；研究报告说 status bar 个性化是高危 |
| **截图镜头选择** | 1: Live Activity + Dynamic Island 进行中 / 2: Brush 主屏 + Vision overlay + Sugar Bugs / 3: Group Dashboard 多 profile / 4: History + Habit Curve / 5: Tips Course | 对抗 4.2 minimum functionality（研究报告策略）；前两张展示"非平凡"动效 |
| **App Preview video** | 做一版 30s 简单 capture（QuickTime screen record 真机），无配音，含"开始刷牙 → Live Activity → Sugar Bugs → Done sheet"，BGM 用 Apple-provided 免费曲库 | 强力对抗 4.2；研究报告专门提；不需要后期 polish，简单真实就行 |
| **TestFlight 节奏** | 先 Internal Testing（自己 + 1-2 朋友，无 Beta App Review）跑 1-2 天；稳了再 External（10000 名额，过 Beta App Review 24-48h）；不急 external 也可以直接走正式 review | Internal 0 等待 + 0 风险；External 是营销动作 |

---

## High-Level Technical Design

本 plan 5 个交付阶段，依赖关系简单（视觉资产 → 合规调整 → 本地化基建 + 文案 → 商店资产 → TestFlight + 评审）。**App Store Connect 操作**完全在 Apple Web UI，**不进 git**；仓库里只有 markdown 源 + 截图 + Review Notes + 元数据"备份"docs，方便重新 reviewer 时直接复制粘贴 + 后续 1.1 版本对比。

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Phase A: 视觉资产           Phase B: 合规调整                                │
│  ┌──────────┐                ┌─────────────────┐                            │
│  │ U1 Icon  │                │ U3 Category +   │                            │
│  │ U2 Launch│                │    Permissions  │                            │
│  └────┬─────┘                │ U4 Legal docs  │                            │
│       │                       └────────┬────────┘                           │
│       │                                │                                    │
│       ▼                                ▼                                    │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │  Phase C: 本地化（基建 + UI 文案）                                     │  │
│  │  ┌────────┐  ┌──────────┐  ┌──────────────┐  ┌─────────────────┐    │  │
│  │  │ U5     │→ │ U6       │→ │ U7           │→ │ U8              │    │  │
│  │  │ infra  │  │ UI files │  │ AppShortcuts │  │ Widget/LA/Notif │    │  │
│  │  │ + Plist│  │ × 11     │  │ phrases zh   │  │ + Achievements  │    │  │
│  │  └────────┘  └──────────┘  └──────────────┘  └─────────────────┘    │  │
│  └────────────────────────────────────────┬─────────────────────────────┘  │
│                                            │                                │
│  ┌─────────────────────────────────────────▼─────────────────────────────┐ │
│  │  Phase D: 商店资产                                                     │ │
│  │  ┌──────────────────┐  ┌─────────────────┐  ┌──────────────────────┐ │ │
│  │  │ U9 Metadata 双语 │  │ U10 Screenshots │  │ U11 App Preview video│ │ │
│  │  └──────────────────┘  └─────────────────┘  └──────────────────────┘ │ │
│  └──────────────────────────────────────────┬─────────────────────────────┘ │
│                                              │                              │
│  ┌───────────────────────────────────────────▼─────────────────────────────┐│
│  │  Phase E: 提交                                                           ││
│  │  ┌────────────────────┐  ┌──────────────────────────────────────────┐  ││
│  │  │ U12 TestFlight     │→ │ U13 Beta App Review + 首次正式提审         │  ││
│  │  │     Internal       │  │     (用户操作 + 我提供 checklist & 文案)    │  ││
│  │  └────────────────────┘  └──────────────────────────────────────────┘  ││
│  └─────────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Output Structure

本 plan 新增 / 修改的文件大致这个分布：

```
Assets.xcassets/
└── AppIcon.appiconset/              [NEW] U1
    ├── Contents.json
    ├── icon-light-1024.png          [NEW] 设计图，Light variant
    ├── icon-dark-1024.png           [NEW] Dark variant
    └── icon-tinted-1024.png         [NEW] Tinted variant grayscale

design/                              [NEW] 资产源文件目录
├── app-icon.svg                     [NEW] U1 icon SVG 源
└── README.md                        [NEW] U1 渲染命令

Support/
├── Info.plist                       [MODIFIED] U3 U5 category + CFBundleLocalizations
├── ToothBuddy.entitlements          [unchanged]
└── PrivacyInfo.xcprivacy            [MODIFIED if 必要] U3 reaffirm tracking=false

Localizable.xcstrings                [NEW] U5 主字符串目录（greenfield）
AppShortcuts.xcstrings               [NEW] U7 Siri phrases catalog

docs/
├── legal/
│   ├── privacy-policy.md            [NEW] U4 隐私政策 markdown 源
│   └── support.md                   [NEW] U4 Support 页 markdown 源
├── app-store-listing.md             [NEW] U9 metadata 双语备份
├── app-store-screenshots/           [NEW] U10
│   ├── iphone-69/
│   │   ├── en/  (3-5 PNGs)
│   │   └── zh-Hans/  (3-5 PNGs)
│   ├── ipad-13/
│   │   ├── en/  (3-5 PNGs)
│   │   └── zh-Hans/  (3-5 PNGs)
│   └── README.md                    [NEW] 拍摄脚本与场景说明
├── app-preview-video.md             [NEW] U11 拍摄脚本（视频文件 docs 外）
└── app-store-review-notes.md        [MODIFIED] U13 加 Regulated Medical Device=No 段

project.yml                          [MODIFIED] U1 U5 ASSETCATALOG_COMPILER_APPICON_NAME + 任何 build setting

11 个 view 文件 + 3 个 store 文件 + AppShortcuts 文件
                                     [MODIFIED] U6 U7 U8 字符串提取
```

---

## Implementation Units

### U1. App Icon 设计与集成

**Goal**: 把 ToothBuddy 1.0 app icon 从"没有"变成"home screen 上能看到的真 icon"，符合 Duolingo 风格 + iOS 18 Light/Dark/Tinted 三态。

**Requirements**: R1, R13

**Dependencies**: 无

**Files**:
- `design/app-icon.svg` (新建 - SVG 源)
- `design/README.md` (新建 - 渲染命令)
- `Assets.xcassets/AppIcon.appiconset/Contents.json` (新建)
- `Assets.xcassets/AppIcon.appiconset/icon-light-1024.png` (新建)
- `Assets.xcassets/AppIcon.appiconset/icon-dark-1024.png` (新建)
- `Assets.xcassets/AppIcon.appiconset/icon-tinted-1024.png` (新建)
- `project.yml` (修改 - 两处 `ASSETCATALOG_COMPILER_APPICON_NAME: "AppIcon"`)

**Approach**:
- 视觉概念：一颗白色简化牙齿（与 `DuoCharacters.swift` 的 `BuddyView` 风格一致，但 icon 用简化几何外形）置于 Duo.green 圆角矩形背景上，外缘加 ink-color chunky outline + 4pt 黑色 offset shadow
- SVG 是 `viewBox="0 0 1024 1024"`，结构：背景圆角矩形 + outline + shadow + 牙齿 path
- 渲染：`rsvg-convert -w 1024 -h 1024 design/app-icon.svg -o icon-light-1024.png`
- Dark variant：同结构但牙齿 = Duo.green，背景 = ink-near-black（直接修 SVG fill 重渲）
- Tinted variant：单 channel 灰度（牙齿 = 白，背景 = 透明，让 iOS 用 user-tinted）—— 需要单独的 SVG 或导出后 ImageMagick 灰度化
- 关键决策：不加牙刷。家用 60×60 大小牙刷糊掉，单牙齿 silhouette 更可识别
- `Contents.json` 三个 appearance 入口：`Any` (Light)、`Dark`、`Tinted`
- 三个变体 PNG 都是 1024×1024，Xcode 自动派生所有尺寸（iPad 152、iPhone 120、settings 87、notification 60 等）

**Patterns to follow**:
- `DuoCharacters.swift` 现有的几何牙齿描法（参考线条比例）
- Apple HIG App Icons 文档（圆角由 Xcode 自动 mask，SVG 不要画圆角—画 squircle 会被 mask 两次）
- iOS 18 三态 appearance：[Apple 文档 Configuring your app icon](https://developer.apple.com/documentation/xcode/configuring-your-app-icon)

**Test scenarios**:
- 模拟器装一遍 app，确认 home screen 显示三态 icon（切换深浅 + 设置 tinted appearance）
- TestFlight build 装机后 settings 内 icon 不糊
- Test expectation: none -- 资产生成；视觉验证靠模拟器 + 用户拍板

**Verification**: `xcodebuild build` 通过；模拟器装机后 home screen 看到真 icon；用户视觉拍板

---

### U2. Launch Screen

**Goal**: 把冷启动的黑屏一闪换成简单品牌过场（Duo.green 背景 + ToothBuddy 字样或简化 buddy）。

**Requirements**: R2, R13

**Dependencies**: U1（icon 出来后 launch screen 可以用 icon 的衍生版）

**Files**:
- `Support/Info.plist` (修改 - `UILaunchScreen` dict 填内容)

**Approach**:
- iOS 13+ `UILaunchScreen` dict 替代 storyboard 是最简路径
- Dict 字段：`UIColorName=DuoGreen`（需要在 `Assets.xcassets` 加一个 ColorSet）+ `UIImageName="LaunchLogo"`（从 AppIcon 派生一个无背景版的牙齿 PNG）+ `UIImageRespectsSafeAreaInsets=true`
- 或者更简：只设 `UIColorName` 全屏纯色 + Image，避免做新 ColorSet → 把 `Duo.green` 的 RGB 直接定义为 Asset Catalog 里的 `AccentColor` 或者新增 `LaunchBackground`
- 不做储户屏化：不引入 storyboard，保持 SwiftUI-only 路径

**Patterns to follow**:
- iOS 13+ UILaunchScreen 推荐方法（替代 LaunchScreen.storyboard）

**Test scenarios**:
- 模拟器冷启动看一眼，从黑屏 → 品牌色 + logo → MyApp 第一帧
- Test expectation: none -- 配置 + 视觉验证

**Verification**: `xcodebuild build` 通过；模拟器冷启动不是黑屏；用户视觉拍板

---

### U3. Category 切换 + 权限文案强化

**Goal**: 把 Info.plist 从 medical → healthcare-fitness；把 Camera / Health / 通知 usage description 升级到符合 Apple 2026 "具体描述" 标准（每条 ≥1 句明确说明 what / when / where data goes）。

**Requirements**: R3, R4, R12, R13

**Dependencies**: 无

**Files**:
- `Support/Info.plist` (修改 - LSApplicationCategoryType + NSCameraUsageDescription 强化 + NSHealthUpdateUsageDescription 复核 + 必要时加 NSUserNotificationsUsageDescription)
- `docs/app-store-review-notes.md` (修改 - 加 "Regulated Medical Device declaration = No" 段 + Category change rationale)

**Approach**:
- `LSApplicationCategoryType` 改 `public.app-category.healthcare-fitness`
- 当前 `NSCameraUsageDescription` 已是 "ToothBuddy uses the front camera so you can see yourself while brushing." → 改成更具体版："ToothBuddy uses the front camera during a brushing session to help you see which tooth zones you've covered. Camera frames stay on-device and are never recorded, saved, or sent anywhere." （reference: 研究报告 5.1.1(i) 高拒因建议）
- `NSHealthUpdateUsageDescription` 当前已不错（"only writes tooth-brushing events and never reads any of your health data"），保留 + 微调让 "write-only" 显式
- 通知没专用 usage description（`UNUserNotificationCenter` 不强求）；保留现状
- audit notes 文档加一段 "How Apple's 2026 Regulated Medical Device declaration applies: this app is NOT a regulated medical device; we are submitting `No` to App Store Connect's declaration field"
- 字符串本身**先不本地化**（U5–U8 时一并处理 zh-Hans）

**Patterns to follow**:
- 研究报告 5.1.1(i) 推荐句式
- docs/app-store-review-notes.md 现有 tone

**Test scenarios**:
- `plutil -p Support/Info.plist` 显示新 category 值
- App Store Connect Web UI 选 Healthcare & Fitness 后能继续填表
- Test expectation: none -- 元数据；由 Apple 评审后验证

**Verification**: `xcodebuild build` 通过 0 warning；plist 字段更新；review notes 文档完整

---

### U4. 隐私政策 + Support page markdown 源

**Goal**: 在仓库里写好两份 markdown 法务源，用户拿去 Vercel 渲染托管成两个公开 URL。

**Requirements**: R5, R12

**Dependencies**: U3（category 决定 + Regulated Medical Device declaration 决定 影响隐私政策措辞）

**Files**:
- `docs/legal/privacy-policy.md` (新建)
- `docs/legal/support.md` (新建)

**Approach**:
- `privacy-policy.md` 结构（参考 TermsFeed HealthKit 模板）：
  - Effective date
  - 简介："ToothBuddy is fully offline. No account, no server, no analytics."
  - **Data we touch**：(1) Brushing records (local Core Data, on-device only)、(2) Camera frames (ephemeral, never recorded)、(3) HealthKit toothbrushingEvent (write-only, your Apple Health DB, ours never reads)
  - **What we do NOT do**：no third-party analytics、no advertising、no health data sale or marketing use、no third-party sharing
  - Children's privacy (COPPA): app supports kid profiles but does not collect / transmit any data from any user, so COPPA does not apply in the data-collection sense; parental supervision still recommended
  - Contact: ctlandu@toothbuddy.app（或用户后续给真实邮箱）
  - Changes to policy + effective date
- `support.md` 结构：
  - 简介 + 一句话产品定位
  - **FAQ**: 怎么开始刷牙 / 通知怎么开 / 怎么开 Apple Health 同步 / 多设备同步什么时候有 / 如何删除所有数据
  - **Privacy summary**（链回 privacy）
  - **Contact**：邮箱 + 期望响应时间
- 占位 URL：`https://toothbuddy.app/privacy` 和 `https://toothbuddy.app/support`（U9 metadata 时用同样占位，等真实 URL 再批量替换）

**Patterns to follow**:
- TermsFeed HealthKit privacy template (研究报告链接)
- docs/app-store-review-notes.md 的 tone & 结构

**Test scenarios**:
- 文件存在 + 用户读一遍觉得 OK + 转 Vercel 后回链
- Test expectation: none -- 文档

**Verification**: 两个 `.md` 文件存在；内容覆盖 R5 列出的字段；用户能拿去 Vercel 直接转 HTML

---

### U5. 本地化基础设施（String Catalog + zh-Hans）

**Goal**: 给 app target 装上 String Catalog + 加 zh-Hans locale + 改 Info.plist `CFBundleLocalizations` + 在 ContentEngine fallback 路径正确处理"中文 locale 下英文 fallback"。

**Requirements**: R6, R7, R13, R14

**Dependencies**: U3（Info.plist 共修）

**Files**:
- `Localizable.xcstrings` (新建)
- `Support/Info.plist` (修改 - CFBundleLocalizations = [en, zh-Hans]; CFBundleDevelopmentRegion = en)
- `project.yml` (修改 - sources 列表加 `Localizable.xcstrings`)

**Approach**:
- 在 Xcode：File → New → String Catalog → 命名 `Localizable.xcstrings` → 加 target
- 加 zh-Hans locale：Xcode → 项目 → Info → Localizations → `+` → `Chinese (Simplified) - zh-Hans`
- `Info.plist` 写：
  - `CFBundleDevelopmentRegion = en`
  - `CFBundleLocalizations = [en, zh-Hans]`
- ContentEngine `ContentSelector.pick(...)` 返回的 `ContentItem.text` 等字段当前全英文；本 U 内**不**翻译内容资产；但要在 BrushView 调用前判断 `Locale.current.language.languageCode == "zh"` 时给一句中文 wrapper 提示语（如 "今天的小贴士" 而不是 "Today's tip"），让 zh 用户看到的 UI 是中文 + 内容是英文（明确的边界）
- `LocalizedStringResource` Sendable gotcha（研究报告提到）：暂时不用 `static let foo: LocalizedStringResource = "..."` 模式，避免 Swift 6 严发警告；用 SwiftUI 内联 `Text("Hello")` + AppIntents 用 `LocalizedStringResource("...")` 局部实例化

**Patterns to follow**:
- 研究报告 SwiftUI L10n 段
- Xcode 26 String Catalog UI

**Test scenarios**:
- `xcodebuild build` 0 warning（特别注意：新建 .xcstrings 文件本身不会触发字符串提取，要先 build 一次 + 看到 Xcode 把字面量抓进去）
- 模拟器 → 设置 → ToothBuddy → 选 zh-Hans 后冷启动，至少 MyApp 主屏 placeholder 字符串能切换（实际全文案 U6 内做）
- Test expectation: none -- infra；R7 的端到端验证靠 U6 完成

**Verification**: `Localizable.xcstrings` 文件存在；plist 字段 + locale 设置正确；build 0 warning

---

### U6. UI 主流路径文案双语化（11 个 view 文件）

**Goal**: 把 onboarding / profile picker + create / brush 主屏 / done sheet / history / tips / group dashboard / content view tab bar 等 11 个 view 文件的所有用户可见字面量过一遍 String Catalog，加英文 key + zh-Hans 翻译。

**Requirements**: R7, R13

**Dependencies**: U5

**Files**（修改 - 字面量改成 `LocalizedStringKey` / `Text("English")` 默认 + String Catalog 补 zh）:
- `OnboardingView.swift`（最多字面量，~617 行 SwiftUI Welcome / 4 slides / Ready）
- `ProfilePickerView.swift`
- `BrushView.swift`
- `ContentView.swift`（tab bar 标签）
- `HistoryView.swift`
- `TipsView.swift`（注意：只翻 view 结构 / section header / button label——`BrushingTip.title/summary/content` 的长文本英文资产 deferred）
- `GroupDashboardView.swift`
- `HabitCurveView.swift`
- `BrushGameOverlay.swift`（HUD 文案、win 庆祝）
- 加上 `Localizable.xcstrings` 自动累积所有 key + 中文翻译

**Approach**:
- 策略：每个 view 文件**只改字面量**，不动逻辑；改完后 build 一次让 Xcode 自动提取 → 用 catalog 编辑器一项项填中文
- 翻译风格：与 Duolingo 中文风格保持一致（亲切、口语、强调动作）。例如 "Start Brushing" → "开始刷牙"、"Streak: 7 days" → "连续 7 天"、"Brushed!" → "刷完啦"
- `String(localized:)` 用于纯 String 场景（如 `accessibilityLabel`、`Alert.title` 等参数）
- 复数 / 性别：中文不需要 plural form，但 catalog UI 还是要点开"Vary by Plural"配置以保证英文 plural 正确（"1 day" / "5 days"）
- `BrushingTip` / `Lesson` / Achievement.description 等长内容**显式跳过**（U6 内不译），落入 deferred；catalog 里见到这些 key 时填中文 = 英文原文（占位）或者直接不翻—— iOS 自动 fallback 到英文显示

**Patterns to follow**:
- 研究报告 SwiftUI L10n 段
- Xcode String Catalog 编辑器 UI

**Test scenarios**:
- 模拟器切 zh-Hans 后：onboarding 4 屏全中文、主屏"开始刷牙"按钮中文、tab bar 全中文、done sheet 全中文、history / group / tips section header 全中文
- 模拟器切 en 后：完全等同改之前的英文 UI（回归测试）
- BrushView 长按按钮 / 通知 Live Activity 走 U8 处理
- Test expectation: none -- UI 文案；模拟器双语切换验证

**Verification**: 模拟器切 zh-Hans 主流路径无英文字面量泄漏（content 资产除外）；切回 en 完全等价改前；`xcodebuild test` 42/42 不变

---

### U7. AppShortcuts.xcstrings + 中文 Siri phrases

**Goal**: 让 Siri 中文版能听懂 ToothBuddy 三个 intent 的中文触发短语。

**Requirements**: R7, R13, R14

**Dependencies**: U5

**Files**:
- `AppShortcuts.xcstrings` (新建)
- `ToothBuddyIntents.swift` (微调 - phrases 字面量保持英文为 source；intent title / parameter prompts 改 `LocalizedStringResource("...")`)
- `project.yml` (修改 - sources 列表加 `AppShortcuts.xcstrings`)

**Approach**:
- 在 Xcode：File → New → String Catalog → 命名 `AppShortcuts.xcstrings`（**文件名严格**）→ 加 app target
- Build 一次让 Xcode 自动从 `ToothBuddyShortcuts.appShortcuts` 提取三个 intent 的 phrases
- catalog 内为 zh-Hans 加多 phrase 变体（研究报告强调中文 Siri 匹配靠多变体）：
  - `LogBrushingIntent` (en): "I brushed my teeth in ToothBuddy", "Log my brushing"...
  - `LogBrushingIntent` (zh): "我刷牙了"、"在 ToothBuddy 记录刷牙"、"刚刷完牙"、"记一次刷牙"
  - `StartBrushingIntent` (zh): "开始刷牙"、"在 ToothBuddy 开始刷牙"
  - `BrushingStreakIntent` (zh): "我的连续刷牙天数"、"看一下连续记录"
- Intent title / parameter prompts (如果有) 用 `LocalizedStringResource("...")` 包装 → 走 Localizable.xcstrings

**Patterns to follow**:
- 研究报告 AppShortcuts.xcstrings 段
- Apple [Localizing your app's content for App Shortcuts](https://developer.apple.com/documentation/appintents/localizing-your-app-s-content)

**Test scenarios**:
- 模拟器切到 zh-Hans Siri，说"我刷牙了"应触发 LogBrushingIntent（实际验证靠真机；模拟器 Siri 不全功能）
- Shortcuts.app 内出现三个动作的中文版
- `xcodebuild test` 18 个 App test + 100 Core test 不变（Siri phrases 不在测试范围）
- Test expectation: none -- 元数据；真机 / Shortcuts.app 视觉验证

**Verification**: `AppShortcuts.xcstrings` 文件存在 + zh-Hans 三个 intent 都有 ≥1 phrase；build 0 warning；Shortcuts.app 显示三个中文动作名

---

### U8. 通知 / Live Activity / Widget / Achievement 文案双语

**Goal**: 把不在 view 文件里的"系统层"用户可见字符串全部走 String Catalog：通知 body、Live Activity 文本、Widget 标签、Achievement 标题。

**Requirements**: R7, R13

**Dependencies**: U5, U6

**Files** (修改):
- `NotificationScheduler.swift`（通知 title + body 当前英文硬编码）
- `BrushingLiveActivity.swift`（Lock Screen / Dynamic Island 文本）
- `Widget/StreakWidget.swift`（Home Screen widget 文本）
- `Widget/BrushingLiveActivityWidget.swift`（Live Activity 实际渲染层）
- `GamificationStore.swift`（`Achievement.title` 数组 - 8 个 achievement title）
- 不动 `Achievement.description`（长文内容资产，deferred）

**Approach**:
- NotificationScheduler 的 `title(for:)` / `body(for:)` 返回 `String(localized: "...")`
- Live Activity 内 SwiftUI Text 用 `Text("...")` 默认 LocalizedStringKey
- Widget 同理（注意 widget target 的 Localizable.xcstrings 是否共享——研究报告未明确，常见做法是 widget 共享 app target 的 .xcstrings；可能要 project.yml widget sources 也加 `Localizable.xcstrings`）
- Achievement title 翻译：First Brush → "首次刷牙"、Week Warrior → "周冠军"等
- 不翻 `Achievement.description`（内容资产 deferred）

**Patterns to follow**:
- U6 模式

**Test scenarios**:
- 模拟器 zh-Hans 下：通知中心看到中文通知（需要触发本地通知调度）、Live Activity 中文、Widget 添加到 Home Screen 后显示中文 streak 数字 + 标签
- Achievement detail sheet 显示中文 title + 英文 description（混合体面）
- Test expectation: none -- UI；模拟器视觉验证

**Verification**: 模拟器 zh-Hans 下系统层文案全中文（content 资产除外）；build 0 warning；test 42/42 不变

---

### U9. App Store Connect Metadata（双语备份文档）

**Goal**: 把上 App Store Connect Web UI 时要填的所有 metadata 写成仓库内 markdown，方便复制粘贴 + 后续 1.1 版本对比。

**Requirements**: R8

**Dependencies**: U3（category 决定）、U4（隐私 URL）、U6 U7 U8（中文文案先就位才好写 zh-Hans metadata）

**Files**:
- `docs/app-store-listing.md` (新建)

**Approach**:
- 文档结构（按 App Store Connect Web UI 顺序）：
  - **General Info**: Bundle ID / SKU / Primary language: English / Category: Health & Fitness > Health & Fitness / Content Rights / Age Rating questionnaire (全 None → 4+)
  - **Pricing**: Free / 上架地区: 全球
  - **Privacy**: Privacy Policy URL: `https://toothbuddy.app/privacy` (占位) / Privacy Nutrition Label: 4 sections 全 Data Not Collected
  - **App Information**: 
    - en: Name `ToothBuddy`, Subtitle `Build a real brushing habit, every day.`
    - zh-Hans: Name `刷牙伙伴` (或保持 `ToothBuddy`), Subtitle `每天养成真正的刷牙习惯。`
  - **Version Info**:
    - Promotional Text (en + zh): 一句话，每次更新可改不需要 review
    - Description (en + zh): 长 description ~150-300 字，提 P1 streak / P2 family / P3 content / P4 camera / P5 widget / Live Activity / Siri / Health
    - Keywords (en + zh): 100 char 上限，comma-separated（en: brushing,teeth,habit,streak,family,health,timer,kids,...）
    - Support URL: `https://toothbuddy.app/support` (占位)
    - Marketing URL: 留空
    - Review Notes: 引用 `docs/app-store-review-notes.md`（U13 提交时实际复制）
    - What's New in This Version (1.0): "First release."
  - **Regulated Medical Device Declaration**: No（已 U3 改 category 之后）

**Patterns to follow**:
- 研究报告 metadata 段
- docs/app-store-review-notes.md 措辞风格

**Test scenarios**:
- 文档存在 + 字段齐全
- 占位 URL 用 ALL CAPS 标 `[REPLACE WITH REAL VERCEL URL]` 防止遗忘
- Test expectation: none -- 文档

**Verification**: 文档存在；en + zh 都有 title/subtitle/description/keywords 完整；用户读一遍 OK

---

### U10. App Store 截图（双语 × 双设备）

**Goal**: 截 12–20 张截图（iPhone 6.9 + iPad 13 × en + zh-Hans × 3-5 scenes）。

**Requirements**: R9

**Dependencies**: U6 U7 U8 (中文 UI 就位才能截 zh-Hans 截图)、U1（icon 上线后状态栏显示真 icon）

**Files**:
- `docs/app-store-screenshots/README.md` (新建 - 拍摄脚本)
- `docs/app-store-screenshots/iphone-69/en/scene-1-live-activity.png` 等 (新建 × 3-5)
- `docs/app-store-screenshots/iphone-69/zh-Hans/scene-1-live-activity.png` 等
- `docs/app-store-screenshots/ipad-13/en/...`
- `docs/app-store-screenshots/ipad-13/zh-Hans/...`

**Approach**:
- 5 个场景（研究报告对抗 4.2 的策略）：
  1. **Brush 主屏 + Vision overlay + Sugar Bugs** —— 展示 "non-trivial functionality"
  2. **Lock screen + Dynamic Island Live Activity** —— 展示苹果生态深度集成
  3. **Group Dashboard 多 profile** —— 家庭层是 ToothBuddy 唯一卖点
  4. **History + Habit Curve** —— 习惯养成主张
  5. **Tips Course unlocked** —— 内容引擎主张
- 拍摄技巧（研究报告高危规避）：
  - 状态栏：模拟器设 9:41 / 满电 / Wi-Fi（用 SimulatorStatusMagic 或 simctl 配）
  - 不加 device frame mockup
  - 底部可加 1 行中文/英文 slogan 大字（用 Figma 简单加上覆盖）—— 或者裸图也行
- iPhone 6.9 (1320×2868)：iPhone 16 Pro Max sim；iPad 13 (2064×2752)：iPad Pro 13" sim
- 截图脚本写在 README.md：每张图说明"哪个场景、怎么进入、要等什么状态触发"

**Patterns to follow**:
- 研究报告 screenshots 段

**Test scenarios**:
- 文件存在 + 像素尺寸符合 App Store Connect 要求（用 `sips -g pixelWidth -g pixelHeight` 验证）
- 视觉上每张图表达清楚一个产品价值点
- Test expectation: none -- 资产；用户拍板

**Verification**: 12–20 PNG 文件存在；像素尺寸正确；视觉 OK 由用户拍板

---

### U11. App Preview Video（可选但推荐）

**Goal**: 录一段 15–30 秒的 capture，含 brushing session 关键动作（开始 → Vision overlay → Sugar Bugs → Done）。

**Requirements**: R10

**Dependencies**: U6 U7 U8（中文 UI 录中文版）、U10（与截图风格一致）

**Files**:
- `docs/app-preview-video.md` (新建 - 拍摄脚本 + 后期建议)
- 视频文件本身不进 git（太大；放 `~/Movies/ToothBuddy/preview-1.0.mov` 之类的本地，App Store Connect 直接上传）

**Approach**:
- 镜头脚本（30s）：
  - 0–3s: app icon → 主屏 → "开始刷牙" 按钮 highlight
  - 3–8s: 进入 brush session → Vision overlay 出现 → Sugar Bugs spawn → confetti
  - 8–18s: Live Activity 出现在 Dynamic Island + Lock Screen
  - 18–25s: Done sheet + 星星 + streak update
  - 25–30s: 收尾品牌 wordmark
- 录法：iPhone 16 Pro Max sim + QuickTime screen record，或者真机 + Xcode → Devices → Take Screenshot/Recording
- 无配音（zh-Hans 上传同样的 mp4 即可；如要 zh 配音单独录 zh 版）
- BGM：Apple-provided 免费曲库（避免版权问题）

**Patterns to follow**:
- 研究报告 App Preview 段

**Test scenarios**:
- 视频文件存在（外仓库）+ 长度 ≤ 30s + 像素 ≥ App Store 要求 + 含上述关键镜头
- 通用：先做 en 版上传，zh 版可以延后
- Test expectation: none -- 资产；视觉拍板

**Verification**: 视频文件存在；docs/app-preview-video.md 写完拍摄/上传 checklist；视觉拍板

---

### U12. TestFlight Internal 测试

**Goal**: 上传第一个 build 到 TestFlight，加内测人员（自己 + 1–2 朋友），跑一遍主流路径。

**Requirements**: R11, R13

**Dependencies**: U1 U2 U3 U4 U5 U6 U7 U8（应用本身要 ready）+ Apple Developer 账号 + 距上次成功 archive 跑过

**Files**:
- `docs/testflight-checklist.md` (新建)

**Approach**:
- archive build：`xcodebuild archive -project ToothBuddy.xcodeproj -scheme ToothBuddy -archivePath /tmp/ToothBuddy-1.0.xcarchive`
- 用 Xcode Organizer 上传到 App Store Connect（CLI 也可：`xcrun altool --upload-app -f ToothBuddy.ipa -u ...`）
- 上传后等 ~15 分钟 build 处理完
- 在 App Store Connect → TestFlight → Internal Testing → 加自己 + 选 1–2 个朋友的 Apple ID
- testers 装 TestFlight app → 收邀请 → 装 build
- 跑一遍主流路径 checklist（写在 testflight-checklist.md）：
  - 冷启动 → onboarding → 创建第一个 profile
  - 跑一次完整 brushing session（含相机 / Live Activity / Sugar Bugs / Done）
  - 切语言 zh-Hans 重做一遍
  - 加第二个 profile → group dashboard
  - HealthKit 授权流程 (adult mode)
  - Siri "我刷牙了" 触发
  - Widget 加到主屏
- 收 testers 反馈 1-2 天

**Patterns to follow**:
- 研究报告 TestFlight 段

**Test scenarios**:
- TestFlight build 状态 Active
- 至少 1 名 tester (自己) 跑完 checklist
- 收集 ≥ 0 issue（issue 进 follow-up backlog 但不阻 U13）
- Test expectation: none -- 流程

**Verification**: TestFlight 上有 Active build；checklist 文档存在 + 至少自己跑完

---

### U13. Beta App Review + 首次正式 App Store 提审

**Goal**: 通过 Beta App Review + 首次 App Store 提审，让 1.0 进入 "Ready for Sale"。

**Requirements**: R8, R12, R13

**Dependencies**: U1–U12 全 done

**Files**:
- `docs/app-store-review-notes.md` (修改 - 最终版上传文本)
- `docs/launch-postmortem.md` (新建 - 上架完成后记录上架经历)

**Approach**:
- App Store Connect → App Store → 提交审核：
  - 选 build (U12 的)
  - 填 Version Information（从 docs/app-store-listing.md 复制）
  - 填 App Review Information（从 docs/app-store-review-notes.md 复制）
  - 上传 截图 (U10) + App Preview (U11)
  - 答 Export Compliance（无加密 → No）
  - 答 Content Rights / Advertising Identifier（IDFA → No）
  - 提交
- 等审：通常 24–48h，最长 7 天
- 失败处理：每条审查反馈拆解 → 改代码 / 改 metadata / 回复 → 再交
- 通过后：选 Manual Release 或 Automatic Release（推荐 Manual 自己决定哪天 ship）
- 上架后：写 launch-postmortem.md 复盘流程，记录踩坑 + 时间线

**Patterns to follow**:
- 研究报告 TestFlight + 评审段

**Test scenarios**:
- 至少一轮 Apple 评审反馈（可能直接通过，可能要 reject 改）
- 通过后 manual release → App Store 真的搜得到
- Test expectation: none -- Apple 评审；用户操作 + 等

**Verification**: App Store Connect 状态 "Ready for Sale"；App Store 搜 ToothBuddy 搜得到；用户验证

---

## Risks & Dependencies

| Risk | Severity | Mitigation |
|------|----------|------------|
| **Apple 评审拒因 4.2 minimum functionality**（habit tracker 高拒因） | 高 | 截图必须 lead with Live Activity + Vision overlay + Sugar Bugs；App Preview 必做；Review Notes 显式列举非平凡功能 |
| **Usage description 拒因 5.1.1(i)** | 中 | U3 已强化 + Apple 2026 推荐句式 |
| **Privacy URL / Support URL 用户没及时部署** | 高 | 占位 URL 提前 commit；用户单 commit 替换；不能晚于 U13 |
| **String Catalog + Swift 6 严发 + LocalizedStringResource Sendable 警告** | 中 | U5 决策已规避（不用 `static let LocalizedStringResource`）；如果出现局部加 `nonisolated(unsafe)` |
| **中文翻译质量** | 中 | 翻译由我 + 用户共同 review；catalog 内每行用户能改；不上 LLM 自动翻译（精度不够 + 风格不一致） |
| **Widget target 不共享 app 的 Localizable.xcstrings** | 中 | project.yml widget sources 也加 `Localizable.xcstrings`；build 后验证 widget 中文显示 |
| **iPad 13 截图设备**（用户可能没 iPad sim 装 18.6） | 低 | 文档写如何创建 sim；如设备没法装 iPad sim 可暂跳过 iPad 截图，因为 universal app iPhone 截图也够 |
| **TestFlight Internal 100 名额，没朋友测怎么办** | 低 | 自己一台就够触发 build 上 TF；External 看上架紧急程度后续决定 |
| **Beta App Review 阻塞**（与正式 review 不同） | 低 | Internal Testing 完全跳过 Beta App Review；只有 External 才走 |
| **Apple Developer 账号年费到期或证书过期** | 低 | 用户已确认账号有效；DEVELOPMENT_TEAM 89A8S223WV 已配置 |
| **HealthKit reviewer 复查反复**（write-only 需要明确说明） | 中 | Review Notes 已显式声明；audit notes 文档完整 |
| **Sugar Bugs 触发 9+ age rating questionnaire 误判** | 低 | "cartoon violence" 不勾选；confetti/star 是 visual feedback 不是 violence |

---

## Scope Boundaries

### 在范围内（本 plan 覆盖）
- App Icon + Launch Screen + Healthcare-Fitness 分类
- 隐私政策 markdown 源 + Support page markdown 源
- 本地化基础设施（String Catalog）+ 主流 UI 文案双语
- AppShortcuts.xcstrings + Siri 中文 phrases
- Widget / Live Activity / 通知 / Achievement 标题双语
- App Store Connect metadata（en + zh-Hans）
- App Store 截图（iPhone + iPad × 双语）
- App Preview video（一版）
- TestFlight Internal 测试
- Beta App Review + 首次正式 App Store 提审

### Deferred to Follow-Up Work（与"上架"相关但本 plan 不做）
- App Preview video 第二版 + 中文配音
- External TestFlight 测试（上架后再说）
- App Store Optimization (ASO) - 关键词迭代、A/B 测试
- 自定义 marketing URL + 真品牌站
- iOS 26 Liquid Glass Icon Composer 升级
- Apple Search Ads 投放

### Outside this product's identity / 单独 plan
- **内容资产中文化**：`ContentLibrary` 库（jokes / facts / tips / story beats）+ `BrushingTip` 长描述 + `Lesson` 课程文本 + `Achievement.description`——内容工程独立 plan
- **CloudKit / P2.5b**：仍 park 在用户 Apple Dev 配置侧
- **新功能**（音乐 / LLM / 微笑相册）
- **Apple Watch / iPad-only UI 优化**
- **APNs / 服务器推送**
- **本地化超出中英**（日韩西法等其他语言）

---

## Open Questions

| Question | Resolution path |
|----------|-----------------|
| Vercel 域名 + 真实 Privacy Policy / Support URL 什么时候到位？ | 用户在 U13 之前给真实 URL，单 commit 替换占位（影响 U4 + U9 + Info.plist） |
| App Icon 视觉用户认不认 | U1 完成后用户 review 截图 → 如不满意改 SVG 重渲 |
| 中文翻译用户改不改 | U6–U8 完成后用户跑模拟器看一遍；catalog 内可逐字改 |
| 是否做 zh-Hans 配音的 App Preview | U11 默认只做 en 视频（中文上同一份 mp4）；用户可后续要求加 zh 配音 |
| 截图是否加 slogan 大字 overlay | U10 默认裸截图；用户可后续要求 Figma 加 overlay |
| 评审遇拒因怎么处理 | 拒因到达后单独看 plan—— ce-plan + ce-work 处理 |
| External TestFlight 现在开还是上架后再说 | Internal 跑稳后用户决定（默认延后） |

---

## Verification (Plan-Level)

全部 13 个 U 完成后：
- `xcodebuild build` 0 warning 0 error
- `xcodebuild test` 42/42 ✓ + Core 108/108 ✓ 不变
- `bash scripts/audit.sh` 退出 0
- 模拟器装 app：home screen 有真 icon、launch screen 不黑、切语言 zh-Hans 主流路径全中文（content 资产英文 fallback 体面）
- App Store Connect：build 状态 Ready for Sale；元数据 + 截图 + Preview Video 都上线；隐私 + Review Notes 完整
- App Store 真机搜 ToothBuddy 搜得到

## Sources & Research

- 外部研究 1（2026 评审雷区）：App Review Guidelines / Privacy Manifest / Category 决策 / Kids Category / Privacy Nutrition Label / 截图规范 / TestFlight
- 外部研究 2（本地化 + AppShortcuts + AppIcon）：String Catalog (WWDC23 #10155) / AppShortcuts.xcstrings (Forums #803490) / Configuring App Icon / iOS 18 三态 variants / iOS 26 Liquid Glass
- 本仓库：
  - `docs/app-store-review-notes.md`（已写，U3 U13 复用 + 微调）
  - `Support/PrivacyInfo.xcprivacy`（已就位）
  - `Support/Info.plist`（U3 U5 修改）
  - `project.yml`（U1 U5 修改 build settings + sources）
- 项目 memory：`project-progress` / `design-refactor` / `user-design-direction` / `feedback-design-quality`
