# Spec 04.3 — "Sugar Bugs" Brushing Game (P4.3)

> Annex to `specs/04-camera-guidance.md`. Reading order: `ROADMAP.md` → `PLAN.md` →
> `specs/04-camera-guidance.md` → `specs/04-2-vision-adapter.md` → this file.
> **Implementation blocked until the Confirm gate (§1) is checked.**
> P4.3 is the *fun layer*; the user's bar is explicit: **must look good, feel good,
> interact well, and ship with ~99% confidence of no bug / no interaction friction / not
> ugly — confirm the design before any code.** Visual/feel cannot be unit-tested, so this
> spec pins the design precisely; only the game *rules* are TDD'd in Core.

## 1. Status
- [x] 1. Spec written
- [x] 2. Confirm gate — user approved 2026-05-18 (all PROPOSED) ✅
- [ ] 3. (no test-infra delta — Core `BrushGame` uses existing ToothBuddyCore)
- [ ] 4. Implement (Core rules TDD → SwiftUI overlay exactly per §6–§9)
- [ ] 5. Verify (build clean + §12 device/visual smoke — user runs)
- [ ] 6. Docs
- [ ] 7. Commit

## 2. Concept (plain language)
During the 2-minute brush, the kid sees themselves (the existing selfie preview). Friendly
jelly **Sugar Bugs** cling to the mouth zone they should brush right now. When they
actually brush that zone (we already know it from `BrushingZoneMonitor`), the bugs get
**scrubbed away** with a juicy squash → burst-into-toothpaste-bubbles pop, a floating
`+points`, sound + a light haptic. Clearing a zone stamps a springy ✨ **Clean!**. A slim
top progress bar fills. At 0:00 a celebratory card: "You zapped 37 Sugar Bugs!", 1–3 gold
stars, gentle confetti. It is **opt-out** (adults' `essentials` tone = no game) and
**degrades gracefully** with Reduce Motion and with no camera.

## 3. Art direction (committed — distinctive, cohesive with the existing app)
The app's identity is **soft, rounded, friendly** (Nunito rounded, pastel `Theme`, SF
Symbols, `tooth.png`). We do NOT introduce a foreign art style; we push *that* identity
to its most tactile, "squishy-candy" extreme. The one **memorable** thing: *the jelly
Sugar Bugs that squash and burst into toothpaste bubbles.*

- **Sugar Bug** — pure vector (no image assets; scalable; tiny): a wobbling rounded blob
  body (~52 pt) in a translucent candy color; two oversized white eyes with dark pupils
  that **blink** every 2–4 s; 3 stubby jiggling legs. Idle = slow "breathing" scale
  (1.0↔1.06, 1.6 s ease-in-out) + ±3° wobble, desynced per bug via a per-bug phase seed.
- **Palette** — derived strictly from `Theme` + a 4-tone candy set: coral, grape, mint,
  tangerine (translucent ~0.85). Glow/target ring uses `Theme.accentBlue`. Clean stamp =
  `Theme` green. No new brand colors; no purple-on-white AI cliché.
- **Type** — Nunito (existing): floating `+10` and score in **Nunito ExtraBold**; zone
  chip + summary in the existing Nunito styles. No new fonts.
- **Target zone** — a soft pulsing rounded-rect "spotlight" (blurred stroke,
  `accentBlue`, 1.0↔1.0 opacity 0.35↔0.6, 1.4 s) with a small Nunito chip label
  ("Upper left"). Sugar Bugs cluster loosely inside it with slight scatter.
- **The clear "juice" (the signature 450 ms moment)** — per bug, in order:
  1. squash `scaleY 1→0.55, scaleX 1→1.35` (90 ms, easeOut),
  2. pop: bug fades out over 120 ms while **5–7 small bubble circles** (white, 6–12 pt,
     subtle rim) burst outward along jittered vectors, rising + shrinking + fading
     (320 ms, easeOut), with 2 tiny sparkles (SF Symbol `sparkle`) twinkling,
  3. `+10` in Nunito ExtraBold (`accentBlue`) pops at the bug center, floats up 28 pt,
     fades (380 ms),
  4. `SoundManager` pop cue + `UIImpactFeedbackGenerator(.light)` (reuse existing
     sound/haptics; respect the existing mute).
  Zone fully cleared → ring snaps green, contracts + fades (260 ms, spring), a
  `sparkles` + "Clean!" Nunito-ExtraBold badge bounces in then fades (900 ms).
- **HUD** — top inset, minimal so it never fights the camera: a 6 pt rounded progress
  track (tooth `Image` cap) + a right-aligned score (`Nunito ExtraBold`, monospaced
  digits, count-up tween). Bottom = the **existing** timer/controls, **unmoved**.
- **End summary** — a card springs up from bottom (`Theme.surfaceFrost`, 28 pt radius,
  soft shadow): big count-up number, a row of 1–3 gold stars reusing the existing
  `StarRatingView` look, one warm Nunito line ("Sparkly clean! See you tonight 🌙"),
  gentle confetti (≤ 60 lightweight pieces, 1.4 s, then removed). One existing-style
  "Done" button. Confetti & count-up are skipped under Reduce Motion.

## 4. Reduce Motion & performance (non-negotiable quality bar)
- `@Environment(\.accessibilityReduceMotion)`: when true → no wobble/idle-scale/particles/
  confetti/float; bugs simply cross-fade + a 1.0→0.85 scale on clear; stamp is a static
  fade. All information remains; only motion is removed.
- 60 fps target. **Hard caps:** ≤ 8 Sugar Bugs on screen at once; ≤ 7 bubble particles ×
  ≤ 3 simultaneous pops; confetti ≤ 60 pieces & lives ≤ 1.4 s then despawned. No timers
  per node — one `TimelineView(.animation)` drives everything from a single date; all
  motion is pure functions of `(now − spawnTime)` (no per-frame state mutation in the
  view body → no layout thrash). Particles are value structs in one array, culled when
  finished. Target steady state < ~30 active drawables.

## 5. Architecture
- **Rendering: SwiftUI `Canvas` + `TimelineView(.animation)`** (decided, [OPEN-1]). One
  immediate-mode `Canvas` draws bugs, particles, ring, floating text. Rationale vs
  SpriteKit: no SKScene/coordinate/lifecycle bug surface, trivially Theme-consistent,
  Reduce-Motion is one branch, integrates as a plain SwiftUI overlay, deterministic
  redraw. Lower bug surface = directly serves the user's "99% no-bug" bar.
- **Pure game rules in `ToothBuddyCore` → `BrushGame`** (TDD truth source): bug inventory
  per `CoarseZone`, scrub-clear rate, score, stars, completion. No SwiftUI/Foundation
  timers; a pure `advance(currentZone:isActive:dt:)` mutator + derived getters. Visual
  layer is a pure function of `BrushGame` state + clock; it never decides game logic.
- **Signal source: reuse P4.2, no new camera code.** The overlay observes
  `BrushingZoneMonitor.shared`. We add ONE additive, non-breaking published signal:
  `@Published private(set) var isBrushingActive: Bool` (set from the same decision tick
  using the estimate already computed; in fallback/timed mode it is `true` while a zone
  is active so the game still plays). Existing API/BrushView/`currentZone` untouched.
- **Placement:** a single new `BrushGameOverlay` view, shown by BrushView **inside the
  existing camera area, above `CameraPreviewView`, below existing controls**, only while
  `isBrushing` && tone == `playful`. BrushView diff = a few lines (one conditional
  overlay). No existing view restructured.

## 6. Exact behavior
### 6.1 Session start
- Tone `essentials` ⇒ overlay not shown at all (calm; no behavior change for adults).
- `BrushGame` seeds **3 bugs per zone × 6 zones = 18** (config constant). Bugs for a zone
  are only *visible/clusterable* when that zone is the current target; off-target zones'
  bugs are "waiting" (not drawn) — keeps ≤ 8 on screen.
### 6.2 During brushing
- `currentZone` (from monitor, debounced ≤ 1/s) = the spotlight target. Its waiting bugs
  animate in (stagger 60 ms, spring) inside the ring.
- While `currentZone == z` and `isBrushingActive`: `BrushGame.advance` removes bugs in `z`
  at `clearInterval` (one bug per ~0.7 s of active brushing in that zone) — paced so a
  zone of 3 clears in ~2 s of real brushing (rewarding, not instant, not grindy).
- Each removed bug → the §3 clear juice. Score += 10/bug. When a zone hits 0 → Clean!
  stamp; that zone counts as covered.
- If `currentZone` changes with bugs still left, remaining bugs in the old zone gently
  fade out (they'll re-appear if that zone is targeted again later — game stays winnable).
### 6.3 No-camera / timed fallback
- `isBrushingActive` is `true` whenever a timed zone is current (no motion data), so bugs
  on the timed zone auto-clear at the same pace — the game still plays and feels good with
  zero camera. Consistent with P4.2's fallback philosophy. ([OPEN-3])
### 6.4 End / win — IMPLEMENTATION REFINEMENT (recorded 2026-05-18, preserves intent)
A *separate* end-of-timer summary card would need the overlay to persist briefly after
`isBrushing == false` and coordinate with the existing done-sheet — a fragile lifecycle
bug surface that cannot be device-verified here. Lower-bug realization that keeps the
same goals (juice + celebration + stars):
- **Win moment (overlay-owned, in-session):** when `BrushGame.totalRemaining` hits 0, the
  overlay plays a full "All sparkly clean! ✨" celebration (big bounce title + confetti,
  Reduce-Motion aware) right there — no lifecycle coordination, no flow blocking.
- **End-of-session stars/record:** handled by the **existing, unchanged** Done sheet
  (it already renders a `StarRatingView` + the session record). The game does not add a
  competing card. `BrushGame.stars()` is still computed/tested for future reuse.
This is a deliberate, documented refinement within the confirmed design's goals, not a
feature cut — kids still get the celebration; stars still appear (existing flow).

## 7. Core API (`ToothBuddyCore`, pure, TDD)
```swift
public struct BrushGameConfig: Equatable, Sendable {
    public var bugsPerZone = 3
    public var clearInterval = 0.7          // seconds of active brushing per bug
    public var pointsPerBug = 10
    public static let `default` = BrushGameConfig()
}
public struct BrushGame: Equatable, Sendable {
    public private(set) var remaining: [CoarseZone: Int]   // starts bugsPerZone each
    public private(set) var score: Int
    public init(config: BrushGameConfig = .default)
    /// Advance by dt seconds. Clears ≤ floor(activeTime/clearInterval) bugs in `zone`
    /// only while `isActive`. Pure & deterministic (carries a fractional accumulator).
    public mutating func advance(currentZone: CoarseZone?, isActive: Bool, dt: Double)
    public var totalRemaining: Int
    public var bugsZapped: Int                              // config total − remaining
    public func zonesCleared() -> Int
    public func stars() -> Int                              // 6→3, 4→2, 1→1, else 0
}
```
The view derives all visuals from `BrushGame` + per-bug spawn timestamps it owns; the
engine never knows about pixels. Acceptance §11 tests this exhaustively.

## 8. SwiftUI structure (exact, to pre-empt build/runtime/layout bugs)
- `BrushGameOverlay: View` — `@StateObject vm = BrushGameViewModel()` (`@MainActor`),
  `@Environment(\.accessibilityReduceMotion) var reduceMotion`. Body =
  `TimelineView(.animation(minimumInterval: 1/60, paused: vm.isFinished))` →
  `Canvas { ctx, size in vm.draw(into: ctx, size: size, now: timeline.date, reduceMotion:) }`
  plus the HUD (`overlay` aligned top) and the summary (`overlay` when finished). The
  Canvas is `.allowsHitTesting(false)` (purely decorative; brushing = the input, not
  taps) → zero gesture conflict with existing controls.
- `BrushGameViewModel` — owns `BrushGame` (Core), the array of active visual entities
  (bugs/particles/floaters/confetti as value structs with `spawn`/`life`), subscribes via
  Combine to `BrushingZoneMonitor.shared.$currentZone` & `$isBrushingActive`, and a single
  `Timer`-free advance hook driven by the TimelineView date delta (vm computes `dt` from
  successive draw dates, clamped to ≤ 1/20 to stay stable if frames drop). All mutation on
  `@MainActor`. No retain cycles (weak monitor; vm owned by the overlay).
- Layout: Canvas fills the camera area via `GeometryReader`-free intrinsic fill
  (`.frame(maxWidth:.infinity,maxHeight:.infinity)`); zone→screen position is computed
  from a fixed normalized layout map (6 zones → fixed UnitPoint anchors in the overlay's
  own bounds, NOT tied to real mouth pixels — engagement, not AR) so it can never
  mis-position or NaN.
- All animation = pure math on elapsed time; **no `withAnimation` race**, no implicit
  animations on changing state (avoids the classic SwiftUI "animation glitch" bug class).

## 9. BrushView integration (minimal, safe, reversible)
- Add inside the camera ZStack, above `CameraPreviewView`:
  `if isBrushing, ContentHistoryStore.shared.tone == .playful { BrushGameOverlay() }`.
- The existing zone text prompt + voice stay (the game *complements*, doesn't replace
  them — kids who ignore the game still get guided; [OPEN-2]). The game's own zone
  spotlight is visual reinforcement.
- The existing done-sheet/record flow is **unchanged**; per §6.4 the game shows only an
  in-session win celebration (no end card) so there is zero teardown coordination.
- Diff target: ≤ ~6 added lines in BrushView; no existing line moved. Behavior with the
  game off (essentials/none) is byte-identical to today.

## 10. Edge cases
1. Reduce Motion on → no particles/confetti/wobble; still fully playable & legible.
2. Mute on (existing) → no game sound; haptics still (light) unless also gated by mute
   (match existing SoundManager policy — follow whatever mute governs today).
3. No camera → timed fallback game (§6.3); never empty/broken.
4. Session shorter than clearing all bugs → fine; stars reflect zones cleared.
5. Rapid Start/Done → vm reset on appear; overlay removed on `!isBrushing`; no dangling
   timers (there are none — TimelineView pauses when finished/removed).
6. Device rotation → overlay uses its own normalized layout, not camera pixels →
   no misposition (consistent with portrait-only camera reasoning).
7. Tone toggled mid-session (unlikely) → overlay appears/disappears cleanly on next
   render; no crash (vm guards).
8. Backgrounding → TimelineView pauses; on return, dt is clamped so no huge jump.
9. Extremely fast brushing across zones → debounced `currentZone` (≤1/s) keeps spawns
   calm; caps in §4 hold.

## 11. Acceptance
**Core unit (TDD, `swift test`)**: `BrushGame` — seeds 18; `advance` clears exactly
`floor(activeSeconds/clearInterval)` bugs only in the active zone only while active;
fractional accumulator carries; score = 10×zapped; `zonesCleared`/`stars` thresholds
(6→3,4→2,1→1,0→0); no-op when zone nil or inactive; never negative; deterministic.
**Build (I verify)**: `xcodebuild build` + `test` green; 0 warnings in new/changed files;
Core `swift test` all green; BrushView behaves identically when game off.
**Visual/feel (user, §12)**: cannot be automated.

## 12. Device visual-smoke checklist (user runs — keep it painless)
1. Playful tone, start brushing → bugs appear on the target zone; idle wobble looks
   alive, not jittery; HUD unobtrusive; camera still smooth.
2. Brush the target zone → bugs clear with the squishy pop; `+10` floats; sound+haptic
   fire; pacing feels rewarding (~2 s/zone), not instant or grindy.
3. Clear a zone → "Clean!" stamp bounces; ring goes green & away.
4. Settings → Reduce Motion ON → replay: no particle storm/confetti; still clear,
   pretty, legible; nothing janky.
5. Essentials tone → no game at all; screen identical to before P4.3.
6. Deny camera → timed fallback: game still plays zone-by-zone, still satisfying.
7. End of 2 min → summary card springs up; star count matches zones cleared; confetti
   tasteful (or absent under Reduce Motion); Done dismisses cleanly into the normal flow.
8. Rapid Start/Done ×5, rotate device, background mid-game → no crash, no stuck overlay,
   no frame hitching, camera not stuck on after Done.

## 13. OPEN — confirm before implementation ⛔
- **[OPEN-1]** Rendering = **SwiftUI `Canvas` + `TimelineView`** (lowest bug surface,
  Theme-consistent, Reduce-Motion trivial) vs SpriteKit. PROPOSED Canvas.
- **[OPEN-2]** The game **complements** the existing zone text/voice prompts (both stay)
  vs the game **replaces** the text prompt while playing. PROPOSED complement (safer,
  still guides kids who ignore the game).
- **[OPEN-3]** No-camera fallback **also plays the game** (auto-clear on the timed zone)
  vs game only when camera is available. PROPOSED also plays (always engaging).
- **[OPEN-4]** Art direction = the committed **"jelly Sugar Bugs that pop into toothpaste
  bubbles," vector-only, matching the existing soft-rounded Nunito/Theme identity** + the
  full §3 juice gated by Reduce Motion. PROPOSED as written. (If you want a different
  fantasy — space, monsters, underwater — say so now; it changes §3 only, not the
  architecture.)

_Answers — confirmed by user 2026-05-18:_
- **OPEN-1 →** SwiftUI `Canvas` + `TimelineView`.
- **OPEN-2 →** Game complements existing text/voice prompts (both stay).
- **OPEN-3 →** No-camera fallback also plays the game (auto-clear on the timed zone).
- **OPEN-4 →** "Jelly Sugar Bugs → toothpaste bubbles", vector-only, matching the
  existing soft-rounded Nunito/Theme identity, full §3 juice gated by Reduce Motion.
No remaining OPENs.
