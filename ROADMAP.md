# ToothBuddy Roadmap

> **⚠️ Superseded (2026-05-29):** This describes the old habit-tracker / family product. The current product definition is [`docs/product-north-star.md`](docs/product-north-star.md); the Phase-1 rebuild is [`docs/plans/2026-05-29-001-feat-quality-pivot-rebuild-plan.md`](docs/plans/2026-05-29-001-feat-quality-pivot-rebuild-plan.md). Kept for history.

This document is the source of truth for product direction. Detailed specs live in [`specs/`](specs/), one per focus area, written and implemented iteratively in priority order.

## Product Principles (hard constraints)

1. **iPhone software-only.** No hardware. No BLE to third-party smart toothbrushes. No custom hardware.
2. **Camera is guidance-grade, never clinical.** Vision/ARKit face + hand landmarks can only do coarse 4–6 zone + "is the user actually brushing" signals. We never claim or build toward per-tooth, 18-region, pressure, angle, or plaque-removal measurement.
3. **"Brushing quality" is delivered through guidance, education, and self-assessment** (e.g. guided per-zone sequences, optional user-bought disclosing tablets as a consumable companion) — never through sensing claims.
4. **Apple Watch CoreMotion** is the only software-only path to real motion data. It is **deferred to the far/long-term backlog** — not excluded, not near/mid-term.
5. **Never lose a record.** Local-first, no manual sync. This is the core competitive wedge versus smart-brush apps.

## Why these priorities

Market research (competitor apps, real App Store/Reddit reviews of smart-brush apps, NIH gamification systematic review) shows the biggest openings are: a habit engine that never breaks unfairly, a family/parent layer almost no competitor has, and content that keeps the 2 minutes fresh. None of these need hardware.

## Process & Testing

Execution process, phase tracking, and the spec template live in [`PLAN.md`](PLAN.md). Summary:

- Features are built one at a time in the priority order below, each through: **Spec → Confirm (user gate) → Implement (TDD) → Verify → Docs → Commit**.
- No feature code is written until the user confirms that feature's spec.
- **Testing:** `.swiftpm` has no native test target, so platform-agnostic pure logic is extracted into a local Swift package (`ToothBuddyCore`) covered by XCTest via `swift test`; UI is covered by per-spec manual smoke checklists. The app builds and runs via **Xcode 26** (iPad/Mac Swift Playgrounds.app is no longer supported — required to enable automated tests).

---

## Priority 1 — Habit & Behavior Engine

**Goal:** Make the streak fair and the reminders smart so users come back twice a day.

**Retention/acquisition lever:** Highest retention ROI, zero sensing. The #1 complaint about competitor apps is unfair streak loss and dumb/no reminders.

**Scope:**
- Forgiving streak: freeze/grace days so a single miss doesn't reset progress.
- Longest-streak tracking.
- Morning/evening dual-slot daily goal (ADA 2×/day).
- Adaptive local notifications based on the user's historical brushing times.
- "Streak at risk" evening nudge.
- Fix the SSC leftover where onboarding shows on every launch (retention bug).

**Acceptance criteria:**
- A user who misses one day but has a freeze available keeps their streak; the freeze is consumed and visibly indicated.
- `longestStreak` is tracked and never decreases.
- The app distinguishes a "perfect day" (morning + evening) from a partial day.
- Notification permission is requested contextually (not on cold launch); reminders fire near the user's typical brush times, with sane defaults before enough history exists.
- Logging a session cancels that slot's pending reminder for the day.
- Returning users land directly in the app; onboarding shows only until completed once.

**Out of scope:** cloud sync, push notifications, any sensing.

---

## Priority 2 — Family / Parent Layer

**Goal:** Let a parent track multiple kids and get gently notified.

**Retention/acquisition lever:** Largest competitive whitespace; avoids the crowded kids-only red ocean; parent is the buyer and the sharer (acquisition).

**Scope:** multi-child profiles, parent dashboard (weekly completion, trend, missed-day alerts), family account via CloudKit/iCloud, "your kid brushed" notification, replace-brush-head / dentist-visit reminders, optional dentist-shareable report.

**Acceptance criteria:** (to be detailed in `specs/02-family-layer.md`)
- Multiple child profiles with isolated records.
- Parent view shows per-child weekly completion and streak.
- Family data syncs across devices via CloudKit; offline-first, no record loss.

**Out of scope:** social network features, public leaderboards beyond family.

---

## Priority 3 — Content Engine

**Goal:** Make the 2 minutes never the same twice.

**Retention/acquisition lever:** Brush DJ and Chompers prove content alone drives adherence with zero sensing. LLM-generated content keeps the treadmill cheap.

**Scope:** 2-minute audio adventures/stories (build on `VoiceCoach`), music-sync mode (user's Apple Music), daily-varying content (jokes/facts/mini-lessons), gamified oral-health course (build on `TipsView`), seasonal content, optional LLM-generated daily story.

**Acceptance criteria:** (to be detailed in `specs/03-content-engine.md`)

**Out of scope:** licensed third-party IP, streaming infra.

---

## Priority 4 — Camera Guidance Upgrade

**Goal:** Turn the existing zone monitor into coarse-zone guidance + an optional AR mini-game.

**Retention/acquisition lever:** The only "smart" moat that is software-only; Pokémon Smile validated camera engagement.

**Scope:** Vision/ARKit face + hand landmarks → 4–6 coarse zones, real-time pacing coaching via `VoiceCoach`, mirror + technique overlay, optional AR "brush away the monsters" game, smile progress album. Built on the existing `BrushingZoneMonitor`.

**Acceptance criteria:** (to be detailed in `specs/04-camera-guidance.md`) — explicitly framed as engagement, never measurement.

**Out of scope:** per-tooth accuracy, pressure/angle/plaque claims.

---

## Priority 5 — Adult Mode + First-Party Apple Integrations

**Goal:** Open the adult segment and integrate with the Apple ecosystem.

**Retention/acquisition lever:** Adult is a near-empty software-only segment; Apple integrations are low-cost retention surfaces.

**Scope:** adult minimal mode (no kid gamification, quiet streak + habit curve), HealthKit `toothbrushingEvent` logging, Live Activities / Dynamic Island timer, home-screen widgets, Siri Shortcuts / App Intents.

**Acceptance criteria:** (to be detailed in `specs/05-adult-apple.md`)

**Out of scope:** Apple Watch motion sensing (far backlog), any third-party hardware.

---

## Far / Long-Term Backlog

- Apple Watch CoreMotion brushing-motion detection (only revisit after Priorities 1–5).
- Disclosing-tablet companion self-assessment flow.
- Conversational LLM "brushing buddy" character.
