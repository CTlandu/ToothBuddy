# Spec 04 — Camera Guidance Upgrade

> **Reading order for any AI session:** `ROADMAP.md` → `PLAN.md` → this file.
> Implementation is **blocked until the Confirm gate (§1) is checked**.
> **[OPEN-n]** = unresolved; detailed sections assume the **PROPOSED** answers.
> **Non-negotiable (already locked by the `product-scope-software-only` decision):** the
> camera is **engagement / guidance-grade only**. We NEVER detect, claim, or build toward
> per-tooth coverage, 18-region accuracy, brushing pressure, gum-line angle, or plaque
> removal. This is a Pokémon-Smile-style *guide*, not a measurement device.

## 1. Status
- [x] 1. Spec drafted
- [x] 2. Confirm gate — user approved 2026-05-18 (all PROPOSED) ✅
- [ ] 3. Test infra delta (none — pure logic in existing ToothBuddyCore)
- [ ] 4. Implement (TDD, staged P4.1 → P4.3)
- [ ] 5. Verify
- [ ] 6. Docs
- [ ] 7. Commit

## 2. Problem & Goal
`BrushingZoneMonitor` is an explicit **mock**: it cycles the 6 `BrushingZone`s on a blind
15-second timer with no idea where the user is actually brushing. The front camera
(`CameraPreviewView`) is a passive mirror. **Goal:** use on-device Vision (face + hand
landmarks) to infer, at engagement-grade, *roughly which coarse zone* the user is brushing
and *whether they're actively brushing*, to drive coverage-aware spoken guidance — while
remaining fully functional with no camera/permission (the timed sequence becomes a
graceful fallback, never a hard dependency). No Apple-Developer account needed (Vision is
on-device, free); camera permission is already configured.

## 3. User Stories
- As a **kid**, the app reacts to where I'm actually brushing ("great, now the other
  side!") instead of a robotic timer.
- As a **user who denies the camera**, the app still guides me with the timed sequence —
  nothing breaks.
- As a **user**, I'm never told my brushing is "98% clean" or graded per tooth — only
  encouraged and guided.

## 4. Scope & Staging (all under P4; ordered, each verified & committed)
- **P4.1 — Core engine (pure, TDD).** Abstract observation DTOs + `BrushingZoneEstimator`
  (signals → coarse zone + isActivelyBrushing), `ZoneCoverageTracker` (dwell per zone →
  coverage / least-covered), `GuidanceDecider` (target order + coverage + elapsed → next
  prompt/announcement), and the **fallback timed sequence** generator (the old mock's
  behavior, now pure + tested).
- **P4.2 — App Vision adapter + wiring.** A `VisionZoneMonitor: BrushingZoneMonitoring`
  using `AVCaptureVideoDataOutput` + `VNDetectFaceLandmarksRequest` +
  `VNDetectHumanHandPoseRequest`, mapping Vision output → Core DTOs → engine → published
  `currentZone`. Graceful fallback to the Core timed sequence when no permission / no face
  for a grace period. BrushView keeps using the existing `BrushingZoneMonitoring` protocol
  (minimal app change). Smoke-tested (camera/Vision not unit-testable).
- **P4.3 — Lightweight engagement game (stretch, [OPEN-4]).** A simple 2D SwiftUI/SpriteKit
  overlay ("scrub the bugs in the highlighted zone") reacting to the coarse-zone + motion
  signal — NOT heavy ARKit/RealityKit. Game state/scoring is pure/tested; rendering smoke.

**Deferred to its own later spec ([OPEN-1]):** smile-progress selfie album (privacy +
local-storage design, not core to guidance).

## 5. PROPOSED Architecture
- **Vision, not ARKit face tracking ([OPEN-2]).** `VNDetectFaceLandmarksRequest` +
  `VNDetectHumanHandPoseRequest` run on the front `AVCaptureVideoDataOutput`. Works on all
  supported devices (no TrueDepth requirement), 2D, sufficient for engagement-grade coarse
  zones. ARKit `ARFaceAnchor` is richer but TrueDepth-gated — rejected for device breadth.
- **Testability (same discipline as P1–P3).** `ToothBuddyCore` defines *abstract* value
  types — it does **not** import Vision/AVFoundation. All inference logic (zone estimate,
  coverage, guidance, fallback sequence) is pure over those DTOs and is the TDD truth
  source (`swift test`). The app's `VisionZoneMonitor` is a thin adapter (Vision →
  DTO → engine) verified by manual smoke.
- **Camera is an enhancement, never required ([OPEN-3]).** No camera/permission/face →
  `GuidanceDecider` runs the pure fallback timed sequence; the app is 100% functional.

## 6. Exact Behavior
### 6.1 Abstract signals (Core DTOs; the app fills these from Vision)
- `FaceSignal { isPresent: Bool, mouthCenter: UnitPoint2D?, faceYaw: Double? }`
  (`UnitPoint2D` = normalized 0…1 in the image; yaw ≈ head turn left/right).
- `HandSignal { isPresent: Bool, position: UnitPoint2D?, motionEnergy: Double }`
  (`motionEnergy` = smoothed frame-to-frame wrist/finger movement magnitude, 0…1).
- `ZoneSample { face: FaceSignal, hand: HandSignal, atSeconds: Double }`.

### 6.2 `BrushingZoneEstimator` (pure)
Given the latest `ZoneSample` (+ short rolling window it keeps via an explicit state value
passed in/out — no hidden state, fully testable):
- `isActivelyBrushing` = face present AND hand present near the mouth AND
  `motionEnergy ≥ MOTION_THRESHOLD` sustained over the window.
- Coarse zone from hand position relative to `mouthCenter` + `faceYaw`:
  - left/right half of mouth → left/right; above/below mouth center → upper/lower; head
    strongly yawed → the far-side quadrants; near the front & low motion spread → front
    top/bottom. Maps to exactly the existing 6 `BrushingZone` cases.
- Returns `nil` zone when not confidently brushing (caller then holds last or falls back).
- Deterministic given inputs → unit-tested with synthetic sample sequences.

### 6.3 `ZoneCoverageTracker` (pure)
Accumulates dwell seconds per `BrushingZone` from a stream of (zone, dt). Exposes
`coverage(for:)`, `leastCovered()`, `isWellCovered(_:threshold:)`. Pure value type.

### 6.4 `GuidanceDecider` (pure)
Inputs: target zone order, current estimate, coverage, elapsed, mode (`camera` |
`fallbackTimed`). Output: the `BrushingZone` to prompt + whether to speak a new
announcement (debounced so it doesn't nag every frame). In `fallbackTimed` mode it
reproduces the old behavior (advance every `ZONE_INTERVAL` seconds) — same UX when no
camera. In `camera` mode it nudges toward the least-covered zone and confirms progress.

### 6.5 App `VisionZoneMonitor` (conforms to existing `BrushingZoneMonitoring`)
- Starts an `AVCaptureSession` (front) with `AVCaptureVideoDataOutput`; per frame runs the
  two Vision requests, builds a `ZoneSample`, feeds the Core engine, publishes
  `currentZone` (the existing `@Published` the BrushView already observes).
- If camera auth ≠ authorized, or no face for `FALLBACK_GRACE` seconds → switch to Core
  fallback timed sequence (drive `currentZone` from `GuidanceDecider` in timed mode).
- `BrushView` is unchanged except swapping the concrete monitor; it already speaks
  `currentZone` changes via `VoiceCoach` and shows the prompt overlay.

## 7. Data Model
No persistence. All new types are transient Core value types + an app monitor. Existing
`BrushingZone` enum is reused unchanged. Spec 03's session content cues are unaffected
(content/encourage stay with the script; quadrant guidance stays here).

## 8. Acceptance Criteria (each maps to a test)
- **AC1** Estimator: synthetic samples with hand left-of-mouth + motion → a left zone;
  right-of-mouth → a right zone; below mouth center → a lower zone; (mapping table
  asserted for all 6 zones with representative inputs).
- **AC2** `isActivelyBrushing` false when face absent, hand absent, or motion below
  threshold; true only when all hold over the window.
- **AC3** `ZoneCoverageTracker` accumulates dwell correctly; `leastCovered()` returns the
  smallest; `isWellCovered` respects threshold.
- **AC4** `GuidanceDecider` camera mode steers toward least-covered and debounces repeat
  announcements (no new announcement within `ANNOUNCE_DEBOUNCE`).
- **AC5** `GuidanceDecider` fallback-timed mode reproduces the legacy cadence: advances
  every `ZONE_INTERVAL` seconds through all 6 zones, deterministically.
- **AC6** Estimator returns `nil` (not a wrong zone) when confidence is low; never crashes
  on missing/partial signals.
- **AC7** Determinism: identical sample sequences → identical outputs.

## 9. Test Plan
Unit (`ToothBuddyCore` `swift test`) — one test per AC with synthetic `ZoneSample`
sequences and a fixed clock; no Vision/AVFoundation imported. App target — none new
(adapter is smoke). Manual smoke: real device, brush left/right → prompt follows roughly;
deny camera → timed fallback still guides; face leaves frame → graceful fallback; no crash.

## 10. Docs to Update
`README.md` (camera guidance is engagement-grade, optional, offline), `ROADMAP.md`/
`PLAN.md` (P4 phase ticks), `CHANGELOG.md`, this Status + §12.

## 11. Out of Scope
Per-tooth / 18-region / pressure / angle / plaque — **forbidden** (positioning lock).
ARKit face tracking; heavy AR (RealityKit/SceneKit) for the game; smile-album (deferred);
any networking; any Apple-Developer-account capability.

## 12. OPEN QUESTIONS — confirm before implementation ⛔
- **[OPEN-1]** Scope/staging = P4.1 Core engine + P4.2 Vision adapter/wiring this round;
  P4.3 lightweight game as a stretch sub-stage; **smile-progress album deferred** to its
  own later spec. (PROPOSED.)
- **[OPEN-2]** Camera tech = **Vision** (`VNDetectFaceLandmarks` + `VNDetectHumanHandPose`,
  all devices, 2D) vs ARKit face tracking (TrueDepth-only). (PROPOSED Vision.)
- **[OPEN-3]** Camera is an enhancement; with no permission/face the **timed sequence is
  the graceful fallback** and the app stays fully functional. (PROPOSED yes.)
- **[OPEN-4]** P4.3 engagement game = **lightweight 2D** overlay reacting to coarse zone
  (game logic pure-tested, render smoke) — vs **defer the game entirely** to its own spec.
  (PROPOSED: lightweight 2D, included as P4.3 stretch.)

_Answers — confirmed by user 2026-05-18:_
- **OPEN-1 →** Accepted: P4.1 Core + P4.2 Vision adapter this round; P4.3 lightweight 2D
  game as stretch; smile-album deferred to its own spec.
- **OPEN-2 →** Vision (`VNDetectFaceLandmarks` + `VNDetectHumanHandPose`).
- **OPEN-3 →** Camera is an enhancement; timed-sequence graceful fallback; app fully
  functional with no camera.
- **OPEN-4 →** P4.3 = lightweight 2D engagement game (logic pure-tested), stretch.

**Architecture note (locked):** Core uses a pure `CoarseZone` enum (no UI text); the app's
existing `BrushingZone` (with prompt/announcement) maps 1:1 to it. Keeps Core/UI boundary
clean and P4.1 Core-only (no app change until P4.2). No remaining blocking OPENs.
