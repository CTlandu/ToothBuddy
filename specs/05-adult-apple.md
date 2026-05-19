# Spec 05 — Adult Mode + First-Party Apple Integrations

> **Reading order for any AI session:** `ROADMAP.md` → `PLAN.md` → this file.
> Implementation is **blocked until the Confirm gate (§1) is checked**.
> **[OPEN-n]** = unresolved decisions; the detailed sections assume the **PROPOSED**
> answers. Honors product principles: iPhone software-only, local-first, never lose a
> record, no third-party hardware, Apple Watch stays in the far backlog.

## 1. Status
- [x] 1. Spec drafted
- [x] 2. Confirm gate — user approved 2026-05-19 (all PROPOSED) ✅
- [ ] 3. Test infra delta (none expected — pure logic in existing ToothBuddyCore; new
       Widget extension target added to `project.yml` at P5.3)
- [ ] 4. Implement (TDD, staged P5.1 → P5.4)
- [ ] 5. Verify
- [ ] 6. Docs
- [ ] 7. Commit

## 2. Problem & Goal
ToothBuddy today is a kid-shaped experience (stars, confetti, Sugar Bugs, playful voice).
The adult software-only segment is near-empty in the market, and Apple's first-party
surfaces (Health, Lock Screen / Dynamic Island, Home Screen widgets, Siri) are low-cost,
high-retention touchpoints we don't use at all. **Goal:** (a) give an adult a calm,
gamification-free experience that still rewards consistency, and (b) integrate with the
Apple ecosystem so brushing shows up where the user already looks — without any
third-party hardware, without Apple Watch (far backlog), and without losing the
local-first / never-lose-a-record guarantee.

## 3. User Stories
- As an **adult**, I want a quiet mode — no stars, no confetti, no Sugar Bugs, no
  kid voice — just a clean streak and a habit/consistency curve, so the app feels made
  for me.
- As an **adult in a family group**, my profile is adult while my kid's profile stays
  playful on the *same device* — switching profiles switches the whole experience.
- As **any user**, I can say "Hey Siri, I brushed my teeth" or tap a Shortcut/widget and
  have today's session logged without opening the app.
- As **any user**, a Lock Screen / Dynamic Island Live Activity shows the live 2-minute
  brushing timer; a Home Screen widget shows my streak and whether today is done.
- As a **health-tracking user**, completed brushing sessions appear in Apple Health
  (`toothbrushingEvent`) so my dental habit lives alongside the rest of my health data —
  only if I explicitly grant permission, and never overwriting or reading other data.

## 4. Scope & Staging (all under P5; ordered, each verified & committed)
- **P5.1 — Adult minimal mode** (pure + app; **fully doable now, no Apple-Dev gate**).
  Per-profile `Profile.mode` (`kid` default | `adult`). `adult` ⇒ minimal UI (no
  Sugar Bugs overlay, no stars/confetti, calm copy, `essentials` content tone default),
  plus a quiet **habit curve** (rolling adherence/consistency trend). The curve math is
  pure/tested in Core (`HabitCurve`); presentation is app-layer smoke.
- **P5.2 — App Intents / Siri Shortcuts** (app; **doable now, no entitlement/extension**).
  `AppIntents` (iOS 16+): "Log brushing", "Start brushing", "Brushing streak" — operating
  on the **active profile**, idempotent for the day, surfaced to Siri & the Shortcuts app.
- **P5.3 — Home-screen widgets + Live Activities** (app; needs a **new Widget Extension
  target** + an **App Group** for app↔widget data — see [OPEN-4]). WidgetKit timeline:
  streak + today AM/PM done state; ActivityKit Live Activity for the live brushing timer
  (Lock Screen + Dynamic Island). Countdown/timeline math is pure/tested; rendering &
  ActivityKit lifecycle are smoke/device.
- **P5.4 — HealthKit `toothbrushingEvent`** (app; **partially Apple-Dev-gated, see
  [OPEN-3]**). On a completed session, write one `HKCategorySample` of
  `.toothbrushingEvent`, behind explicit authorization, **write-only**, idempotent (no
  duplicate per session). The *decision/dedupe/mapping* logic is pure/tested in Core
  (`HealthExportDecider`); the `HKHealthStore` save + Health-app verification is
  app-layer smoke / device-only.

**Deferred to the far backlog (unchanged):** Apple Watch CoreMotion brushing-motion
sensing. **Deferred / not in P5:** macOS/iPad-specific UI, App Store widgets gallery
art, watchOS companion.

## 5. Apple-Developer Gating — explicit (read before [OPEN-3])
This is **materially less gated than P2.5b (CloudKit)**. P2.5b required a *manually
created CloudKit container in the developer portal* plus *two iCloud accounts and two
devices* for a share/convergence smoke — none of which can be done autonomously. P5 needs
only **entitlements declared in `project.yml`** which **automatic signing provisions
without any manual portal step**:
- **HealthKit:** entitlement `com.apple.developer.healthkit` (a boolean) + Info.plist
  `NSHealthUpdateUsageDescription`. No container, no portal object to create. Automatic
  signing with the existing `DEVELOPMENT_TEAM` adds the capability.
- **App Group (for widget↔app data):** `com.apple.security.application-groups` with id
  `group.com.ctlandu.ToothBuddy`. Automatic signing registers the group; no manual portal
  container creation, no second account/device.
- **Live Activities:** Info.plist `NSSupportsLiveActivities = YES`. No entitlement.
- **App Intents / widgets:** no entitlement at all.

CLI test builds use `CODE_SIGNING_ALLOWED=NO`, so entitlements are **not enforced** for
build/`xcodebuild test` — implementation, unit tests, and the app test target all stay
green autonomously. What genuinely **cannot be done by an AI** and is therefore the
**user-pending smoke** (same established pattern as the P4 camera/game visual smokes):
running a real signed build on a device to (a) grant HealthKit permission and see the
sample in the **Health app**, (b) see the **Live Activity** in the Dynamic Island /
Lock Screen, (c) add the **widget** from the gallery, (d) trigger the **Siri/Shortcut**
intent. No multi-account or multi-device setup is required anywhere in P5.

## 6. Exact Behavior (assumes PROPOSED answers)

### 6.1 Profile mode (P5.1)
- `Profile` gains `mode: ProfileMode` (`kid` | `adult`), **default `kid`**.
- Migration: every existing stored profile is read as `kid` (the new attribute is
  optional in the Core Data model with a `kid` default → zero-loss, CloudKit-compatible,
  consistent with the P2.1 additive-schema rule).
- Switching the active profile to an `adult` profile changes the **whole experience**
  for that profile only (a `kid` sibling profile on the same device is unaffected).
- `adult` presentation rules (app layer):
  - `BrushView`: **no** `BrushGameOverlay` (Sugar Bugs), **no** stars/confetti on the
    Done sheet (a quiet "Done — morning ✓ / evening ✓" summary instead), calm copy.
  - Content tone **defaults to `essentials`** for an adult profile (the existing P3
    per-device tone still wins if the user explicitly set it; adult only changes the
    *default*). No jokes/story beats; terse, calm narration.
  - Streak/stats shown as a quiet number + the habit curve (§6.2); no game language.
- A `kid` profile is byte-for-byte the current experience (no regression).

### 6.2 Habit curve (P5.1, pure)
`HabitCurve.points(records:profileID:asOf:days:calendar:)` → an ordered
`[HabitCurvePoint]` (one per day in the window, oldest→newest), each with `date`,
`completed01` (0 = no session, 0.5 = one slot, 1.0 = perfect day) and a smoothed
`adherence` (rolling mean over a fixed short window, clamped 0…1). Profile-isolated
(reuses the existing `ProfileScopedAggregator`), deterministic given inputs, no storage.
Adult UI renders it as a small calm line/area; kid UI never shows it.

### 6.3 App Intents (P5.2)
- **LogBrushingIntent** ("Log brushing", "I brushed my teeth"): records a session for the
  **active profile** at `now`, mapped to the current slot (AM/PM by the existing noon
  boundary). **Idempotent within a slot**: a second invocation in the same slot/day does
  not create a duplicate or inflate the streak — it returns a "already logged" dialog.
- **StartBrushingIntent** ("Start brushing"): opens the app into `BrushView` and begins a
  session (and, P5.3, starts the Live Activity). If the app can't foreground, it still
  logs intent to start; no crash.
- **BrushingStreakIntent** ("What's my brushing streak"): returns a spoken/recapped
  current streak for the active profile (read-only, via `StreakEngine`).
- All intents operate **only** on the active profile, never silently switch profiles,
  and degrade gracefully if no profile exists (guide the user to open the app).
- `AppShortcutsProvider` exposes the phrases to Siri & the Shortcuts app.

### 6.4 Widgets (P5.3)
- A WidgetKit widget (small + medium) for the **active profile**: current streak,
  today's AM/PM done state, and "at risk" if the evening slot is pending late in the day.
- Data path: the app writes a tiny **snapshot** (`WidgetSnapshot`: profile name, streak,
  amDone, pmDone, asOf) to the shared **App Group** container on every relevant change
  (session logged, profile switched, scene background). The widget timeline provider
  reads only that snapshot — it never touches Core Data directly (keeps the widget cheap
  and crash-safe). Snapshot building is pure/tested (`WidgetSnapshotBuilder`).
- No data ⇒ a friendly placeholder ("Open ToothBuddy to get started"), never blank/crash.

### 6.5 Live Activity (P5.3)
- Started when a brushing session starts (in-app or via StartBrushingIntent), showing the
  live 2-minute countdown and current quadrant/zone hint on the Lock Screen and Dynamic
  Island. Ended when the session finishes or is cancelled; auto-ends via a stale-dismiss
  policy if the app is killed mid-session (never a stuck Live Activity).
- The countdown/segment math is the **already-tested P3 `SessionScript`** timeline;
  the Live Activity only renders it. ActivityKit lifecycle is app-layer smoke.
- If Live Activities are unsupported/disabled, brushing works unchanged (additive only).

### 6.6 HealthKit (P5.4)
- On a **completed** session (the same completion event the streak uses), if the user has
  granted `toothbrushingEvent` **share** authorization, write exactly one
  `HKCategorySample(.toothbrushingEvent, value: notApplicable, start:end:)` covering the
  session window, with metadata `HKMetadataKeyExternalUUID` = the session's stable id.
- **Idempotent:** `HealthExportDecider.shouldExport(session:alreadyExportedIDs:)` ⇒ never
  write the same session twice (the app keeps a small per-device exported-id set;
  re-completion / app relaunch does not duplicate). Pure/tested.
- **Write-only, opt-in, revocable:** never *read* Health data; nothing is written before
  explicit authorization; revoking permission silently disables export (no error spam,
  no data loss locally — the local record is always the source of truth).
- Authorization is requested **contextually** (a clear in-app prompt in adult settings or
  after a session when the user opts in), never on cold launch.

## 7. Data Model
- **Core Data (additive, CloudKit-compatible, zero-loss):** `CDProfile.mode` (String,
  optional, default `"kid"`), mirrored on Core `Profile`. Follows the exact P2.1
  additive-attribute migration rule (optional + default ⇒ existing rows read as `kid`;
  legacy JSON path unaffected).
- **Per-device only (UserDefaults / App Group), not synced, not per-profile-synced:**
  exported-to-Health session id set; the App Group `WidgetSnapshot`; Live Activity
  current-activity token. None of these are records — losing them never loses a brushing
  record (Health re-export is naturally deduped by the id set + `HKMetadataKeyExternalUUID`).
- **No new record types.** Brushing records are unchanged; everything here derives from
  or mirrors existing per-profile data.

## 8. API Surface (ToothBuddyCore, pure)
```swift
public enum ProfileMode: String, Sendable { case kid, adult }            // on Profile
// Profile gains: public var mode: ProfileMode  (default .kid)

public struct HabitCurvePoint: Equatable, Sendable {
    public let date: Date
    public let completed01: Double      // 0, 0.5, or 1.0
    public let adherence: Double        // smoothed rolling mean, 0...1
}
public enum HabitCurve {
    public static func points(records: [BrushingRecord], profileID: UUID,
                              asOf: Date, days: Int, calendar: Calendar) -> [HabitCurvePoint]
}

public struct WidgetSnapshot: Equatable, Sendable, Codable {
    public let profileName: String
    public let currentStreak: Int
    public let amDone: Bool
    public let pmDone: Bool
    public let atRisk: Bool
    public let asOf: Date
}
public enum WidgetSnapshotBuilder {
    public static func build(records: [BrushingRecord], profileID: UUID,
                             profileName: String, asOf: Date,
                             calendar: Calendar) -> WidgetSnapshot
}

public enum HealthExportDecider {
    /// Pure: should this completed session be written to Health, given prior exports?
    public static func shouldExport(sessionID: UUID, isCompleted: Bool,
                                    alreadyExportedIDs: Set<UUID>) -> Bool
}
```
App layer (no new pure logic): `ProfileStore` carries `mode`; `BrushView`/Done sheet
branch on `mode`; an `AppIntents` file (`LogBrushingIntent`/`StartBrushingIntent`/
`BrushingStreakIntent` + `AppShortcutsProvider`); a `ToothBuddyWidget` extension target
(WidgetKit + ActivityKit) reading the App Group snapshot; a thin `HealthExporter`
wrapping `HKHealthStore` behind `HealthExportDecider`; an `AppGroupStore` writing
`WidgetSnapshot`.

## 9. Edge Cases (each → expected behavior)
- **Existing profiles after update** → all read as `kid`; no UI/behavior change for them.
- **Mixed family on one device** → switching to an `adult` profile flips only that
  profile's experience; `kid` siblings unchanged.
- **User set `essentials` tone in P3, profile is `kid`** → tone stays `essentials`
  (explicit user setting wins; adult only changes the *default*).
- **Intent fired with no profiles / first run** → no crash; dialog directs to open the app.
- **LogBrushingIntent twice in one slot** → second is a no-op "already logged today";
  streak not inflated (reuses existing per-slot idempotency).
- **App killed mid-session with a Live Activity** → activity auto-dismisses by the stale
  policy; no stuck Lock Screen timer; local record integrity unaffected.
- **Widget with stale/no snapshot** → shows last known or a friendly placeholder; never
  blank, never crashes, never reads Core Data on the widget side.
- **HealthKit permission denied / later revoked** → export silently disabled; no error
  spam; local records remain the source of truth; re-grant resumes (deduped).
- **Same session re-completed / app relaunched** → `HealthExportDecider` blocks a second
  write; `HKMetadataKeyExternalUUID` is a second safety net.
- **Live Activities unsupported (older device / disabled in Settings)** → brushing works
  exactly as before; nothing degraded.

## 10. Acceptance Criteria (each maps to a test)
- **AC1** `Profile` defaults to `mode == .kid`; decoding a profile with no stored mode
  yields `.kid` (migration parity).
- **AC2** `HabitCurve.points` returns exactly `days` points oldest→newest;
  `completed01 ∈ {0, 0.5, 1.0}` per the day's slots; profile-isolated (another profile's
  records don't bleed in); deterministic for fixed inputs.
- **AC3** `HabitCurve` `adherence` is the clamped rolling mean over the fixed window
  (0…1), correct at the series start (partial window) and end.
- **AC4** `WidgetSnapshotBuilder.build` reports correct streak/amDone/pmDone for a known
  record set; `atRisk` true only when PM pending and `asOf` is in the late-evening band;
  profile-isolated; deterministic.
- **AC5** `HealthExportDecider.shouldExport` is `true` only when completed **and** the id
  is not in `alreadyExportedIDs`; `false` if incomplete or already exported.
- **AC6** App-layer: a `kid` profile shows the Sugar Bugs overlay & stars; an `adult`
  profile shows neither and uses the calm Done summary (smoke + a wiring assertion where
  feasible).
- **AC7** App-layer: `LogBrushingIntent` invoked twice in one slot yields one logged
  session (idempotent), streak unchanged on the second call.
- **AC8** Library/model integrity: adding `mode` does not change any existing P1–P4 Core
  test result (full suite still green; additive only).

## 11. Test Plan
Unit (`ToothBuddyCore` `swift test`) — one test per AC1–AC5 + AC8 (fixed `Calendar`,
fixed clock, fixed seeds; profile-isolation cases). App target (`xcodebuild test`) —
AC6/AC7 wiring + the intents' idempotency against the existing per-slot rule. **Manual
smoke (user-pending, device-only — §12):** HealthKit grant + sample visible in the Health
app; Live Activity on Lock Screen / Dynamic Island; widget added from the gallery; Siri
phrase + Shortcuts app entry; adult vs kid profile visual switch.

## 12. Manual Smoke Checklist (user runs on a signed device)
1. Update an install that has existing profiles → all still present, behave as `kid`,
   no data loss (P2.1 migration parity holds).
2. Create/flip a profile to `adult` → BrushView has no Sugar Bugs, no stars/confetti;
   calm Done summary; narration is `essentials`. Switch back to a `kid` profile → full
   playful experience returns. (Mixed-family isolation.)
3. "Hey Siri, I brushed my teeth" and the Shortcuts-app actions → logs the active
   profile's session; repeating in the same slot says "already logged" and does not
   inflate the streak.
4. Start a session → Live Activity appears on Lock Screen + Dynamic Island with the live
   2-min countdown; ends cleanly on finish/cancel; kill the app mid-session → no stuck
   activity.
5. Add the Home Screen widget (small + medium) → shows streak + today AM/PM; updates
   after logging; placeholder before any data; never blank/crash.
6. Adult settings → grant Health permission → complete a session → exactly one
   tooth-brushing entry in the Health app; complete again / relaunch → still exactly one
   (no duplicates). Revoke in Settings → export stops, app & local records unaffected.

## 13. OPEN QUESTIONS — confirm before implementation ⛔
- **[OPEN-1] Scope & staging.** P5 = P5.1 adult-minimal mode + P5.2 App Intents/Siri +
  P5.3 widgets/Live Activities + P5.4 HealthKit `toothbrushingEvent`, in that order, each
  TDD-verified & committed. (**PROPOSED:** yes.)
- **[OPEN-2] Adult mode shape.** Per-**profile** `Profile.mode` (`kid` default | `adult`;
  existing profiles migrate to `kid`; adult ⇒ minimal UI + `essentials` default) — so a
  family can mix kids & adults on one device. Alternative: a single per-**device** toggle
  (simpler, but wrong for the P2 multi-profile family model). (**PROPOSED:** per-profile.)
- **[OPEN-3] Apple-Developer gating.** Implement **all** of P5.1–P5.4 now (entitlements
  declared in `project.yml`; automatic signing provisions HealthKit + App Group with **no
  manual portal step and no multi-account/multi-device** — unlike P2.5b), with only the
  on-device visual/permission checks in §12 deferred to the user's smoke pass (same
  pattern as the P4 camera/game smokes). Alternative: park P5.4 (and/or P5.3) like P2.5b.
  (**PROPOSED:** implement all now; only §12 device smoke is user-pending — P5 is *not*
  blocked the way P2.5b is.)
- **[OPEN-4] New Widget extension target.** P5.3 adds a `ToothBuddyWidget`
  app-extension target to `project.yml` (WidgetKit + ActivityKit), sharing logic via the
  `ToothBuddyCore` package and data via the App Group `group.com.ctlandu.ToothBuddy`.
  Confirm adding this target + App Group id. (**PROPOSED:** yes, that id.)
- **[OPEN-5] HealthKit scope.** Strictly **write-only** `toothbrushingEvent` category
  samples on completed sessions, opt-in & revocable, idempotent, **no reading** any Health
  data, no other Health types. (**PROPOSED:** yes.)

_Answers — confirmed by user 2026-05-19:_
- **OPEN-1 →** Accepted: all 4, in order P5.1 → P5.2 → P5.3 → P5.4.
- **OPEN-2 →** Per-**profile** `Profile.mode` (`kid` default | `adult`; additive zero-loss
  migration; adult ⇒ minimal UI + `essentials` default).
- **OPEN-3 →** Implement **all** of P5.1–P5.4 now; entitlements declared in `project.yml`
  (automatic signing covers HealthKit + App Group — no manual portal step, no
  multi-account/multi-device). Only the §12 on-device visual/permission smoke is
  user-pending (same pattern as the P4 camera/game smokes). P5 is **not** parked like P2.5b.
- **OPEN-4 →** Yes: add the `ToothBuddyWidget` app-extension target to `project.yml`
  (WidgetKit + ActivityKit) with App Group id `group.com.ctlandu.ToothBuddy`.
- **OPEN-5 →** Strictly write-only `toothbrushingEvent`, opt-in & revocable, idempotent,
  **no reading** any Health data, no other Health types.
No remaining blocking OPENs.

## 14. Docs to Update (Phase 6)
`README.md` (adult mode + Apple integrations), `ROADMAP.md` (P5 ticks),
`PLAN.md` (P5 status board + decision log), `CHANGELOG.md`, this Status §1 + §13 answers.

## 15. Out of Scope
Apple Watch CoreMotion / any motion sensing (far backlog); third-party hardware/BLE;
reading any HealthKit data; CloudKit/iCloud work (that is P2.5b, separately parked);
watchOS/macOS/iPad-specific UI; widget marketing art; LLM/online features.
