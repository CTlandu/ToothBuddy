# ToothBuddy Phase 1.5 — 真机 smoke checklist

> 这份清单只列**真机才能验**的项 —— 相机映射、`cameraVerified` 手感、语音、Live Activity、Siri、HealthKit、音频中断、权限弹窗这些单测和模拟器覆盖不到的。纯逻辑(SessionClock、SessionModeResolver、OnboardingPreset、ReportBuilder 等)已被 Core 142 + app 54 个测试盖住,这里不再重复。
>
> 用法:在一台**真 iPhone**(装好相机/麦克风权限可控、能接电话或用 Siri)上,从冷启动开始按 A→G 走一遍。每条标 ✅ / ❌,❌ 的把"实际看到什么"写在该条下面。
>
> 关联实现单元:U2(onboarding 预设)· U3(计时/中断/快照)· U4(相机降级)。Phase 1 一直 pending 的相机映射/阈值也收在这里(C1、C2)。

---

## A. 首次启动 & onboarding 预设(U2)

> 需要"全新安装"状态。先删除 app 重装,或在模拟器/真机上清掉 app 数据。

- [ ] **A1 预设步骤可见。** 走 onboarding,在最后的"You're all set!"(Ready)屏**之前**,出现一屏 **"Who's this phone mostly for?"**,有三张卡:`For a kid` / `For myself` / `My dentist wants me to improve`,外加底部 `Skip — I'll set this up later`。
- [ ] **A2 Skip 落点正确。** 在任意 feature 屏点右上角 `Skip` → 落到**预设屏**(不是直接跳过它),且能继续到 Ready;在预设屏点 `Skip — I'll set this up later` → 到 Ready。**不应**出现"滑不到 Ready"或"Skip 跳过了预设又跳过了 Ready"。
- [ ] **A3 预设真的改默认值。** 选 `My dentist wants me to improve` 完成 onboarding → 进 Settings,确认:Content style = **essentials**、Session length = **3 min (180)**、Sugar Bugs game = **off**、Celebrations = **on**。(选 `For a kid` 则应是 playful / 120 / game on / celebrations on。)
- [ ] **A4 跳过保持默认。** 重装后这次**跳过**预设 → Settings 里应是全开默认(playful / mirror / 120 / game on)。
- [ ] **A5 不复活 kid/adult 分叉。** 确认 app 里**没有**任何"切换 kid/adult 模式"的开关 —— 预设只是设了一次默认值,之后全靠 Settings 逐项调。

---

## B. 纯音频 session — 免眼盲走(核心卖点)

> Settings → Guidance 选 **Audio**(或用 A 里选了 adult 的档)。

- [ ] **B1 不开相机也能跑。** 点 START,**把手机扣在桌上别看屏**。全程靠语音应该能走完:开场 → 依次念 6 个区("Now brush your upper left teeth"…)→ 中段插一条笑话/冷知识/tip → 收尾。
- [ ] **B2 语音单源、不重叠、不抢话。** 换区提示和中段内容**不应**同时响、不应一句没说完被下一句切断得很突兀。(U3 把 cue 改成 `<=` 扫描 + 单一语音链路。)
- [ ] **B3 计时正常推进。** 屏幕计时器从 00:00 平稳走到目标(2:00 或 3:00),颜色 红→黄→绿。
- [ ] **B4 达标总结正确。** 跟着走完 → 结束卡显示 6 区基本都达标、时长达标 ✓、角标为 **"Guided (no camera)"**(纯音频不该显示 camera-verified)。

---

## C. 智能镜 session — 相机映射 & 佐证(Phase 1 遗留,只能真机调)

> Settings → Guidance 选 **Mirror**,授予相机权限。架起手机能照到脸。

- [ ] **C1 左右/上下映射对。** 当前高亮"upper left"时,你刷**自己**的左上后牙,自拍画面里高亮区和你手的位置应该**对得上**(注意自拍是镜像的)。逐区核对一遍,记录哪个区映射反了。
- [ ] **C2 `cameraVerified` 阈值手感。** ① 认真对着镜头刷满全程 → 结束卡应给 **"Camera-verified"**(盾形✓)。② 把手机架着但**人走开/不刷** → 这次应**不是** verified(guided)。阈值(检测占比 ≥ 50%)是否符合"认真刷=verified、敷衍=guided"的直觉?偏松/偏紧都记下来。
- [ ] **C3 糖虫游戏。** game 开关开 + mirror → 出现 Sugar Bugs 叠层;关掉 → 不出现。
- [ ] **C4 预览不黑、不卡。** 相机预览实时、不黑屏、不冻帧;"Preview only — not saved" 字样在。

---

## D. 中断 & 恢复 —— 计时不膨胀(U3,本期最关键)

> 这是 Phase 1.5 的 P0。重点验:**中断期间不计时,记录时长 = 真实刷牙时长,不含中断**。

- [ ] **D1 切后台不膨胀。** 开始一个 session,刷约 30s → 按 Home 回桌面**停 1 分钟** → 回到 app。期望:① 回来时看到**"Paused"**遮罩(暂停可见信号);② 计时器停在 ~30s 不是 ~90s;③ 继续刷到达标后,结束卡和 History 里的时长 ≈ 真实刷牙时长(**不含**那 1 分钟)。
- [ ] **D2 接电话/Siri/闹钟也暂停(不改 scenePhase 的中断)。** session 进行中,让另一台设备打来电话(或触发 Siri / 响个闹钟)打断音频但**不离开 app**。期望:计时**暂停**、语音停;中断结束后计时继续。**不应**出现"语音被系统静音了但计时还在涨"。
- [ ] **D3 多次中断求和正确。** 中断→恢复→再中断→再恢复,最终记录时长应等于各段**有效刷牙**之和,从不超过墙钟。
- [ ] **D4 被杀后 relaunch 补提交(快照)。** 刷约 1 分钟 → 切后台 → 在后台**强制划掉 app**(或等系统回收)→ 重新打开。期望:今日记录里**多出一条** ~1 分钟、guided-only 的 session(快照补提交),而**不是**这次刷牙凭空消失。
- [ ] **D5 中断里 cue 不丢。** 在某条语音提示快响的时点前后中断再恢复,恢复后**不应**永久跳过那条内容/鼓励 cue(`<=` 扫描兜底)。

---

## E. 相机权限降级(U4)—— 不黑屏、不误标

> 需要能改系统相机权限:设置 → ToothBuddy → 相机。

- [ ] **E1 拒权 → 纯音频降级,不黑屏。** 关掉 ToothBuddy 的相机权限,Settings 里仍选 **Mirror**,点 START。期望:**不黑屏**;显示 **"Camera off — guiding you by voice"** 提示条(整场常驻);能纯音频走完;结束卡是 **guided-only**。
- [ ] **E2 权限未决时点 START 不误标。** 全新安装(相机权限 = 未问过),进刷牙页,在系统相机弹窗**还没点**之前就快速点 START → 应**等你回答弹窗**再开始;若你点**允许**,这次应能 camera-verified(**不**被错误地标成 guided-only)。
- [ ] **E3 audio 模式不显示降级提示。** Settings 选 **Audio**(主动不要相机)→ START → **不应**出现 "Camera off" 提示条(主动选音频不算"降级")。

---

## F. 收尾 & 记录 / 牙医证明(U5)

- [ ] **F1 空态导出不误导。** 零记录状态(全新装、没刷过)→ History → "Share dentist report" → 生成的 PDF 应明确写 **"No sessions recorded yet."**,而**不是**一张全是 0 的正常排版表。
- [ ] **F2 有数据导出正常。** 刷几次后导出 → PDF 含 sessions / thorough / camera-verified 计数 + 日历网格;verified vs guided 区分清楚。
- [ ] **F3 导出失败有提示(尽量构造)。** 若能制造写入失败(如存储极满)→ 应弹 **"Couldn't create the report"** alert,而**不是**点了按钮没反应。(难复现可跳过,只要确认代码路径在。)
- [ ] **F4 空曲线占位。** 记录很少时,History 的 Consistency 曲线区显示 **"A few more days and your curve appears here."**,不空白、不崩。

---

## G. Apple 集成(管道保留,真机验)

- [ ] **G1 Live Activity / 灵动岛分区进度。** session 进行中锁屏 / 灵动岛应显示**分区进度**(已完成区数 / 总区数)+ 剩余时间,profileName 为机主名。中断暂停时不应乱跳。
- [ ] **G2 HealthKit 随 metMinimum。** Settings 开 Apple Health 连接 + 授权。**达标**的 session 应写入 Health 的 toothbrushing event;**未达标/提前结束**的按设计不写(或不标 completed)。
- [ ] **G3 Siri 播报质量。** 触发"我的刷牙 streak"类 Siri 意图 → 播报应是**质量指标**(本周达标次数 / 今日是否达标),不再是单纯打卡 streak。
- [ ] **G4 Widget 质量主角。** 主屏 widget 主显**今日质量状态**(达标 / 覆盖),streak 降为小角标。
- [ ] **G5 通知文案。** 提醒类通知文案是质量/回来记录导向,不是旧的纯打卡口吻。

---

## 验完之后

- 全 ✅ → Phase 1.5 本地闭环通过,可以进入 Phase 2(联网分享)的规划,或回头做视觉精修 / App Store 材料(north-star 里延后的那批)。
- 有 ❌ → 把"实际看到什么"记在对应条目下,回报给我;相机映射(C1)/阈值(C2)这类是预期需要真机微调的,不算 Phase 1.5 的回归。
