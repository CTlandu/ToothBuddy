# App Store Connect Listing — ToothBuddy 1.0

Plan U9 (`docs/plans/2026-05-28-002-feat-app-store-launch-plan.md`).

Source of truth for everything you paste into App Store Connect when submitting. Update this file alongside metadata changes so version-N+1 has a working diff base.

URLs marked `[VERCEL]` are placeholders — replace with the real Vercel URLs once the user spins them up.

---

## General Info

| Field | Value |
|------|-------|
| App Name | ToothBuddy |
| Primary Language | English (U.S.) |
| Bundle ID | `com.ctlandu.ToothBuddy` |
| SKU | `toothbuddy-ios-1` |
| Category — Primary | Health & Fitness |
| Category — Secondary | (leave blank) |
| Content Rights | This app does NOT contain, show, or access third-party content. |
| Age Rating | 4+ |
| Regulated Medical Device | **No** (see `docs/app-store-review-notes.md`) |

### Age Rating questionnaire (all answers)

| Question | Answer |
|---|---|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Prolonged Graphic or Sadistic Realistic Violence | None |
| Profanity or Crude Humor | None |
| Mature/Suggestive Themes | None |
| Horror/Fear Themes | None |
| Medical/Treatment Information | None |
| Alcohol, Tobacco, or Drug Use or References | None |
| Simulated Gambling | None |
| Sexual Content or Nudity | None |
| Graphic Sexual Content and Nudity | None |
| Unrestricted Web Access | No |
| Gambling | No |
| User-Generated Content | No |
| Frequent/Intense Medical Treatment Info | **No** (this matters — keep at No) |

→ Resulting age rating: **4+**

---

## Pricing & Availability

| Field | Value |
|------|-------|
| Price | Free |
| Availability | All territories |
| Pre-order | Not used |

---

## Privacy

| Field | Value |
|------|-------|
| Privacy Policy URL | `[VERCEL: https://toothbuddy.app/privacy]` |
| Privacy Choices URL | (leave blank — no analytics / no choices to surface) |

### Privacy Nutrition Label (App Privacy section)

Answer **"Data Not Collected"** for ALL four sections:

- Data Used to Track You → **Data Not Collected**
- Data Linked to You → **Data Not Collected**
- Data Not Linked to You → **Data Not Collected**
- Data Not Collected → (confirm the above)

Justification (for your own reference if reviewer asks):
- HealthKit writes go to the user's Apple Health DB on device. Apple-side processing on user's own device is explicitly excluded from "data collected" per Apple's guidance.
- Camera frames are processed by Vision on-device and discarded; never recorded.
- No analytics, no third-party SDKs (verify by grepping `Package.swift` external deps).
- No advertising, no IDFA, no tracking permissions ever requested.

---

## App Information (per locale)

### English (en-US)

| Field | Value |
|---|---|
| Name | ToothBuddy |
| Subtitle | Build a real brushing habit, every day. |
| Promotional Text (170 chars; updatable without review) | A calm, offline brushing habit tracker for kids and adults. No account, no tracking — just a 2-minute timer, gentle reminders, and a streak that doesn't break unfairly. |

**Description (4000 chars max; below is ~1400 chars):**

```
ToothBuddy helps kids and adults build a real twice-a-day brushing habit — without an account, without a server, and without losing a single record.

WHAT IT DOES

• Forgiving streak: one missed day doesn't reset weeks of progress. Two consecutive misses still resets, so it's honest. Your longest streak is tracked and never decreases.

• Morning + evening goals (ADA's twice-a-day standard). Adaptive reminders learn your typical brushing times. A gentle "streak at risk" nudge in the evening if you haven't brushed yet.

• Multi-profile family: add a profile per family member, with isolated records, streaks, achievements, and care reminders (brush head, dentist). Everyone sees everyone — no admin role.

• Camera-guided sessions (engagement-grade): the front camera shows you which tooth zones you've covered. Camera frames stay on device; nothing is recorded, saved, or sent anywhere. A timed fallback works without the camera.

• Sugar Bugs mini-game for kids: jelly bugs to sweep away while you brush. Reduce-Motion aware.

• Adult mode: calm presentation. No stars, no confetti — just a habit curve.

• Apple ecosystem: Live Activity + Dynamic Island during a session. Home Screen widget showing today's morning/evening status. Siri Shortcuts ("Start brushing", "What's my streak?"). Optional, write-only Apple Health export of tooth-brushing events.

• Dentist-shareable PDF report (30/90/365 days) from the Family dashboard.

PRIVACY

ToothBuddy is fully offline. No account. No analytics. No advertising. No third-party SDKs. Your data lives on your device.
```

**Keywords (100 chars; comma-separated, no leading "ToothBuddy"):**

```
brushing,teeth,habit,streak,family,health,timer,kids,routine,dentist
```

**What's New in This Version (1.0):**

```
Hello, world! ToothBuddy 1.0 is here. Build a real brushing habit, every day.
```

**Support URL:** `[VERCEL: https://toothbuddy.app/support]`

**Marketing URL:** (leave blank for v1)

---

### Simplified Chinese (zh-Hans)

| Field | Value |
|---|---|
| Name | ToothBuddy |
| Subtitle | 每天养成真正的刷牙习惯。 |
| Promotional Text | 一款离线、安静的刷牙习惯应用，适合儿童和成人。不需要账号，不追踪你——只有 2 分钟计时器、贴心提醒，以及一个不会被不公平打断的连续天数。 |

**Description (中文):**

```
ToothBuddy 帮助儿童和成人养成真正的每日两次刷牙习惯——不需要账号、不需要服务器、不会丢失任何一条记录。

主要功能

• 宽容的连续天数：偶尔漏刷一天不会让你前功尽弃。连续漏刷两天才会重置，这样既宽容又诚实。你的最长连续记录会一直保留，永不下降。

• 早晚目标（ADA 推荐每天两次）：自适应提醒会学习你日常的刷牙时间。如果晚上还没刷牙，会有一条温和的"连续记录有风险"提示。

• 多档案家庭支持：为每个家人添加独立档案，每个人的记录、连续天数、成就、关怀提醒（刷头、牙医）都互相隔离。家人之间互相看得到——没有管理员角色。

• 相机刷牙引导（仅辅助参与感）：前置摄像头帮你看清刷到哪些区域了。相机画面只在设备本地处理，绝不录制、不保存、不发送到任何地方。没有相机也可用计时模式。

• 儿童糖虫小游戏：刷牙时清理果冻糖虫。支持降低动画效果。

• 成人模式：界面安静，没有星星和彩纸，只有一条习惯曲线。

• Apple 生态集成：刷牙时的 Live Activity + 灵动岛。主屏 Widget 显示今日早晚刷牙状态。Siri 快捷指令（"开始刷牙"、"看连续刷牙天数"）。可选的 Apple 健康导出（仅写入刷牙事件）。

• 牙医分享 PDF 报告（近 30/90/365 天）：从家庭面板生成。

隐私

ToothBuddy 完全离线运行。没有账号。没有分析统计。没有广告。没有第三方 SDK。你的数据只在你的设备上。
```

**Keywords (zh-Hans, 100 chars):**

```
刷牙,牙齿,习惯,连续,家庭,儿童,健康,计时,提醒,牙医
```

**What's New in This Version (1.0) — zh-Hans:**

```
你好，ToothBuddy 1.0 来啦！每天养成真正的刷牙习惯。
```

**Support URL (zh-Hans):** `[VERCEL: https://toothbuddy.app/support]` (same as en — server picks lang)

**Marketing URL:** (留空)

---

## App Review Information

### Sign-in & Demo Account
- **Sign-in required:** No
- **Demo account:** Not applicable

### Contact Information
- First Name: Colin
- Last Name: Tang
- Email Address: `colintangxy@gmail.com`
- Phone Number: (fill in when submitting)

### Notes (paste from `docs/app-store-review-notes.md`)
See `docs/app-store-review-notes.md` for the full reviewer-facing notes including:
- Offline / no-account / no-network declaration
- HealthKit write-only `toothbrushingEvent` flow
- Camera Vision processing (never recorded)
- Regulated Medical Device declaration = No
- TestFlight notes if external testers needed

### Attachment
(optional) — a short walkthrough video helps but is not required.

---

## Submission Checklist (before tapping "Submit for Review")

- [ ] Privacy Policy URL is reachable (replace VERCEL placeholder)
- [ ] Support URL is reachable
- [ ] Screenshots uploaded (iPhone 6.9" + iPad 13", 3-5 each per locale)
- [ ] App Preview video uploaded (optional but recommended)
- [ ] Privacy Nutrition Label = Data Not Collected (4 sections)
- [ ] Age Rating questionnaire answered (4+)
- [ ] Regulated Medical Device = No
- [ ] Export Compliance = No encryption beyond standard iOS
- [ ] Content Rights = does not contain third-party content
- [ ] App Review Notes filled in (copy from `docs/app-store-review-notes.md`)
- [ ] Build selected (must be processed for at least 15 min after Xcode upload)
- [ ] What's New copy filled in (en + zh-Hans)
- [ ] Localization both languages have all fields filled
