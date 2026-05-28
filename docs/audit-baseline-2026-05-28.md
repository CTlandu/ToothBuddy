# Quality Audit Baseline — 2026-05-28

Plan: [`docs/plans/2026-05-28-001-refactor-quality-audit-plan.md`](plans/2026-05-28-001-refactor-quality-audit-plan.md) — Unit U8

Snapshot of measurable state **after** U1–U7 ship. Future optimizations compare against this anchor.

| Build / test | Value |
|--------------|-------|
| `xcodebuild build` warnings | **0** (with `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES` per U1) |
| `xcodebuild build` errors | 0 |
| `xcodebuild test` (App) | **42/42 ✓** (up from 18/18 pre-audit) |
| `swift test` (Core) | **108/108 ✓** (unchanged across audit) |
| Total Swift LOC (app + Shared + Widget, ex. tests / Core / .build) | 9,160 |

---

## 1. Bundle size

**Source of truth:** Xcode Organizer → archive → "All compatible device variants" → `App Thinning Size Report.txt`. The numbers below are pending an archive build (requires signing); the script below produces them.

```bash
# Run on demand (requires DEVELOPMENT_TEAM in project.yml, which is already set):
xcodebuild -project ToothBuddy.xcodeproj -scheme ToothBuddy \
  -destination 'generic/platform=iOS' \
  archive -archivePath /tmp/ToothBuddy.xcarchive
# Then Distribute → Ad Hoc / Development → "All compatible device variants"
# → review the exported `App Thinning Size Report.txt`.
```

Compressed-source bundle assets (read directly from the working tree):

| File | Size | Notes |
|------|------|-------|
| `Nunito-Regular.ttf` | 132K | 126 call sites (heavy) |
| `Nunito-SemiBold.ttf` | 132K | 26 call sites (moderate) |
| `Nunito-Bold.ttf` | 132K | **0 view call sites** — defined in `NunitoFont.bold` / `Duo.Fnt.bld` but no view invokes either. **132K removable** if helpers are also removed. |
| `Nunito-ExtraBold.ttf` | 132K | 71 call sites (heavy — the Duolingo brand wordmark) |
| `Assets.xcassets/` | 4K | Only `AccentColor.colorset` + `AppIcon.appiconset` (empty); the legacy `tooth.imageset` was deleted in U6. |

Total Nunito payload: **528 KB**. Conservative-cut candidate: **396 KB** (remove `Nunito-Bold.ttf` + helpers).

App-icon: `ASSETCATALOG_COMPILER_APPICON_NAME: ""` (intentionally empty until a real icon is designed — see `project.yml`).

---

## 2. Font usage (call-site count, dedup'd against helper definitions)

Counted via:

```bash
grep -rn 'Nunito-<WEIGHT>\|NunitoFont.<weight>\|Duo.Fnt.<abbrev>' \
  --include="*.swift" . | grep -v Tests/ | grep -v .build | wc -l
```

| Weight | Raw count | Defs (subtract) | Actual call sites |
|--------|-----------|-----------------|-------------------|
| Regular   | 126 | 3 | **123** |
| SemiBold  | 26  | 3 | **23** |
| Bold      | 3   | 3 | **0 ⚠️** |
| ExtraBold | 71  | 3 | **68** |

**Finding:** `Nunito-Bold` is registered + has a helper but no view ever calls `.bold(_:)`. Two paths forward (deferred decision — not done in U8):

1. **Remove** `Nunito-Bold.ttf` + the `NunitoFont.bold` / `Duo.Fnt.bld` helpers → save 132 KB compressed download, ~132 KB install
2. **Adopt** `.bold(_:)` somewhere the design intends a non-extra-bold heading. Currently the SwiftUI codebase reaches straight from `.semiBold(_:)` to `.extraBold(_:)`, skipping `.bold(_:)`.

`Nunito-Regular` heaviness (123 sites) comes mostly from the `NunitoFont.body = .custom("Nunito-Regular", size: 16)` constant injected via `.environment(\.font, NunitoFont.body)` in `MyApp.swift`.

---

## 3. Cold launch / startup

**Method:** Instruments → App Launch template → record one cold launch on a real iPhone (sim numbers are biased — Apple's documented stance is "sim is for behavior, device is for perf").

**Status:** Instruments capture is maintainer device-side work (cannot be done from CI / from this audit pass). To run:

```bash
# In Xcode:
# Product → Profile → App Launch → record
# Stop after first frame is visible
# Save as docs/audit-baseline-trace-2026-05-28-app-launch.trace (next to this file)
```

**Instrumentation in place** (U2): `OSSignposter` intervals named so they surface in the Points of Interest lane:

| Signpost name | Where | Plan |
|---------------|-------|------|
| `ColdLaunch.registerFonts` | `MyApp.registerNunito()` | Measure 4-font registration cost |
| `BrushingSession` | `BrushView.start/stopBrushing` | Full 2-min session interval |
| `Camera.configure` | `CameraService.configureIfNeeded()` | One-time camera setup |
| `Vision.frame` | `VisionFrameProcessor.captureOutput` (12 fps throttle) | Per-frame Vision pipeline |

Expected ranges (industry baselines from research; verify against measurements):

- Cold launch process-start → first-frame: **<400 ms** is the modern bar for mid-tier devices.
- `registerNunito` (4× CGFont registration): typically **5–20 ms**.
- `Camera.configure`: typically **100–300 ms** (depends on `AVCaptureSession` config negotiation).
- `Vision.frame`: must stay **<83 ms** to hold 12 fps; <33 ms to hold 30 fps if we ever bump.

---

## 4. Production telemetry (MetricKit)

`MetricsSubscriber` is wired (U3) and subscribes at `MyApp.init`. **Payloads only deliver to TestFlight / App Store builds, not Debug.** First payload arrives ~24 h after first install.

Fields logged (`Logger` subsystem `com.ctlandu.ToothBuddy`, category `metrics`):

- `MXAppLaunchMetric.histogrammedTimeToFirstDraw` — the cold-launch headline
- `MXAppLaunchMetric.histogrammedOptimizedTimeToFirstDraw` — post-prewarm cold launch
- `MXAppLaunchMetric.histogrammedApplicationResumeTime` — warm resume
- `MXAppResponsivenessMetric.histogrammedApplicationHangTime` — frame-budget misses
- `MXCPUMetric.cumulativeCPUTime` — battery proxy
- `MXCrashDiagnostic` / `MXHangDiagnostic` / `MXCPUExceptionDiagnostic` — diagnostics

**View in Console.app:** filter on `subsystem:com.ctlandu.ToothBuddy category:metrics`.

---

## 5. Periphery (dead code)

Config at [`.periphery.yml`](../.periphery.yml). Run via [`scripts/audit.sh`](../scripts/audit.sh) or `periphery scan` directly.

**Status:** Periphery not yet installed on the dev machine (per U7's friendly-skip in `audit.sh`). To install + run:

```bash
brew install peripheryapp/periphery/periphery
bash scripts/audit.sh   # last step runs Periphery
```

Baseline once run: copy first-run output here for future diff.

---

## 6. Concurrency surface

`SWIFT_VERSION=6.0` on app + widget + tests. `swiftLanguageModes: [.v6]` on Core. `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES` on all three targets (U1).

**Escape hatches in app code (5 total)** — each carries an `AUDIT 2026-05-28 (Plan U1)` comment explaining why it's still the right choice:

| File | Escape | Reason (summarized) |
|------|--------|---------------------|
| `CameraService.swift` | `@preconcurrency import AVFoundation` | AVFoundation hasn't completed its Sendable audit |
| `CameraService.swift` | `@unchecked Sendable` on the class | Queue-confined state; actor would force every SwiftUI caller async |
| `Persistence.swift` | `nonisolated(unsafe)` on `ToothBuddyModel.shared` | SE-0412 sanctioned; built once, then read-only |
| `Persistence.swift` | `nonisolated(unsafe)` on `PersistenceController.shared` | Same; needed for synchronous singleton pattern |
| `BrushingZoneMonitor.swift` | `@preconcurrency import AVFoundation` | Same as CameraService import rationale |
| `Support/MetricsSubscriber.swift` | `@unchecked Sendable` (added U3) | NSObject + Logger state; `App.init` can't be async |

Core package: **0 escape hatches.**

---

## 7. Test coverage (post-audit)

| Suite | Count | Coverage areas |
|-------|-------|----------------|
| Core (`swift test`) | 108 | Every Core module has a *Tests.swift companion. |
| App (`xcodebuild test`) | 42 | Persistence, BrushingStore, GamificationStore, CareStore, ContentHistoryStore, GroupStore, ReportPDFRenderer, HealthExporter (decider), NotificationScheduler (contract), WidgetBridge (round-trip + placeholder), BrushGameOverlay (caps via Core), App-smoke. |

**Documented coverage gaps** (intentional, see `references/plan-sections.md`-style note in each test file):

- `VoiceCoach` / `SoundManager` — trivial AV wrappers, no business logic.
- `CameraService` / `VisionFrameProcessor` / `BrushingZoneMonitor` — covered by spec 04.2 / 04.3 §12 device smoke; unit tests would require restructuring around mocks.
- `BrushGameOverlayCapsTests` only covers Core-level bug-count bound; the `maxConfetti = 60` constant lives inside a `fileprivate` view model and is documented gap.

`test_regression_<bug>` tests pinning prior fixes:

- `test_regression_sharedSingletonCanBeAccessedAtLaunchWithoutTrap` (P5.3 reentrant `BrushingStore.shared` fix)
- `test_regression_doubleExportDecisionWritesAtMostOnce` (P5.4 HealthKit idempotency)
- `test_regression_brushGameTotalBugsBoundedByConfig` / `test_regression_brushGamePerZoneBugCountIsExact` / `test_regression_brushGameClearsToZeroAndZapTotalMatches` (P4.3 Sugar Bugs caps lower-bound invariants)
- `testQuickLogIsIdempotentWithinSlot` (P5.2 Siri quick-log idempotency, pre-existing in `PersistenceTests`)

---

## What to do next (deferred — not part of U8)

| Item | Owner | Cost | Value |
|------|-------|------|-------|
| Drop `Nunito-Bold.ttf` + helpers | maintainer | 5 min | 132 KB |
| Capture cold-launch trace + Camera.configure trace | maintainer (device) | 15 min | Real baseline numbers |
| Install Periphery + run + record baseline | maintainer | 10 min | Continuous dead-code monitor |
| Watch first MetricKit payload after TestFlight | maintainer | passive | Production telemetry truth |
| Migrate `Theme.*` → `Duo.*` in BrushView/ContentView/BrushGameOverlay | maintainer | 1 hr + visual smoke | Single-namespace cleanup |
