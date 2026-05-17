# Changelog

All notable changes to ToothBuddy. Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added — Priority 1: Habit & Behavior Engine (spec 01)

- **Forgiving streak** (rolling grace, ≈1 forgiven day per 7-day run; two consecutive
  missed days still reset). Bridged days are reported as "frozen" for the UI.
- **Longest-streak** tracking (never decreases).
- **Morning/evening session slots** (noon boundary) and `isTodayPending` (streak-at-risk) state.
- **Adaptive local reminders**: morning + evening at the user's median brushing time
  (defaults 08:00 / 20:30 before enough history), plus a 20:30 "streak at risk" nudge,
  with a 60-minute collision rule. Permission requested after the first completed session.
- **`ToothBuddyCore`** local Swift package holding all pure logic
  (`BrushingRecord`, `SessionSlot`, `StreakEngine`, `ReminderPlanner`), covered by
  28 XCTest cases mapped 1:1 to the spec acceptance criteria (`swift test`).

### Changed

- Onboarding now shows **once** (persisted), not on every launch (removed an SSC leftover).
- `BrushingStore` streak is now derived by `StreakEngine` (old strict-streak loop removed;
  `consecutiveDaysCount` kept as a shim).
- Project is now **Xcode 26 / CLI-driven**; `Package.swift` is hand-maintained and depends
  on the local `ToothBuddyCore` package. iPad/Mac Swift Playgrounds.app is no longer supported.

### Verification

- `cd ToothBuddyCore && swift test` → 28/28 green.
- Full app `xcodebuild` → BUILD SUCCEEDED (iOS 18.6 simulator).
- Manual smoke checklist (spec 01 §9) to be run by the maintainer.
