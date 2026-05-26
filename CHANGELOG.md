# Changelog

All notable changes to ToothBuddy. Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added — P5.4: HealthKit `toothbrushingEvent` export (spec 05) — P5 complete

- **`ToothBuddyCore`**: pure `HealthExportDecider.shouldExport` — write iff completed and
  not already exported (idempotent; re-completion/relaunch never double-writes).
  `swift test` 108/108.
- **App**: `HealthExporter` — write-only, opt-in, revocable, idempotent. Requests
  **share-only** authorization for the single `.toothbrushingEvent` type (never any read
  type, never reads Health), writes one `HKCategorySample` per completed session with
  `HKMetadataKeyExternalUUID` = session id, and tracks a per-device exported-id set
  (second safety net beyond the external UUID). HealthKit entitlement +
  `NSHealthUpdateUsageDescription` added; all use `canImport(HealthKit)`-gated and a
  no-op unless available & authorized — local records stay the source of truth, revoking
  silently disables with no error spam or data loss. Hooked into both completion paths
  (in-app finish + Siri quick-log), shared-instance only. Adult History gains a
  contextual "Save brushing to Apple Health" opt-in row (never on cold launch).
- Verified: build clean (0 new-file warnings), app `xcodebuild test` 18/18, Core
  `swift test` 108/108. The Health permission grant + Health-app verification is
  maintainer device smoke (spec 05 §12) — automatic signing provisions the HealthKit
  entitlement with no manual portal step (unlike P2.5b).
- **Priority 5 (Adult Mode + Apple Integrations) complete.**

### Added — P5.3: Home-screen widget + Live Activity (spec 05)

- **`ToothBuddyCore`**: pure `WidgetSnapshot` + `WidgetSnapshotBuilder` — Codable
  profile-isolated summary (streak via `StreakEngine`, today AM/PM, late-evening
  `atRisk`), deterministic, with a friendly `.placeholder`. `swift test` 105/105.
- **App + new `ToothBuddyWidget` app-extension target** (XcodeGen) sharing logic via
  `ToothBuddyCore` and data via the App Group `group.com.ctlandu.ToothBuddy`
  (entitlements on both targets; `NSSupportsLiveActivities`): a small/medium Home Screen
  widget (streak + today's slots + at-risk; never blank — placeholder until first write)
  reading only the App Group snapshot; an ActivityKit Live Activity (Lock Screen +
  Dynamic Island, 2-min countdown + zone hint) started/updated/ended from BrushView,
  with stale-dismiss on launch so a killed session never leaves a stuck activity. All
  ActivityKit use is `iOS 16.1`-gated and additive (brushing unchanged if unsupported).
  `WidgetBridge` pushes the snapshot + reloads timelines on session log / profile switch
  / scene-background.
- Fixed a launch crash: `BrushingStore.reload()` referenced `BrushingStore.shared` while
  that singleton was still initializing (reentrant static init trap). Now a post-init
  `widgetSyncEnabled` instance flag gates the widget refresh — shared instance only,
  unit-test stores stay isolated.
- Verified: build clean (0 new-file warnings), app `xcodebuild test` 18/18 (with the
  extension embedded + App Group entitlements), Core `swift test` 105/105. Widget gallery
  / Lock Screen / Dynamic Island visuals are maintainer device smoke (spec 05 §12) —
  automatic signing provisions the App Group with no manual portal step (unlike P2.5b).

### Added — P5.2: App Intents / Siri Shortcuts (spec 05)

- **`ToothBuddyCore`**: pure `QuickLog.isCurrentSlotLogged` + `QuickLogDecision` — the
  per-slot idempotency rule (project boundary 12), profile-isolated & deterministic.
  `swift test` 100/100.
- **App**: `BrushingStore.quickLogForCurrentSlot` (logs a ~2-min session for the active
  profile, idempotent within the AM/PM slot — does not touch the in-app flow);
  `BrushingIntentBridge` (StartBrushingIntent → Brush tab + auto-start, crash-safe,
  consumed once); `ToothBuddyIntents` — `LogBrushingIntent` (background),
  `StartBrushingIntent` (opens app), `BrushingStreakIntent` (read-only), all active-
  profile-only and graceful with no profile, plus `ToothBuddyShortcuts`
  (`AppShortcutsProvider`) exposing Siri phrases. No entitlement, no extension (in-process,
  iOS 16+).
- Verified: build clean, app `xcodebuild test` 18/18 (adds AC7 idempotency +
  no-profile), Core `swift test` 100/100. On-device Siri/Shortcuts trigger is part of the
  maintainer smoke (spec 05 §12).

### Added — P5.1: Adult minimal mode (spec 05)

- **`ToothBuddyCore`**: `ProfileMode` (`kid` default | `adult`) on `Profile` with a custom
  `init(from:)` so profiles persisted before P5 (no `mode` key) decode as `kid` —
  additive, zero-loss, CloudKit-compatible (same rule as the P2.1 schema). Pure
  `HabitCurve.points` — per-day `completed01` (0/0.5/1.0) + a clamped trailing-mean
  `adherence`, profile-isolated & deterministic. `swift test` 95/95 (all prior tests
  still green — additive only, AC8).
- **App**: `CDProfile.mode` (optional String, default `"kid"`) in the programmatic model;
  `ProfileStore.createProfile(mode:)` + `setMode(_:for:)` (per-profile — a sibling on the
  same device is unaffected). For an `adult` profile: BrushView shows **no** Sugar Bugs
  overlay, the Done sheet drops stars/confetti for a calm "Brushing logged" summary with
  a quiet "Morning ✓ · Evening ✓" line, content tone defaults to `essentials` (an
  explicit P3 user tone still wins), and History hides level/achievements and shows a
  calm `HabitCurveView` instead. Profile create gains a Kid/Adult picker; each picker row
  gets a quick mode menu. A `kid` profile is byte-for-byte the existing experience.
- Verified: build clean, app `xcodebuild test` 16/16, Core `swift test` 95/95. On-device
  visual switch is part of the maintainer smoke (spec 05 §12).

### Added — P4.3: "Sugar Bugs" brushing game (spec 04.3) — P4 complete

- **`ToothBuddyCore`**: `BrushGame`/`BrushGameConfig` — pure rules (seed bugs/zone, clear
  by active brushing time with a fractional accumulator, score, zones-cleared, stars).
  `swift test` 87/87.
- **App**: `BrushGameOverlay` — `Canvas` + `TimelineView` jelly Sugar Bugs that squash &
  burst into toothpaste bubbles with `+10` floaters, pulsing zone ring, slim HUD, and an
  in-session "All sparkly clean!" win celebration; Reduce-Motion aware; hard caps (≤8
  bugs, ≤60 confetti); sim/draw separated; throttled sound. Additive
  `BrushingZoneMonitor.isBrushingActive` (existing API/`currentZone` untouched). BrushView
  shows it only for the `playful` tone (essentials = unchanged screen); also plays in the
  no-camera timed fallback.
- §6.4 refinement (documented): in-session win celebration only — no separate end card;
  the existing, unchanged Done sheet keeps the star rating. Lower bug surface, same goals.
- Verified: build clean (0 warnings in new files), app `xcodebuild test` 14/14, Core
  `swift test` 87/87. **On-device look/feel is smoke-tested by the maintainer** (spec
  04.3 §12) — visuals cannot be unit/sim-tested.

### Added — P4.2: Vision camera adapter (spec 04.2)

- **App**: `CameraService` — the single shared `AVCaptureSession` feeding both the selfie
  preview and Vision (one camera claim, eliminates the dual-session black-screen bug);
  `VisionFrameProcessor` (nonisolated data-output delegate, ≤12 fps, face-landmarks mouth
  centroid + hand pose + EMA motion → Sendable `ZoneSample`, isolated DEVICE-TUNE
  mirror/flip knobs); `BrushingZoneMonitor` rewritten to drive the unit-tested Core
  engine with a debounced `currentZone` (≤1 change/sec → no voice/UI thrash) and a
  graceful timed-sequence fallback (no permission / no face / interruption). Public API
  byte-compatible → **BrushView unchanged**. `CameraPreviewView` now shares the one
  session. Camera released on screen teardown (battery/privacy).
- Verified: build clean (0 warnings in new files), app `xcodebuild test` 14/14, Core
  `swift test` 80/80. **On-device behavior is smoke-tested by the maintainer** (spec
  04.2 §12 checklist) — it cannot be unit/simulator-tested.

### Added — P4.1: Camera-guidance Core engine (spec 04)

- **`ToothBuddyCore`**: `CoarseZone` + signal DTOs (`FaceSignal`/`HandSignal`/
  `ZoneSample`) + `BrushingZoneEstimator` (signals → coarse zone + isActivelyBrushing),
  `ZoneCoverageTracker`, `GuidanceDecider` (camera steer-to-least-covered + debounce;
  deterministic fallback-timed cadence). Pure, no Vision import. `swift test` 80/80
  (AC1–AC7). Engagement-grade only — never clinical (positioning lock).
- P4.2 (Vision adapter + wiring) and P4.3 (2D game) follow; smile-album deferred.

### Added — P3.4: Seasonal content (spec 03) — P3 complete

- **`ToothBuddyCore`**: spring/summer/autumn `ContentItem`s added so every season (plus
  winter & halloween) has flavor; `ContentSelector` already prefers them with neutral
  fallback. Core seasonal-coverage + fallback tests; `swift test` 73/73.
- Visual seasonal accent intentionally left out of scope (pure cosmetic, no logic).
- **Priority 3 (Content Engine) complete.** Music-sync and LLM generation remain
  deferred to their own later specs.

### Added — P3.3: Gamified oral-health course (spec 03)

- **`ToothBuddyCore`**: `Lesson` + bundled ordered `CourseLibrary` (8 original lessons)
  + `CourseProgression.unlockedCount` (1 unlocked, +1 every 2 active days, capped).
  `swift test` 72/72.
- **App**: TipsView gains a course section — lessons lock/unlock by the active profile's
  distinct active-day count, with a lesson detail sheet (UI smoke).

### Added — P3.2: 2-minute spoken-content session (spec 03)

- **`ToothBuddyCore`**: `ScriptCue`/`SessionScript.build` — deterministic 2-min timeline
  (intro, 4 quadrants, content cue when present, encourage, wrap; tone-aware; clamped).
  `swift test` 69/69.
- **App**: `ContentHistoryStore` (per-device no-repeat ring + tone setting); BrushView
  builds a per-session script (kind rotates by day, content via `ContentSelector`) and
  speaks **content + encouragement** cues mid-session via `VoiceCoach` — quadrant guidance
  stays with `zoneMonitor` to avoid overlap. App `xcodebuild test` 14/14 (adds AC5 + ring).

### Added — P3.1: Offline content selection engine (spec 03)

- **`ToothBuddyCore`**: `ContentItem` + bundled original `ContentLibrary` (facts/jokes/
  tips/story beats, some seasonal; no licensed IP) + `ContentSelector` — tone gating
  (playful/essentials), seasonal preference with neutral fallback, no-repeat-then-reset,
  fully deterministic by day-seed. `swift test` 64/64. Offline, no account, asset-light.
- Music-sync (Apple Music/MusicKit) and LLM generation deferred to their own later specs.

### Added — P2.5a: Pure sync merge resolver (spec 02 §6.8 / AC12)

- **`ToothBuddyCore`**: `SyncMergeable` protocol + `SyncMergeResolver.merge` —
  last-writer-wins by `modifiedAt`, tombstone beats stale/tie, union of ids (no loss),
  deterministic stable ordering. `swift test` 58/58. No iCloud dependency.
- P2.5b (CloudKit container/CKShare wiring) is blocked on the maintainer's interactive
  Apple-Developer setup (see `specs/02-family-layer.md` §5/§6.8).

### Added — P2.4: Per-profile dentist PDF report (spec 02)

- **`ToothBuddyCore`**: `ReportBuilder`/`ReportData`/`DayCell` — range-bounded, profile-
  isolated, deterministic: in-range sessions, active/total days, completion %, current/
  longest streak (via `StreakEngine`), per-day active/perfect grid; reversed ranges
  tolerated. `swift test` 53/53.
- **App**: `ReportPDFRenderer` (UIGraphicsPDFRenderer — header, totals, calendar grid) +
  temp-file share via `ShareSheet`; Group dashboard "Report" menu (last 30/90/365 days).
  App `xcodebuild test` 12/12 (adds AC11 + PDF smoke).
- AC14 perf test made non-flaky (generous regression-catching ceiling; spec note updated).

### Added — P2.3: Per-profile brush-head & dentist reminders (spec 02)

- **`ToothBuddyCore`**: `CareKind` (brushHead 90d / dentist 180d defaults),
  `CareDueCalculator` (anchor + interval; no baseline → not due, never nags),
  `CareReminderPlanner` (future due dates only — overdue is shown, not re-nagged).
  `swift test` 50/50.
- **App**: `CareStore` (per-profile `CDProfileCare`, "Mark done" resets the anchor),
  `NotificationScheduler.rescheduleCare` (authorized-only, unique ids per profile+kind),
  Group dashboard care chips with due/overdue state + Set/Done buttons; rescheduled on
  scene-active and after marking. App `xcodebuild test` 11/11 (adds AC10).

### Added — P2.2: Peer Group + everyone-sees-everyone dashboard (spec 02, local-modeled)

- **`ToothBuddyCore`**: `DashboardMetrics` / `DashboardMetric` — today AM/PM, current &
  longest streak (reuses `StreakEngine`), last-7-days active, 4-week trend, missed-yesterday;
  pure & profile-isolated. `swift test` 44/44.
- **App**: `CDGroup` entity + `CDProfile.group` relationship added to the programmatic
  model (additive, CloudKit-compatible); `GroupStore` (create group attaching profiles,
  leave keeps profile local, disband); `GroupDashboardView` listing every profile with
  metrics — no roles, no gating; new **Family** tab.
- App `xcodebuild test` 8/8 (adds AC7 create-attaches, AC9 leave-keeps-local, disband).
- CloudKit go-live for the Group is still P2.5.

### Added — P2.1: Multiple profiles + per-profile data + zero-loss migration (spec 02)

- **`ToothBuddyCore`**: `Profile` (+ `ProfileColor`/`ProfileSymbol`), non-optional
  `BrushingRecord.profileID`, `LegacyBrushingRecord`, `MigrationTransform`,
  `ProfileScopedAggregator`. `swift test` 39/39.
- **App**: programmatic `NSManagedObjectModel` + `NSPersistentCloudKitContainer`
  (local-only now; CloudKit-compatible schema so P2.5 needs no migration). `ProfileStore`
  (CRUD + device-local active profile). `BrushingStore`/`GamificationStore` reworked to be
  per-profile. Zero-loss JSON→Core Data migration runner (idempotent; legacy JSON kept as
  a one-release backup). Profile picker + first-run gate; header profile switcher.
- App `xcodebuild test` (`ToothBuddyTests`): Core Data CRUD, per-profile isolation,
  delete-cascade — 5/5. App BUILD SUCCEEDED.
- Peer-Group sharing (P2.2–P2.5) not yet started.

### Changed — Project format: `.swiftpm` → Xcode `.xcodeproj`

- Migrated off Swift Playground to a normal Xcode project, generated by **XcodeGen**
  from a committed `project.yml` (the `.xcodeproj` itself is git-ignored — run
  `xcodegen generate` after cloning). Required because App Playgrounds cannot carry
  the iCloud/CloudKit (and HealthKit/App Intents) entitlements that P2/P5 need.
- Removed the root app `Package.swift`; added `Support/Info.plist`, an app
  `ToothBuddyTests` target, and an `xcodegen generate` bootstrap step (README).
- `ToothBuddyCore` package and its 28-test `swift test` suite are unchanged.
- Verified: app BUILD SUCCEEDED, app TEST SUCCEEDED, Core `swift test` 28/28.

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
