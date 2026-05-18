# Spec 04.2 — Vision Camera Adapter (P4.2)

> Annex to `specs/04-camera-guidance.md`. Reading order: `ROADMAP.md` → `PLAN.md` →
> `specs/04-camera-guidance.md` → this file.
> **Implementation blocked until the Confirm gate (§1) is checked.**
> This spec is intentionally exhaustive: P4.2 **cannot be unit- or simulator-tested**
> (it needs a real front camera + a real face/hand). Every decision below is pinned so
> the on-device smoke is smooth and bug-free. Engagement-grade only — never clinical
> (locked by `product-scope-software-only`).

## 1. Status
- [x] 1. Spec written
- [x] 2. Confirm gate — user approved 2026-05-18 (portrait-only accepted) ✅
- [ ] 3. (no test-infra delta — P4.1 Core already done & tested 80/80)
- [ ] 4. Implement (exactly per this spec)
- [ ] 5. Verify (build green + the §12 device smoke checklist — run by user)
- [ ] 6. Docs
- [ ] 7. Commit

## 2. Goal & non-goals
Feed the **already-tested** P4.1 Core engine (`BrushingZoneEstimator` /
`ZoneCoverageTracker` / `GuidanceDecider`) from the real front camera via Vision, and
publish a debounced `currentZone` that BrushView already consumes — with a flawless
graceful fallback to the legacy timed sequence when the camera is unavailable.
**Non-goals:** any clinical claim; per-frame UI updates; landscape camera reasoning;
new product behavior. Pure logic stays in Core; this layer is glue + I/O only.

## 3. The single most important decision — ONE shared AVCaptureSession

**Bug pre-empted:** today `CameraPreviewView` creates its *own* `AVCaptureSession` with
the front camera. If the monitor creates a *second* session on the same physical camera,
iOS lets only one claim the device — the preview goes black or Vision starves. **This is
the #1 runtime risk and is eliminated by design, not worked around.**

**Decision:** introduce one app-owned `CameraService` that owns a single
`AVCaptureSession` with **both**:
- an `AVCaptureVideoPreviewLayer` (the selfie mirror shown by `CameraPreviewView`), and
- an `AVCaptureVideoDataOutput` (frames for Vision).

`CameraPreviewView` is refactored to **display `CameraService.shared`'s preview layer**
instead of building its own session. `BrushingZoneMonitor` drives Vision off the same
service. Exactly one session, one camera claim, ever.

## 4. Component map (exact files & responsibilities)

| File | Type | Isolation | Responsibility |
|---|---|---|---|
| `CameraService.swift` (new) | `final class CameraService` | session work on a private serial `DispatchQueue`; **not** an actor; `@unchecked Sendable` with all mutable state confined to `sessionQueue` | Owns the single `AVCaptureSession`, front input, preview layer, video data output. `configure()/start()/stop()`. Vends the `AVCaptureVideoPreviewLayer`. Holds a `nonisolated` sample-buffer delegate. |
| `VisionFrameProcessor.swift` (new) | `final class`, `nonisolated`, `AVCaptureVideoDataOutputSampleBufferDelegate` | runs on the camera data-output queue | Per (throttled) frame: run Vision, compute a **Sendable** `ZoneSample`, deliver via an `@Sendable (ZoneSample) -> Void` sink. Never touches UI/@MainActor. Holds previous hand point for motion energy (queue-confined). |
| `BrushingZoneMonitor.swift` (rewrite, **same public API**) | `@MainActor final class … : ObservableObject, BrushingZoneMonitoring` | `@MainActor` | Unchanged public surface: `static let shared`, `@Published private(set) var currentZone: BrushingZone?`, `startMonitoring()`, `stopMonitoring()`. Internally: starts `CameraService`, consumes `ZoneSample`s, runs the Core engine on a main-actor decision tick, publishes a **debounced** `currentZone`, and falls back to the timed sequence. The `BrushingZone` enum stays here unchanged. |
| `CameraPreviewView.swift` (edit) | `UIViewRepresentable` | `@MainActor` | Show `CameraService.shared.previewLayer` (no own session). |
| `BrushView.swift` | — | — | **UNCHANGED.** Same `BrushingZoneMonitor.shared`, same `currentZone`/`startMonitoring`/`stopMonitoring`. Zero risk to existing UI. |

> Keeping `BrushingZoneMonitor`'s name + API and **not touching BrushView** removes an
> entire class of integration/UI regressions. The `VisionZoneMonitor` name from spec 04
> §6.5 is realized as this in-place rewrite (documented deviation, lower risk).

## 5. Concurrency model (Swift 6 strict — pin every hop)

- `AVCaptureVideoDataOutputSampleBufferDelegate.captureOutput(_:didOutput:from:)` fires on
  a **private serial dispatch queue** (`videoQueue`), never main. `VisionFrameProcessor`
  is a plain `final class` (NOT `@MainActor`); its delegate method is `nonisolated`.
- **Nothing non-Sendable crosses an actor/queue boundary.** `CMSampleBuffer`,
  `VNRequest`, `AVCaptureSession`, `CVPixelBuffer` stay on `videoQueue`. The processor
  fully consumes the frame there and produces a value-type **`ZoneSample`** (already
  `Sendable`, from Core) — only that crosses to `@MainActor`.
- Delivery to the monitor: the processor holds an `@Sendable (ZoneSample) -> Void`
  closure; the monitor sets it to `{ sample in Task { @MainActor in self.ingest(sample) } }`.
  (`self` capture: the closure captures a `weak` box; see §7.)
- `AVCaptureSession.startRunning()` / `stopRunning()` **block** — always called via
  `sessionQueue.async`. Never on main (pre-empts a main-thread-hang bug).
- `CameraService` stored mutable state (`session`, `input`, `output`, `previewLayer`) is
  **only** mutated on `sessionQueue`; the class is `@unchecked Sendable` with that
  documented invariant. `previewLayer` is created in `configure()` and thereafter only
  read; `CameraPreviewView` reads it on main after `configure()` completes (ordering
  guaranteed by §7 start sequence).
- Use `@preconcurrency import AVFoundation` and `@preconcurrency import Vision` to silence
  pre-Swift-6 delegate/Sendable noise without unsafe opt-outs elsewhere.
- The monitor's decision tick is a `@MainActor` repeating `Timer` (publishes `@Published`).

## 6. Vision pipeline (exact)

Per frame on `videoQueue`, throttled to **≤ 12 fps** (skip frames: process when
`CACurrentMediaTime() - lastProcessed ≥ 1/12`):

1. Get `CVPixelBuffer` from the sample buffer; build one
   `VNImageRequestHandler(cvPixelBuffer:orientation:options:)`.
2. **Orientation (pinned):** the brushing screen is **portrait-only for camera reasoning**
   (§13 OPEN). Front camera, portrait → handler orientation **`.leftMirrored`**. The
   capture connection sets `videoRotationAngle`/`videoOrientation = .portrait` and
   `isVideoMirrored = true` on the **preview** connection only (selfie mirror); the data
   output connection is **not** mirrored (we mirror in math, §6.4) to keep one source of
   truth.
3. Perform `[VNDetectFaceLandmarksRequest(), VNDetectHumanHandPoseRequest()]` together.
   Wrap in `do/catch`; any throw ⇒ treat as "no detection this frame" (never crash).
4. **Face → `FaceSignal`:**
   - Take the largest-bounding-box `VNFaceObservation`.
   - `mouthCenter`: centroid of `landmarks?.outerLips?.normalizedPoints` mapped into image
     space via the face `boundingBox`; if `outerLips` nil, use `boundingBox` point
     `(midX, minY + 0.30·height)` (lower third ≈ mouth). Convert to our `UnitPoint2D`
     (§6.4). `faceYaw` = `observation.yaw?.doubleValue` (may be nil; unused by v1 math but
     forwarded).
   - No face ⇒ `FaceSignal(isPresent: false)`.
5. **Hand → `HandSignal`:**
   - From `VNDetectHumanHandPoseRequest` results pick the observation with highest
     `confidence`; require it `≥ 0.3`, else treat as absent.
   - Position: `try? observation.recognizedPoint(.wrist)`; require `confidence ≥ 0.3`;
     fallback to `.middleMCP`. Convert to `UnitPoint2D`.
   - `motionEnergy`: let `d` = Euclidean distance (in unit space) between this hand point
     and the previous processed frame's hand point (queue-confined `prevHand`); EMA:
     `motion = 0.6·motion + 0.4·min(1, d / MOTION_FULL_SCALE)`, `MOTION_FULL_SCALE = 0.06`.
     Reset `motion` toward 0 when hand absent (`motion *= 0.5`).
   - No hand ⇒ `HandSignal(isPresent: false, motionEnergy: decayed)`.
6. Emit `ZoneSample(face:hand:atSeconds: CACurrentMediaTime())` via the sink.

### 6.4 Coordinate convention (pinned — prevents inverted L/R bugs)
Vision normalized points: origin **bottom-left**, x→right, y→up, in the *raw* (un-mirrored)
buffer. We convert to Core `UnitPoint2D` meaning **what the user sees in the mirrored
preview**: `ux = 1 - visionX` (mirror so the user's right hand reads as "right"),
`uy = 1 - visionY` (flip to top-origin so "upper" = small y, matching `BrushingZoneEstimator`).
This single transform is applied to **every** point (mouth + hand) identically, so the
estimator's relative dx/dy logic is correct and consistent with the mirror.
*(Rationale: the estimator only uses hand-relative-to-mouth deltas, so a globally
consistent transform is sufficient and robust; absolute correctness of axes is not
required for engagement-grade.)*

## 7. Lifecycle (idempotent, leak-free, interruption-safe)

`startMonitoring()` (`@MainActor`):
1. If already running ⇒ return (idempotent).
2. `guard AVCaptureDevice.authorizationStatus(for:.video) == .authorized` else ⇒
   `enterFallback()` and return. (Do **not** request permission here — BrushView already
   owns the prompt flow; double-request is a known bad-UX bug we avoid.)
3. `CameraService.shared.start(sink:)` — `sessionQueue.async`: lazy `configure()` once
   (add input/output/preview, set connections per §6.2, `commitConfiguration`), set the
   processor sink, `session.startRunning()`. Configuration is guarded so it runs once.
4. Start the `@MainActor` decision `Timer` (≈ every **1.0 s**, see §8). Start a
   "no-face watchdog": if no `FaceSignal.isPresent==true` for `fallbackGrace` (4 s) ⇒
   `enterFallback()` (timed mode) but **keep the camera running** so it can auto-recover
   when a face returns (`exitFallback()`).
5. Observe `AVCaptureSession.wasInterruptedNotification` /
   `.interruptionEndedNotification` / `.runtimeErrorNotification`: on interruption ⇒
   `enterFallback()`; on ended ⇒ resume camera path. Prevents the frozen-black-preview bug.

`stopMonitoring()`:
- Idempotent. Invalidate timers, remove notification observers, clear the sink,
  `sessionQueue.async { session.stopRunning() }`, set `currentZone = nil`. Camera fully
  released (battery/privacy-indicator correctness). Safe to call when never started.

Rapid Start/Done taps: all transitions go through the idempotent guards above; no
double-start, no dangling queue work (sink cleared before stop; processor checks
`sink != nil`).

Memory: the processor never retains sample buffers; `prevHand` is a small struct. The
sink closure holds `weak` monitor; monitor holds `CameraService.shared` (singleton) — no
retain cycle.

## 8. Decision tick & debounced `currentZone` (prevents UI/voice thrash)

**Bug pre-empted:** BrushView speaks on every `currentZone` change (`.onChange`, line 64)
and renders a prompt overlay. If `currentZone` changed per Vision frame the user would get
voice spam + flicker.

- The monitor keeps the latest `ZoneSample` and a short rolling **window** (samples from
  the last ~1.2 s, capped at 24).
- A `@MainActor` timer fires every **1.0 s** (`decisionInterval`):
  - camera mode: `estimate = BrushingZoneEstimator.estimate(window:)`; if
    `estimate.isActivelyBrushing`, `coverage.record(estimate.zone!, dt: decisionInterval)`.
    `out = GuidanceDecider.decide(mode:.camera, estimate:, coverage:, elapsed:, state:)`.
  - fallback mode: `out = GuidanceDecider.decide(mode:.fallbackTimed, …)`.
  - Map `out.promptZone` (`CoarseZone`) → `BrushingZone` (1:1 by case name, total switch
    — no force-unwrap). **Only assign `self.currentZone` when it actually changes**
    (`if mapped != currentZone { currentZone = mapped }`). Announcement debounce already
    lives in `GuidanceDecider` (`out.shouldAnnounce`) — but since BrushView speaks on
    `currentZone` change and `currentZone` only changes ≤ once/sec and only on real zone
    change, voice cadence is calm and correct. (We deliberately do **not** add a second
    speak path; BrushView's existing `.onChange` is the single speak trigger — no overlap
    with Spec 03 content cues, which are content/encourage only.)
- `CoarseZone`↔`BrushingZone` mapping is a total, exhaustive `switch` in the monitor
  (both enums have the same 6 cases); add a `// must stay in sync` comment on both.

## 9. CameraPreviewView refactor (no black preview)

- Remove its own `AVCaptureSession`. In `makeUIView`, ask `CameraService.shared` for the
  preview layer (creating/`configure()`-ing the service if needed — service guards
  one-time config). Add the layer as a sublayer; set `videoGravity = .resizeAspectFill`;
  mirror handled on the preview connection (§6.2).
- `layoutSubviews`/`updateUIView`: keep `previewLayer.frame = bounds` (existing behavior).
- If not authorized, the service has no inputs ⇒ preview shows the existing black
  placeholder (unchanged UX). No crash, no leak.
- Ordering guarantee: `configure()` creates `previewLayer` synchronously on `sessionQueue`
  but the layer object is created eagerly in `init` (so `CameraPreviewView` can read it on
  main immediately); only the *session wiring* is deferred to `sessionQueue`. The layer
  shows frames once `startRunning()` completes — standard, no special handling.

## 10. Constants (single source — `ZoneGuidanceConfig` + adapter-local)
Core (`ZoneGuidanceConfig.default`, already shipped): `motionThreshold 0.15`,
`nearRadius 0.35`, `deadband 0.08`, `frontXBand 0.12`, `announceDebounce 3.0`,
`zoneInterval 15.0`, `fallbackGrace 4.0`. Adapter-local: `maxFPS 12`,
`decisionInterval 1.0`, `windowSeconds 1.2`, `windowCap 24`, `handConfidenceMin 0.3`,
`motionFullScale 0.06`, `motionEMA 0.6/0.4`, `mouthFallbackHeightFrac 0.30`.

## 11. Acceptance (build) & §12 (device smoke)
**Build (I verify):** `xcodebuild build` + `xcodebuild test` both green; no new warnings
in changed files; Core `swift test` still 80/80 (Core untouched); BrushView diff = none.

## 12. Device smoke checklist (user runs — make it painless)
1. Grant camera. Start brushing → preview shows you mirrored, not black.
2. Brush upper-left → within ~1–2 s the prompt/voice moves toward upper area; brush other
   side → it follows roughly (engagement-grade, not exact). No rapid flicker, no voice
   spam (≤ ~1 change/sec).
3. Cover the camera / look away > 4 s → smoothly falls back to the timed sequence (still
   guides); uncover → camera guidance resumes.
4. Deny camera (Settings) → brushing still works with timed guidance; preview is the
   black placeholder; no crash.
5. Get a phone call / open Control Center mid-session → no frozen black preview; falls
   back; returns after.
6. Tap Start/Done rapidly 5× → no crash, no stuck camera (privacy dot off after Done),
   no duplicate audio.
7. Background the app mid-session then return → no crash; camera released on stop.
8. Battery/thermal: a 2-min session doesn't make the device hot (throttled 12 fps).

## 13. OPEN — confirm before implementation ⛔
- **[OPEN-1]** Camera reasoning is **portrait-only** (the brushing screen is designed
  upright / on a portrait stand). Landscape still *runs* (preview works) but zone
  inference assumes portrait; documented constraint, not a bug. PROPOSED: accept
  portrait-only for camera guidance (engagement-grade). _This is the only user-facing
  trade-off; everything else in this spec is forced-correct engineering._

_Answer — confirmed by user 2026-05-18:_ **Portrait-only camera reasoning accepted**
(documented constraint; landscape preview still works, zone inference assumes portrait).
No remaining OPENs.
