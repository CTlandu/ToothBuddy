# Spec 01 — Habit & Behavior Engine

> **Reading order for any AI session:** `ROADMAP.md` → `PLAN.md` → this file.
> Implementation of this spec is **blocked until the Confirm gate below is checked**.
> Items tagged **[OPEN-n]** are unresolved product decisions — do not implement until resolved in §12.

## 1. Status

- [x] 1. Spec written
- [x] 2. Confirm gate (user approved §12 answers 2026-05-18) ✅
- [ ] 3. Test infra (`ToothBuddyCore` + XCTest)
- [ ] 4. Implement (TDD)
- [ ] 5. Verify
- [ ] 6. Docs
- [ ] 7. Commit

## 2. Problem & Goal

**Problem.** Today's streak (`BrushingStore.consecutiveDaysCount`) breaks the instant one day is missed — the single most-cited complaint in competitor reviews. There are no reminders at all. Onboarding is shown on **every** launch (a Swift Student Challenge leftover in `MyApp.swift`), which is hostile to returning users.

**Goal.** A streak that is fair (survives an occasional miss), reminders that arrive near the user's real brushing times, and a returning user who lands straight in the app. Zero sensing; pure habit mechanics. This is the highest-retention, lowest-risk foundation.

## 3. User Stories

- As a **user**, if I miss one day after brushing for weeks, I do not lose everything, so I stay motivated.
- As a **user**, I get a reminder around the time I normally brush, not a random alarm.
- As a **user**, if I haven't brushed and my streak is at risk, I get one gentle nudge in the evening.
- As a **returning user**, the app opens to the main screen, not onboarding.
- As a **user**, I can see my current streak, my longest-ever streak, and when a "freeze" saved me.

## 4. Exact Behavior

### 4.1 Session slots

Each `BrushingRecord` maps to a **slot** by the hour of `startDate` in the user's calendar:

- `morning` if `hour < SLOT_BOUNDARY_HOUR`
- `evening` if `hour >= SLOT_BOUNDARY_HOUR`

`SLOT_BOUNDARY_HOUR` proposed = **12** (local). **[OPEN-1]**

A calendar day is:
- **active** — ≥ 1 session that day
- **perfect** — ≥ 1 morning session **and** ≥ 1 evening session that day

### 4.2 Streak definition

The streak counts consecutive **qualifying** days ending at the anchor day.

- A day **qualifies** if it is *active*. **[OPEN-2]** (alternative: qualifies only if *perfect*).
- Anchor day = today. If today has no session yet, today is "pending": it neither counts nor breaks the streak until the day ends; the displayed streak is the streak through yesterday, with a "brush today to keep your N-day streak" state.

### 4.3 Forgiving mechanic — **DECIDED: Option A (rolling grace), `GRACE_PERIOD = 7`**

Implement **only Option A**. Options B and C below are recorded for history only — **do not implement B or C**; do not add `mechanic`/`freezeEarnEvery`/`maxFreezes`/`repairWindowHours` to `StreakConfig` (drop them; keep only `slotBoundaryHour`, `gracePeriod`, `requirePerfectDay`). Option A is a pure deterministic function of the qualifying-day set + config (no stored mutable inventory → no migration, fully unit-testable).

_(Historical only — **NOT implemented**: Option B freeze inventory; Option C streak repair.)_

#### Option A — precise algorithm (implement exactly this)

Definitions: a **qualifying day** = an *active* day (≥1 session; `requirePerfectDay = false`). All day math uses one injected `Calendar`; "day" = `calendar.startOfDay`. `GRACE_PERIOD = 7`.

**Step 1 — anchor.** `today0 = startOfDay(now)`.
- If `today0` is qualifying → `anchor = today0`, `isTodayPending = false`.
- Else → `anchor = today0 − 1 day`, `isTodayPending = true` (today not yet brushed: streak is measured through yesterday and today does not break it yet).

**Step 2 — extend pass.** Walk backward from `anchor`, one day per step, building an ordered run (newest→oldest). For each `day`:
- if `day` qualifying → append as `qualifying`, continue.
- else (missed) → if the **immediately newer** day in the run was also `missed` → **stop** (two missed in a row), excluding this day; else append as `missed`, continue.
- Stop when the day is older than the earliest record's day. If the run's oldest element is `missed`, drop that trailing missed day.

**Step 3 — trim pass (budget).** Let `Q` = count of qualifying, `M` = count of missed in the run. While `M > floor(Q / GRACE_PERIOD)`: remove the run's **oldest segment up to and including its oldest `missed` element** (drop everything from run-start through the earliest missed day); recompute `Q`, `M`. Result is the longest most-recent suffix satisfying the budget.

**Step 4 — result.** `currentStreak = Q` (missed/"frozen" days keep the streak contiguous but do **not** increment the count). `frozenDays` = `startOfDay` of every `missed` day remaining after trim (UI shows "🛡 saved"). Never negative. Future-dated records (clock moved back) are ignored by the backward walk.

**Worked examples (become tests):**
- E1: 10 qualifying days, today qualifying → `Q=10, M=0` → `currentStreak=10`. *(AC1)*
- E2: 20 qualifying, then 1 missed, then today qualifying → run `Q=21, M=1`; `floor(21/7)=3 ≥ 1` → no trim → `currentStreak=21`, `frozenDays=[the missed day]`. *(AC2)*
- E3: 5 qualifying, missed, missed, 10 qualifying, today qualifying → extend stops at the two consecutive misses → run = 10 + today, `Q=11, M=0` → `currentStreak=11` (the older 5 are severed). *(AC3)*
- E4: 2 qualifying, missed, 3 qualifying, today qualifying → run `Q=6, M=1`; `floor(6/7)=0 < 1` → trim drops the 2 + the miss → `Q=4, M=0` → `currentStreak=4`. *(AC3b)*

### 4.4 Longest streak

`longestStreak` = max streak length ever observed across the full history under the chosen mechanic. It never decreases. Derived, not separately mutated.

### 4.5 Reminders

The app schedules **local** notifications only. Three reminder kinds:

| Kind | When | Skip if |
|------|------|---------|
| `morningRoutine` | user's typical morning brush time (see 4.6), today | a morning session already logged today |
| `eveningRoutine` | user's typical evening brush time, today | an evening session already logged today |
| `streakAtRisk` | `STREAK_RISK_HOUR` (proposed 20:30) local, today | any session logged today, **or** current streak == 0 |

`streakAtRisk` and `eveningRoutine` must not both fire within `MIN_GAP_MINUTES` (proposed 60); if they collide, drop `eveningRoutine`. Re-evaluated and rescheduled whenever the app becomes active and after every logged session. **[OPEN-4]** confirms hours/gap and whether the user can edit times in this iteration (proposed: not editable yet — defaults + adaptive only).

### 4.6 Adaptive times

For each slot, typical time = median `startDate` time-of-day of the **last `ADAPT_WINDOW` sessions in that slot** (proposed window = 14). If fewer than `MIN_HISTORY` (proposed 3) sessions exist in a slot, use the default (`DEFAULT_MORNING` 08:00, `DEFAULT_EVENING` 20:30). Times computed in the user's calendar.

### 4.7 Notification permission

Requested **once, contextually**: immediately after the user's **first completed brushing session** (not on cold launch, not during onboarding). If denied, the app never re-prompts programmatically and functions normally without reminders. **[OPEN-4]**

### 4.8 Onboarding

Onboarding shows **only until completed once**. Persist `hasCompletedOnboarding` (UserDefaults via `@AppStorage`). Completion = the existing onboarding completion callback fires. Returning users go straight to `ContentView`. (Re-viewing onboarding later is **out of scope** here — Priority 5 settings.) **[OPEN-5]** (low-risk confirm).

## 5. Data Model & Migration

- **No change** to `BrushingRecord`'s stored JSON. Slots and streak are **derived**, never stored. → **zero migration**, no risk to existing user data.
- New persisted value: `hasCompletedOnboarding: Bool` in `UserDefaults` (default `false`).
- Streak/longest are recomputed from `records` on every load and after every add — deterministic, so always correct even across app versions.

## 6. API Surface

### New package `ToothBuddyCore` (platform-agnostic, no SwiftUI/UIKit)

Moved into Core (pure Foundation): `BrushingRecord`.

```swift
public enum SessionSlot: String, Codable, CaseIterable { case morning, evening }

public extension SessionSlot {
    init(hour: Int, boundaryHour: Int)            // pure
    static func slot(for date: Date, boundaryHour: Int, calendar: Calendar) -> SessionSlot
}

public struct StreakConfig: Equatable {
    public var slotBoundaryHour: Int              // 4.1 — DECIDED 12
    public var gracePeriod: Int                   // 4.3 Option A — DECIDED 7
    public var requirePerfectDay: Bool            // 4.2 — DECIDED false
    public static let `default` = StreakConfig(slotBoundaryHour: 12, gracePeriod: 7, requirePerfectDay: false)
}

public struct StreakResult: Equatable {
    public let currentStreak: Int
    public let longestStreak: Int
    public let frozenDays: [Date]                 // start-of-day list, for "🛡 saved" UI
    public let isTodayPending: Bool               // today active? if not and streak>0 → at risk
}

public enum StreakEngine {
    // The single source of truth. Pure. The TDD target.
    public static func evaluate(records: [BrushingRecord],
                                now: Date,
                                config: StreakConfig,
                                calendar: Calendar) -> StreakResult
}

public struct ReminderPlanInput {
    public let records: [BrushingRecord]
    public let now: Date
    public let streak: StreakResult
    public let config: ReminderConfig
}
public enum ReminderKind: String { case morningRoutine, eveningRoutine, streakAtRisk }
public struct PlannedReminder: Equatable { public let kind: ReminderKind; public let fireDate: Date }
public enum ReminderPlanner {
    public static func plan(_ input: ReminderPlanInput, calendar: Calendar) -> [PlannedReminder] // pure
}
```

### App layer (stays in `.swiftpm`, depends on `ToothBuddyCore`)

- `BrushingStore`: replace `consecutiveDaysCount` with `streak: StreakResult` (cached `@Published`, recomputed on `load()`/`add()`). Keep old name as a deprecated shim returning `streak.currentStreak` so `GamificationStore`/`HistoryView` compile unchanged; migrate call sites in this iteration.
- New `NotificationScheduler` (`@MainActor`): wraps `UNUserNotificationCenter`; `requestAuthorizationIfNeeded()`, `reschedule(from: BrushingStore)` consuming `ReminderPlanner.plan`. Not unit-tested (system); covered by smoke checklist. All scheduling math lives in the pure `ReminderPlanner`.
- `MyApp`/`RootView`: `@AppStorage("hasCompletedOnboarding")` gates onboarding; remove "show on every launch" comment + behavior.
- Call sites: request notification auth after first completed session; `reschedule` on `scenePhase == .active` and after `add()`.

## 7. Edge Cases

1. No records → streak 0, longest 0, no reminders, no crash.
2. Only today, only one session → streak shows pending→1 at day rollover; longest ≥ prior.
3. Multiple sessions same day/slot → counts as one active/qualifying day (no double counting).
4. Timezone / DST change → all date math uses one injected `Calendar`; tests cover a DST boundary.
5. Clock moved backward (now < latest record) → never produce negative streak; treat future records as "today" bucket; covered by test.
6. Two missed days in a row → reset under A/C and under B without ≥2 freezes.
7. Slot boundary exactly at `SLOT_BOUNDARY_HOUR:00` → boundary belongs to `evening` (`>=`).
8. Notification permission denied/undetermined → planner still returns plan; scheduler no-ops; no error UI.
9. Slot reminder time already passed when rescheduled → that reminder is skipped today (not fired immediately).
10. Onboarding completion callback fires twice → flag idempotent.
11. Huge history (years) → `evaluate` is O(n) over distinct days; test with 5000 records < 50 ms.

## 8. Acceptance Criteria (each maps to a test in §9)

- **AC1** (E1) 10 unbroken active days incl. today → `currentStreak == 10`, `frozenDays == []`, `isTodayPending == false`.
- **AC2** (E2) 20 active, 1 missed, today active → `currentStreak == 21`, `frozenDays.count == 1` (the missed day's `startOfDay`), `isTodayPending == false`.
- **AC3** (E3) 5 active, missed, missed, 10 active, today active → `currentStreak == 11` (older 5 severed by two-in-a-row), `frozenDays == []`.
- **AC3b** (E4) 2 active, missed, 3 active, today active → budget trim → `currentStreak == 4`, `frozenDays == []`.
- **AC4** History whose max suffix run was 30, then two missed days (reset), then 4 active incl. today → `longestStreak == 30`, `currentStreak == 4`.
- **AC5** Today has no session, yesterday-anchored run is 5 → `currentStreak == 5`, `isTodayPending == true`.
- **AC6** Pure-function param check: with `requirePerfectDay == true`, a day with only a morning session does **not** qualify; with both slots it does. (App passes `false`; this verifies the parameter path.)
- **AC7** Slot mapping: 11:59 → morning, 12:00 → evening (with boundary 12).
- **AC8** Reminders: morning session logged today → plan contains no `morningRoutine`; none logged → it is present at the adaptive/default time.
- **AC9** Any session today OR streak==0 → plan contains no `streakAtRisk`.
- **AC10** `eveningRoutine` and `streakAtRisk` within `MIN_GAP_MINUTES` → `eveningRoutine` dropped.
- **AC11** Adaptive: ≥`MIN_HISTORY` evening sessions clustered ~21:10 → `eveningRoutine.fireDate` ≈ 21:10 (±1 min); below `MIN_HISTORY` → default 20:30.
- **AC12** DST boundary day → no crash, slot/day math correct (explicit test).
- **AC13** App relaunch with `hasCompletedOnboarding == true` → `RootView` renders `ContentView` (logic-level test on the gating predicate).
- **AC14** Performance: 5000 records evaluate < 50 ms (measured test).

## 9. Test Plan

**Unit (XCTest in `ToothBuddyCoreTests`, run via `swift test`) — the TDD truth source.** One test per AC1–AC14, plus per edge case in §7. Tests inject a fixed `Calendar` (UTC + a DST zone) and explicit `now`; no reliance on system clock/timezone. Builder helper `record(day:Int, hour:Int)` for readable fixtures. Each forgiving-mechanic option gets its own precise numeric assertions (the chosen one is kept).

**Manual smoke checklist (in spec §11 of PLAN template / appended to PR):**
- Fresh install → onboarding shows once → relaunch → goes straight to app.
- Complete first session → permission prompt appears once → accept → background → reminder logic rescheduled (verify via pending requests in a debug print).
- Deny permission → app works, no crash, no nag.
- Change device timezone, relaunch → streak unchanged.

## 10. Docs to Update

- `README.md` — note streak forgiveness + reminders under Features.
- `ROADMAP.md` / `PLAN.md` — tick Priority 1 phases.
- `CHANGELOG.md` — create; add entry.
- This file — tick Status; record §12 answers.

## 11. Out of Scope

Cloud/push, multi-profile, editable reminder times, settings screen, re-viewable onboarding, any sensing, UI redesign beyond minimally surfacing streak/longest/frozen + "at risk".

## 12. OPEN QUESTIONS — must be answered & checked before implementation ⛔

- **[OPEN-1]** Slot boundary hour.
- **[OPEN-2]** Streak day = active vs perfect.
- **[OPEN-3]** Forgiving mechanic + constants.
- **[OPEN-4]** Reminder hours/gap, permission timing, editability.
- **[OPEN-5]** Onboarding once-only, no re-view entry point this iteration.

_Answers — confirmed by user 2026-05-18:_
- **OPEN-1 →** `SLOT_BOUNDARY_HOUR = 12` (noon; `<12` morning, `>=12` evening).
- **OPEN-2 →** Streak day = **active** (≥1 session). `requirePerfectDay = false`. "Perfect day" surfaced separately only.
- **OPEN-3 →** **Option A — rolling grace**, `GRACE_PERIOD = 7`. Do not implement B/C.
- **OPEN-4 →** Proposed scheme accepted: `morningRoutine` + `eveningRoutine` + `streakAtRisk` at 20:30; `MIN_GAP_MINUTES = 60`; defaults `DEFAULT_MORNING = 08:00`, `DEFAULT_EVENING = 20:30`; permission requested after first completed session; reminder times **not user-editable** this iteration.
- **OPEN-5 →** Yes — onboarding shows once only; no re-view entry point this iteration.
