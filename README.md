# ToothBuddy

An iPhone app that helps one person **brush better** — cover every area, brush long enough — and turns it into a **verifiable oral-health record** they can show a dentist.

---

## Overview

ToothBuddy isn't a habit-tracker; most people already brush twice a day. The point is **the quality of each brush**: a guided, zone-by-zone session that makes sure every area gets enough time, logged into a record that's honest enough to be evidence.

- **Guided route, audio-first.** The app talks you through a structured 6-zone routine — "now upper-left… switch to upper-right" — so you can brush eyes-free with the phone set down. A "smart mirror" mode (front camera + zone highlight + progress + Sugar Bugs game) is there for people who prop the phone.
- **Honest quality.** A phone camera can't judge clinical cleaning, so we don't pretend to. We measure **coverage** (did each area get its time), **duration** (did you hit the 2-minute target), and mark each record **camera-verified** vs **guided-only** — the un-fakeable flag for a dentist.
- **Single user.** One device = one person. No multi-profile family layer. Sharing (dentist / family / friends) over the network is Phase 2.
- **Apple ecosystem.** Live Activity + Dynamic Island show per-zone progress; the Home-Screen widget shows today's brushing quality; Siri reports your week; HealthKit gets your thorough brushes.
- **Offline, no account, no tracking.**

**Platform:** iOS 17.0+ (iPhone & iPad), SwiftUI, Swift 6.0.
**Status:** Phase-1 quality-pivot rebuild on branch `feat/quality-pivot-rebuild`. Phase 2 (networked identity + sharing) is planned.

Current product definition: [`docs/product-north-star.md`](docs/product-north-star.md).
Rebuild plan: [`docs/plans/2026-05-29-001-feat-quality-pivot-rebuild-plan.md`](docs/plans/2026-05-29-001-feat-quality-pivot-rebuild-plan.md).

---

## Features

### Quality brushing session
- Prescribed-route engine (`GuidedSessionEngine`, pure logic): walks all 6 coarse zones, each with a per-zone time target; the session auto-completes when every area is covered for long enough.
- **Audio-first** eyes-free coaching by default; optional **smart-mirror** visual mode (camera + zone highlight + progress + Sugar Bugs game). Settings switch between them; audio mode never opens the camera.
- Configurable target (2 or 3 minutes).
- End-of-session summary: which areas were covered, whether the target was met, and a **camera-verified vs guided-only** badge.

### Verifiable record + dentist proof
- Each `BrushingRecord` stores per-zone coverage, active time, target, met-minimum, camera-verified flag, and guidance mode.
- Shareable PDF "dentist report" (90-day default) with thorough-session count, camera-verified count, average active time, and a coverage calendar — clearly distinguishing verified from guided sessions.

### Settings (no kid/adult split)
- Every feature defaults on; the user turns off what they don't want: brushing game, celebrations/stars, content tone, levels & achievements, habit curve, voice guidance, session mode, target length, Apple Health.

### Retention (demoted streak)
- Forgiving streak (`StreakEngine`) is kept as a light consistency badge, no longer the hero metric.
- Adaptive local notifications that learn your typical brushing times + a gentle "brush before bed" nudge. No account, no network.

### Rewards bound to quality
- Achievements and levels track **thorough** (target-met) and **camera-verified** sessions, not raw counts.

### Content engine
- 2-minute TTS coaching with a no-repeat, seasonal-aware content selector (facts / jokes / tips).

### Apple integrations
- Home-Screen widget: today's brushing quality (thorough count + last coverage + verified), streak demoted to a small badge.
- Live Activity / Dynamic Island: countdown + per-zone progress during a session.
- App Intents / Siri: "Log brushing", "Start brushing", and a weekly quality summary.
- HealthKit `toothbrushingEvent` write-only export — share-only, idempotent, revocable; only thorough sessions are written.

---

## Tech Stack

- **UI:** SwiftUI
- **Persistence:** Core Data (programmatic `NSPersistentCloudKitContainer`, local-only until Phase 2)
- **Pure logic:** Local Swift package [`ToothBuddyCore/`](ToothBuddyCore/) — platform-agnostic, XCTest-covered (`GuidedSessionEngine`, `StreakEngine`, `ZoneGuidance`, `ReportBuilder`, `WidgetSnapshot`, …)
- **Targets (per [`project.yml`](project.yml)):** `ToothBuddy` (app), `ToothBuddyWidget` (widget + Live Activity), `ToothBuddyTests`
- **System integrations:** AVFoundation, Vision, AppIntents, ActivityKit, WidgetKit, HealthKit (write-only), UserNotifications, App Group `group.com.ctlandu.ToothBuddy`
- **Minimum:** iOS 17.0
- **Build:** Xcode + [XcodeGen](https://github.com/yonsson/XcodeGen)

---

## How to Run

`ToothBuddy.xcodeproj` is generated from [`project.yml`](project.yml) and is **git-ignored**:

```sh
brew install xcodegen   # one-time
xcodegen generate
open ToothBuddy.xcodeproj
```

### Tests

```sh
# Pure logic (fast, no simulator)
swift test --package-path ToothBuddyCore

# Everything (one-shot: xcodegen + Core tests + app build/test + dead-code scan)
bash scripts/audit.sh
```

The app target builds with `SWIFT_TREAT_WARNINGS_AS_ERRORS` — the baseline is 0 warnings.

---

## Project Layout

| Path | What |
|------|------|
| [`docs/product-north-star.md`](docs/product-north-star.md) | Current product definition (authoritative) |
| [`docs/plans/`](docs/plans/) | Implementation plans (latest = quality-pivot rebuild) |
| [`ToothBuddyCore/`](ToothBuddyCore/) | Local Swift package — pure logic + XCTest suite |
| `MyApp.swift`, `ContentView.swift` | App entry + tab container (Brush / History / Tips) |
| `OnboardingView.swift` | First-run flow (auto-creates the single owner profile) |
| `BrushView.swift` | Guided session: audio-first + smart-mirror, done summary |
| `BrushGameOverlay.swift` | Sugar Bugs mini-game (mirror mode, toggleable) |
| `CameraService.swift`, `VisionFrameProcessor.swift`, `BrushingZoneMonitor.swift` | Camera pipeline + zone coverage/verification (drives `GuidedSessionEngine`) |
| `PreferencesStore.swift`, `SettingsView.swift` | Per-feature settings (replaces the kid/adult split) |
| `Persistence.swift`, `BrushingStore.swift`, `ProfileStore.swift`, `GamificationStore.swift` | Core Data + single-owner records + quality rewards |
| `CareStore.swift`, `NotificationScheduler.swift` | Brush-head / dentist reminders + adaptive notifications |
| `ContentHistoryStore.swift`, `HabitCurveView.swift`, `TipsView.swift` | Content engine + habit curve + course |
| `ReportPDFRenderer.swift`, `HistoryView.swift` | Dentist-proof PDF + history/quality screen |
| `ToothBuddyIntents.swift`, `BrushingLiveActivity.swift`, `WidgetBridge.swift`, `Shared/`, `Widget/` | Siri + Live Activity + Home-Screen widget |
| `HealthExporter.swift` | Write-only `toothbrushingEvent` export |
| `Theme.swift`, `DuoTheme.swift`, `SoundManager.swift`, `VoiceCoach.swift` | Design system + audio / TTS |

---

## License & Third-Party Code

All app code in this repository is original. Open-source dependencies are declared in `ToothBuddyCore/Package.swift` and `project.yml`.
