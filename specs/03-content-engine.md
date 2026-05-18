# Spec 03 — Content Engine

> **Reading order for any AI session:** `ROADMAP.md` → `PLAN.md` → this file.
> Implementation is **blocked until the Confirm gate (§1) is checked**.
> **[OPEN-n]** = unresolved decisions; the detailed sections assume the **PROPOSED**
> answers. Honors product principles: offline-first, no account, software-only.

## 1. Status
- [x] 1. Spec drafted
- [x] 2. Confirm gate — user approved 2026-05-18 (all PROPOSED) ✅
- [ ] 3. Test infra delta (none expected — pure logic in existing ToothBuddyCore)
- [ ] 4. Implement (TDD, staged P3.1 → P3.4)
- [ ] 5. Verify
- [ ] 6. Docs
- [ ] 7. Commit

## 2. Problem & Goal
The 2-minute brush is silent and identical every time → boring, especially for kids;
boredom kills the habit. Brush DJ / Chompers prove that *content* alone drives adherence
with zero sensing. **Goal:** make every session feel different — varying spoken
micro-content (facts / jokes / tips / mini story beats), a gamified oral-health course
that progresses over time, and seasonal flavor — **fully offline, no account, asset-light**.

## 3. User Stories
- As a **kid**, each brush tells me something new (a fact, a joke, a tiny story beat) so
  2 minutes flies by.
- As an **adult**, I can pick a quiet "just the essentials" tone instead of kid content.
- As a **returning user**, content doesn't repeat until the pool is exhausted, and it
  feels seasonal (e.g., a winter theme in December).
- As a **learner**, a short oral-health "course" unlocks a new bite-sized lesson as I keep
  brushing.

## 4. Scope & Staging (all under P3; ordered, each verified & committed)
- **P3.1 — Content model + selection engine** (pure, the core). `ContentItem` library
  (bundled curated text) + a deterministic `ContentSelector`: no-repeat rotation per kind,
  seasonal-by-date, varies per session from a seed; fully unit-tested.
- **P3.2 — 2-minute guided audio session.** Turn the silent timer into a paced sequence
  of spoken segments (intro → per-quadrant prompts → selected micro-content → wrap-up)
  via on-device TTS, building on the existing `VoiceCoach`. The *segment timeline* is
  pure/tested; speech playback is app-layer smoke.
- **P3.3 — Gamified oral-health course.** Build on `TipsView`: an ordered lesson set with
  a pure progression rule (a new lesson unlocks per N qualifying days/sessions),
  per-profile. Progression logic unit-tested; UI app-layer.
- **P3.4 — Seasonal content.** Date-driven theme selection (already a hook in the
  selector); add seasonal item sets + a small visual accent. Minor.

**Deferred (recorded, not done in P3):**
- **Music-sync / Apple Music** — the Apple Music catalog needs a MusicKit identifier in the
  Apple-Developer portal (the same interactive Apple-account dependency the user parked for
  P2.5b). **[OPEN-3]** Local-library-only playback avoids that but is low ROI; PROPOSED:
  defer all music to its own later spec.
- **LLM-generated daily content** — needs network + an API/account, conflicting with the
  offline-first / no-account principle (and adds cost). **[OPEN-4]** PROPOSED: defer;
  revisit as an optional online enhancement later.

## 5. Exact Behavior (assumes PROPOSED)
### 5.1 Content library
Bundled, curated, original short text authored in-repo as data (JSON resource or Swift
literals), never licensed third-party IP (ROADMAP out-of-scope). Each `ContentItem`:
`id`, `kind` (`fact` | `joke` | `tip` | `storyBeat`), `text`, `minAgeBand` (`kid` |
`everyone`), optional `season` (`none` | `winter` | `spring` | `summer` | `autumn` |
`halloween`). Rendered by **on-device TTS** (`AVSpeechSynthesizer`, via `VoiceCoach`) —
offline, free, no audio assets, no size cost. **[OPEN-2]**

### 5.2 Selection (pure, deterministic)
`ContentSelector.pick(kind:now:history:tone:calendar:)`:
- Filters by tone (kid shows all; "essentials/adult" shows only `tip`, no jokes/story).
- Prefers items whose `season` matches the date's season (seasonal window by month/day);
  falls back to `none`.
- **No-repeat:** never returns an item in `history` (recently shown ids) until that kind's
  eligible pool is exhausted, then the pool resets (oldest-first).
- Deterministic given the same inputs (seeded by day + session index) → unit-testable.

### 5.3 2-minute session timeline (pure)
`SessionScript.build(durationSeconds:tone:selected:calendar:)` → an ordered list of
`ScriptCue(atSecond:, kind: .intro/.quadrant/.content/.encourage/.wrap, text:)`. Default
2:00 split into 4 × 30 s quadrants with a content cue mid-session and a wrap at the end.
The app drives `VoiceCoach` from this timeline; timeline math is pure/tested.

### 5.4 Course progression (pure, per profile)
Ordered `Lesson` list. `CourseProgression.unlockedCount(activeDays:)` = `min(totalLessons,
1 + activeDays / LESSON_EVERY)` (PROPOSED `LESSON_EVERY = 2`). Per-profile (uses the
profile's active-day count from existing aggregator). Pure/tested; `TipsView` renders
locked/unlocked.

### 5.5 Tone setting
A per-device (not per-profile, not synced) setting `contentTone` (`playful` default |
`essentials`), in `UserDefaults`. `essentials` = no jokes/story beats, terse tips, calmer
narration. **[OPEN-1]** (part of scope confirm).

## 6. Data Model
- No Core Data changes. `ContentItem`/`Lesson` are bundled static data (Core value types);
  shown-history is a small per-device `UserDefaults` ring buffer of recent ids per kind;
  course progress derives from existing per-profile active-day data (no new storage).

## 7. API Surface (ToothBuddyCore, pure)
```swift
public enum ContentKind { case fact, joke, tip, storyBeat }
public enum ContentTone { case playful, essentials }
public enum ContentSeason { case none, winter, spring, summer, autumn, halloween }
public struct ContentItem: Identifiable, Equatable, Sendable { … }
public enum ContentLibrary { public static let all: [ContentItem] }      // bundled
public enum ContentSelector {
    public static func pick(kind: ContentKind, now: Date, history: [UUID],
                            tone: ContentTone, calendar: Calendar) -> ContentItem?
    public static func season(for date: Date, calendar: Calendar) -> ContentSeason
}
public struct ScriptCue: Equatable, Sendable { … }
public enum SessionScript {
    public static func build(durationSeconds: Int, tone: ContentTone,
                             content: ContentItem?, calendar: Calendar) -> [ScriptCue]
}
public struct Lesson: Identifiable, Equatable, Sendable { … }
public enum CourseProgression {
    public static func unlockedCount(activeDays: Int, totalLessons: Int) -> Int
}
```
App layer: a small `ContentHistoryStore` (UserDefaults ring), `VoiceCoach` driven by
`SessionScript`, `TipsView`/course UI, tone toggle in settings/profile area.

## 8. Acceptance Criteria (each maps to a test)
- **AC1** `ContentSelector` never repeats an item still in `history` until the eligible
  pool is exhausted; then it resets.
- **AC2** `tone == .essentials` excludes `joke`/`storyBeat`; `.playful` includes all.
- **AC3** Seasonal: a December date prefers `winter`/`halloween`→ correct `season(for:)`;
  seasonal items preferred, non-seasonal fallback when none.
- **AC4** Deterministic: same (kind, now, history, tone) → same item.
- **AC5** `SessionScript.build` for 120 s, playful → ordered cues: intro at 0, 4 quadrant
  cues (~0/30/60/90 s), ≥1 content cue, wrap near 120 s; `essentials` omits joke/story
  content cue.
- **AC6** `CourseProgression.unlockedCount`: activeDays 0→1, 2→2, with `LESSON_EVERY=2`;
  capped at `totalLessons`.
- **AC7** Library integrity: non-empty; ids unique; no empty `text`.

## 9. Test Plan
Unit (ToothBuddyCore `swift test`) — one test per AC, fixed `Calendar`/seed; library
integrity test. App target — smoke: a session plays varying narration; `TipsView` shows
locked/unlocked lessons; tone toggle changes content. (Speech/audio is smoke-only.)

## 10. Docs to Update
`README.md` (content/course feature, offline), `ROADMAP.md`/`PLAN.md` (P3 phase ticks +
deferrals), `CHANGELOG.md`, this Status + §12.

## 11. Out of Scope
Licensed third-party IP; streaming/audio-asset production; Apple Music catalog & MusicKit
(deferred, OPEN-3); LLM/online generation (deferred, OPEN-4); any sensing; networking.

## 12. OPEN QUESTIONS — confirm before implementation ⛔
- **[OPEN-1]** Scope/staging = P3.1 selector + P3.2 TTS session + P3.3 course + P3.4
  seasonal; plus the per-device `playful`/`essentials` tone. (PROPOSED yes.)
- **[OPEN-2]** Content delivery = bundled curated original **text + on-device TTS**
  (offline, asset-light, no IP) — vs bundled pre-recorded audio (size/production/licensing).
  (PROPOSED text + TTS.)
- **[OPEN-3]** Music-sync: **defer entirely** (Apple Music = parked Apple-Developer/MusicKit
  dependency; local-library low ROI) vs do local-library-only now. (PROPOSED defer.)
- **[OPEN-4]** LLM daily content: **defer** (offline-first/no-account/network/cost
  conflict) vs include now. (PROPOSED defer.)

_Answers — confirmed by user 2026-05-18:_
- **OPEN-1 →** Accepted: staged P3.1→P3.4 + per-device `playful`/`essentials` tone.
- **OPEN-2 →** Bundled original text + on-device TTS (offline, asset-light, no IP).
- **OPEN-3 →** Music-sync deferred entirely (own later spec).
- **OPEN-4 →** LLM content deferred entirely (own later spec).
No remaining blocking OPENs.
