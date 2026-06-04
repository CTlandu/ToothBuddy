# ToothBuddy — 进度 & 接力点

> 这是**当前执行状态**的活文档(快速接力用)。产品权威定义是 [`docs/product-north-star.md`](product-north-star.md);这份只记"做到哪了 / 接下来做什么"。末尾有 **Pick up next**。
>
> 最后更新:2026-06-05。

---

## 现在在哪

- 分支 `main`,与 `origin/main` 同步,已推 GitHub。
- `main` 上 = **Phase 1(质量转向重做)+ Phase 1.5(本地闭环打磨)+ header 视觉修复**。
- 校验基线:**Core 142 + app 54 测试全绿、0 warning**(`bash scripts/audit.sh`)。
- 旧分支 `feat/quality-pivot-rebuild` 已合并(PR #1),可删可留。

---

## ✅ 已完成

### Phase 1 — 质量转向重做(U1–U16)
计划:[`docs/plans/2026-05-29-001-feat-quality-pivot-rebuild-plan.md`](plans/2026-05-29-001-feat-quality-pivot-rebuild-plan.md)(status: completed)。
内核从"习惯打卡"改成"刷牙质量 + 时长 + 可验证记录":记录变厚(分区覆盖 + 时长 + 相机佐证)、规定路线 audio-first session、去 kid/adult 改 Settings、砍多档案家庭改单 profile、奖励/Widget/Siri/HealthKit/Live Activity 重指向质量、牙医证明 PDF。2026-06-04 合 main(merge `be074e3`)。

### Phase 1.5 — 本地闭环打磨(U1–U6)
计划:[`docs/plans/2026-06-04-001-feat-phase-1-5-local-loop-hardening-plan.md`](plans/2026-06-04-001-feat-phase-1-5-local-loop-hardening-plan.md)(status: completed,经 5-persona doc-review 加固)。2026-06-05 合 main(merge `9e30d6f`)。
- **U3** 计时膨胀修复:`SessionClock`(Core)只算前台活跃时间;暂停信号双源(scenePhase + AVAudioSession 中断);持久化时长走活跃总秒(单一时间源);cue `==`→`<=` 扫描;monitor `paused` flag 同步冻结;被杀落 `InProgressSessionSnapshot` 快照、relaunch 补提交。
- **U4** 相机被拒 → `SessionModeResolver`(Core)降级纯音频、不黑屏、整场降级提示;权限未决 + START 竞态 gate。
- **U2** onboarding 加可选"主要给谁用"预设(`OnboardingPreset` Core → `PreferencesStore.apply`,只设默认值、不复活 kid/adult 分叉)。
- **U5** 牙医 PDF 空态页(`ReportData.hasData`)+ 导出失败 alert。
- **U6** 交付 [`docs/phase-1-5-device-smoke-checklist.md`](phase-1-5-device-smoke-checklist.md)(13 类真机验项)。
- **code-review(high)** 修了 3 个真 bug:`.inactive` 误暂停切语音 / 快照没在 resume 清→可能补错记录 / cue 爆发互相打断。

### 视觉精修(进行中,这轮做了一项)
- **header 被灵动岛切** —— 真 bug,已修(merge `d44e3a4`):`ContentView` 用 GeometryReader 自适应顶部 padding 清岛。详见根因 → [[safe-area-inset-gotcha]] 记忆 / 下方 Open。
- 核查"按钮阴影太重" = 误判,实际是规范 `Duo.depthOffset=4`,未改。

---

## ⏳ Open / 待做(都卡在"需要真机")

1. **真机 smoke(最大的门)** —— Phase 1 + 1.5 从没真机跑过。按 [`docs/phase-1-5-device-smoke-checklist.md`](phase-1-5-device-smoke-checklist.md) 走一遍(相机左右映射、cameraVerified 阈值、语音、Live Activity、中断后时长不膨胀、被杀 relaunch、权限降级、HealthKit、Siri、Widget、预设)。**这是验证产品核心"刷牙时有没有人愿意开它"的前提。**
2. **audio-session 中断 gap**(checklist D2)—— app 没主动持有 `AVAudioSession`,TTS 只在念时占会话,所以**前台静默段**被 Siri/闹钟/配对来电打断时可能收不到中断通知→不暂停(答应的来电切后台仍能暂停,主场景 OK)。彻底修要起 `.playback` + `.duckOthers` 会话(改动和用户背景音乐的交互),需真机调。
3. **safe-area 根因**([[safe-area-inset-gotcha]])—— 整个 app 拿老式 ~19pt 顶部 inset 而非灵动岛 ~59pt,贴顶 UI 会被岛压住;header/onboarding 现在都靠手动清岛 workaround。查清根因(为啥全局拿老式 inset)能甩掉手动 pad,但要真机验(真机报 19 还是 59 决定它是真 bug 还是 sim 怪象)。

### Phase 1.5 计划里显式 Deferred 的小项
- 用户可见的 session 暂停/继续按钮(现在只自动暂停计时,无手动按钮)。
- `BrushingZoneMonitor` glue 层更全面单元测试。
- "重跑 onboarding"入口(Settings 重置 `hasCompletedOnboarding`)。
- `ProfileMode` dead column 彻底清理(零风险非必须)。

---

## 🧭 可能的方向(下一个大块,按"贴产品内核"排)

- **Phase 2a — 牙医在线分享链接**(最 on-thesis、最小)。把离线牙医 PDF 变成可在线打开的只读链接(无账号、点对点、低频),补完"可验证记录→给牙医看"价值链。我能独立做大部分,只在"线上 host"那步要用户的 Vercel/blob。**不卡 Apple Dev 配置。** 要做先 `/ce-plan`。
- **Phase 2b — 朋友/家人双向实时可见**(大)。需账号/身份 + CloudKit 共享 zone 或自建后端,卡用户的 Apple Developer 配置(container/entitlements/多端联调)。排在 2a 之后。
- **视觉精修(剩余)** —— north-star 明确 deferred。剩 timer 数字滚动、相机 onboarding 插画偏空等次要项。按用户习惯:**用户指具体哪里丑 → 对着改**,别泛泛重设计(见 [[feedback-design-quality]] / [[user-design-direction]] 记忆)。智能镜 session 的视觉(相机预览+分区高亮+糖虫)模拟器渲染不出,需真机看。
- **中文化** —— 若目标是中文市场。UI 文案走 xcstrings(已有基建)+ 把 BrushView 里硬编码的 100 条英文 facts 抽出来翻。先定市场再动。
- **App Store 上架材料重做** —— 暂停中;旧 listing/截图/icon 的"家庭习惯"叙事要按新定位重做。排在核心真机验证之后。

---

## ▶️ Pick up next(下次直接从这挑一个)

1. **(推荐)真机 smoke** —— 用户拿真机按 `docs/phase-1-5-device-smoke-checklist.md` 跑一遍,反馈问题;我同步可修 audio-session gap、查 safe-area 根因(这两个都要真机数据才能定论)。这是当前最高价值、且只有用户能起的步。
2. **要继续写代码不等真机** → 起 **Phase 2a 牙医在线分享链接** 的 `/ce-plan`(最小、最贴内核、不卡 Apple 配置)。
3. **继续视觉精修** → 用户指出具体"有点丑"的屏/元素,对着改(截图工作流:起 iPhone 16 模拟器,`xcrun simctl io booted screenshot`;onboarding 按钮 cliclick bottom-center 翻页;详见本次会话做法)。
