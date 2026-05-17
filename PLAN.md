# ToothBuddy Development Plan

The end-to-end process tracker. [`ROADMAP.md`](ROADMAP.md) defines *what* and *why*; this defines *how* and *where we are*. Specs live in [`specs/`](specs/).

> **For any AI session resuming this project:** read `ROADMAP.md`, then this file, then the spec for the feature currently in progress. Do not write feature code for a spec whose **Confirm gate** is not checked.

## Working Method

Features are built one at a time, in `ROADMAP.md` priority order. Each feature passes through these phases in order:

| Phase | What happens | Done when |
|-------|-------------|-----------|
| **1. Spec** | Write `specs/NN-feature.md` in full detail (see template below). | Spec file committed. |
| **2. Confirm** ⛔ | Present spec + open questions to the user. Iterate until 99% requirement confidence. | User explicitly approves. **No feature code before this.** |
| **3. Test infra** | (Once, during Priority 1 only.) Stand up the testable core package + XCTest. | `swift test` runs green from CLI. |
| **4. Implement (TDD)** | Translate acceptance criteria into failing tests, then implement until green. | All spec acceptance tests pass. |
| **5. Verify** | Build the `.swiftpm`, run `swift test`, run the spec's manual smoke checklist. | Build OK + tests green + checklist done. |
| **6. Docs** | Update README / ROADMAP / spec status + `CHANGELOG.md`. | Docs reflect shipped behavior. |
| **7. Commit** | One feature per commit set, message references the spec. Push. | Pushed to `origin/main`. |

The session **task list** mirrors these phases for the active feature (dual-track). This file is the durable cross-session record; the task list is the in-session view.

### The Confirm gate (⛔) is mandatory

Per explicit user direction: for every requirement and key point, confirm with the user until 99% confident before acting. Phase 2 is where that happens. A spec may not move to implementation until its Confirm checkbox below is ticked.

## Testing Strategy (decided)

`.swiftpm` app projects have no native test target and cannot be tested with `swift test` directly (the product is an iOS app). Decision: **extract platform-agnostic pure logic into a local Swift package library target** (working name `ToothBuddyCore`) that the app depends on. Unit tests (XCTest) target that library and run via `swift test` on macOS/CI. The app stays runnable in Swift Playgrounds. UI/integration is covered by per-spec manual smoke checklists. This restructure happens once, as part of Priority 1.

## Spec Template (every `specs/NN-feature.md`)

1. **Status** — phase checkboxes (mirrors the table above).
2. **Problem & goal** — what user pain, what success looks like.
3. **User stories** — as a {kid|parent|adult}, I want… so that…
4. **Exact behavior** — precise, unambiguous rules; all states.
5. **Data model changes** — types, persistence, migration of existing stored data.
6. **API surface** — new/changed types, methods, signatures.
7. **Edge cases** — enumerated, each with expected behavior.
8. **Acceptance criteria** — Given/When/Then, each mapped to a test.
9. **Test plan** — unit cases (the truth source for TDD) + manual smoke checklist.
10. **Docs to update** — exact files.
11. **Out of scope** — explicit non-goals.

## Status Board

Legend: ☐ not started · ◐ in progress · ☑ done · ⛔ blocked on user confirm

### Scaffolding
- ☑ ROADMAP.md
- ◐ PLAN.md + ROADMAP Process section + commit

### Priority 1 — Habit & Behavior Engine
- ☐ 1. Spec (`specs/01-habit-engine.md`)
- ⛔ 2. Confirm (awaiting user)
- ☐ 3. Test infra (ToothBuddyCore + XCTest)
- ☐ 4. Implement (TDD)
- ☐ 5. Verify
- ☐ 6. Docs
- ☐ 7. Commit

### Priority 2 — Family / Parent Layer
- ☐ 1. Spec · ☐ 2. Confirm · ☐ 4. Implement · ☐ 5. Verify · ☐ 6. Docs · ☐ 7. Commit

### Priority 3 — Content Engine
- ☐ 1. Spec · ☐ 2. Confirm · ☐ 4. Implement · ☐ 5. Verify · ☐ 6. Docs · ☐ 7. Commit

### Priority 4 — Camera Guidance Upgrade
- ☐ 1. Spec · ☐ 2. Confirm · ☐ 4. Implement · ☐ 5. Verify · ☐ 6. Docs · ☐ 7. Commit

### Priority 5 — Adult Mode + Apple Integrations
- ☐ 1. Spec · ☐ 2. Confirm · ☐ 4. Implement · ☐ 5. Verify · ☐ 6. Docs · ☐ 7. Commit

## Decision Log

| Date | Decision |
|------|----------|
| 2026-05-18 | Project repositioned from Swift Student Challenge to long-term real product. |
| 2026-05-18 | iPhone software-only; no hardware/BLE; camera is guidance-grade not clinical; Apple Watch deferred to far backlog. |
| 2026-05-18 | Testing via extracted `ToothBuddyCore` package + XCTest. |
| 2026-05-18 | Iterative per-feature cadence (spec → confirm → implement). |
| 2026-05-18 | Progress tracked dual-track: this file + session task list. |
