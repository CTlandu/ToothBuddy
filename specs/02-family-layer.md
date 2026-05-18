# Spec 02 — Group Sharing (peer, no-admin)

> **Reading order for any AI session:** `ROADMAP.md` → `PLAN.md` → this file.
> Implementation is **blocked until the Confirm gate (§1) is checked**.
> All architecture decisions are RESOLVED (§13). This file is the full, rewritten spec
> after the 2026-05-18 reframe from "parent/family management" to a **peer Group** model
> (no roles, no admin, no PIN — like iCloud Shared Albums). The old parent/PIN draft is
> superseded; do not implement anything resembling an admin/parent area or a PIN.

## 1. Status
- [x] 1. Spec written (reframed peer-Group model)
- [x] 2. Confirm gate — user approved this rewritten spec 2026-05-18 ✅
- [ ] 3. Test infra delta (ToothBuddyCore DTOs + app Core Data stack)
- [ ] 4. Implement (TDD, staged P2.1 → P2.5)
- [ ] 5. Verify
- [ ] 6. Docs
- [ ] 7. Commit

## 2. Problem & Goal
ToothBuddy is single-user. The product needs **multiple brushing profiles** and the
ability to **share them in a peer group** so a family / friends / roommates / adult
children can all see each other's brushing — with **no roles, no admin, no PIN**, the way
iCloud Shared Albums work: you create or join a Group via a link; everyone is equal;
everyone sees everyone; each person tends their own profile(s). Sharing is **optional** —
the app is fully usable solo and offline; the Group only adds cross-device/cross-Apple-ID
visibility. **Goal:** multi-profile + optional peer Group sharing, zero data loss for
existing users.

## 3. User Stories
- As **anyone**, I create profiles (mine, my kids', whoever brushes on this device) and
  each has its own streak / achievements / reminders.
- As a **group member**, I open a share link and join; I now see everyone's brushing, and
  they see mine. No one is an admin.
- As a **solo user**, I never create a group; everything works locally (and silently syncs
  across *my own* devices via my private iCloud — a free bonus, no sharing needed).
- As a **member**, I get per-profile brush-head / dentist reminders and can export a
  profile's history as a PDF for the dentist.
- As an **existing single-user**, after updating I lose nothing — my history becomes one
  default profile automatically.

## 4. Scope & Staging (all under P2; ordered, each independently verified & committed)
- **P2.1 — Profiles + per-profile data + zero-loss migration** (local only, no network).
  The correctness core. Profile model; `profileID` on records; per-profile
  streak/achievements/reminders; JSON→Core Data migration; profile picker; active profile
  (per device, local, never synced).
- **P2.2 — Group model + everyone-sees-everyone dashboard** (still local-modeled; no
  CloudKit yet). The `Group` root entity, membership as data, a Group dashboard listing
  every profile with its metrics. No gating, no roles.
- **P2.3 — Brush-head & dentist reminders** (per profile).
- **P2.4 — Per-profile dentist PDF report.**
- **P2.5 — CloudKit sharing** (the optional Group goes live cross-Apple-ID). Isolated and
  last so P2.1–P2.4 never depend on network.

## 5. Architecture (all RESOLVED — see §13)
- **Persistence:** Core Data via **`NSPersistentCloudKitContainer`** with **two stores**:
  a **private** store (mirrors to the user's CloudKit *private* DB — gives free
  same-Apple-ID multi-device sync) and a **shared** store (holds a joined Group's shared
  zone). Solo users only ever touch the private store.
- **Group = one shared CloudKit record zone**, shared by a single `CKShare` with
  **`publicPermission = .readWrite`**, joinable by link (`role = publicUser`). There is
  always a technical zone **owner = whoever created the Group** (CloudKit has no ownerless
  share); this is **deliberately hidden** — no admin UI, no remove-participant, no
  stop-sharing surfaced. Everyone is an equal peer in the UX.
  - **Accepted, documented consequence:** the Group's data physically lives in the
    creator's iCloud (counts against their quota); if the creator deletes the app, that
    shared zone is at risk. We surface a gentle "this Group lives on <creator>'s iCloud"
    note; a fully creator-independent design is **out of scope** (§11).
- **Object graph to dodge a known CloudKit limitation:** `NSPersistentCloudKitContainer`
  cannot reliably add **top-level** managed objects to a zone *after* it's shared. So a
  shared Group has a single root **`Group`** object; `Profile`s are **children** of
  `Group`. Adding a member's profile later = adding a *child* to the shared root (safe),
  never a new top-level object. (Validated by smoke in P2.5; this is the #1 P2.5 risk.)
- **Testability (unchanged principle):** all pure logic lives in `ToothBuddyCore` on
  `Sendable` value-type DTOs and is the TDD truth source (`swift test`). Core Data +
  CloudKit + `CKShare` invite/accept are an app-layer adapter, **not unit-testable**,
  verified by manual smoke (P2.5 needs 2 iCloud accounts + 2 devices — the user runs it).

## 6. Exact Behavior
### 6.1 Profile
`id: UUID`, `name: String` (1–24 chars, non-empty trimmed), `colorTag: ProfileColor`
(fixed palette enum), `symbol: ProfileSymbol` (fixed kid-friendly SF Symbol set; **no
photos** — privacy), `birthYear: Int?` (optional; future P5 kid/adult mode),
`creatorLabel: String` (free text e.g. "Mom's iPad", display-only — no permission
meaning), `createdAt`, `modifiedAt`. Max **8** profiles per device-created set (group
total may exceed as members join). Names may collide (disambiguated by color/symbol +
creatorLabel).

### 6.2 Active profile (per device, NEVER synced)
Stored in `UserDefaults`. Launch: 0 profiles → first-run "create your first profile" flow;
1 → auto-select; >1 → profile picker. Switching profiles needs **no** authentication
(peer model, full trust — like Shared Albums). Accepted limitation: on a shared device a
kid can switch into another profile; this is explicitly tolerated (§12).

### 6.3 Per-profile isolation (the "ripple")
`BrushingRecord` gains non-optional `profileID: UUID`. Streak (`StreakEngine`),
achievements, history, and routine reminders (Spec 01) are all computed/stored **per
profileID** via a pure `ProfileScopedAggregator` that filters records by profile then
reuses the existing Spec 01 engines unchanged. Profile A's miss never affects B.

### 6.4 Group (P2.2 model; P2.5 makes it sync)
- A device may **create a Group** (becomes the hidden CloudKit owner) or **join via a
  link**. Group has `id, name, createdAt, modifiedAt`; `Profile`s relate to a `Group`.
- **No roles, no admin, no PIN.** Any member can read/write the shared graph (CloudKit
  zone is `.readWrite` for all). `creatorLabel` is cosmetic only.
- Leaving a Group: a member may remove **themselves** (their device stops participating;
  CloudKit removes that participant; their own locally-created profiles remain local).
  No one can remove anyone else (no admin).
- Solo (no Group) is the default and fully functional.

### 6.5 Group dashboard (P2.2)
One screen lists **every profile in the Group** (and local profiles if no Group), each
row: today morning/evening ✓/✗, current streak, longest streak, last-7-days completion
(active days / 7), a 4-week mini trend, "missed yesterday" flag. Read-only; visible to
all members equally; no gating.

### 6.6 Brush-head & dentist reminders (P2.3, per profile)
Per-profile `lastBrushHeadReplaced?` (due every **90** days) and `lastDentistVisit?` (due
every **180** days); both intervals editable per profile. Due → local notification (reuse
Spec 01 `NotificationScheduler` pattern, only when authorized) + a dashboard badge;
"Mark done" resets the anchor date.

### 6.7 Per-profile dentist report (P2.4)
Export one profile's summary for a chosen date range as a **PDF** via the system share
sheet: range, total sessions, active-day completion %, current/longest streak, a per-day
calendar grid. The report **data model** is pure/tested; PDF rendering is smoke-only.

### 6.8 CloudKit sharing goes live (P2.5)
- Offline-first: local store is always authoritative for UI; sync is background; **a local
  record is never lost or blocked on network**.
- Create Group → share the `Group` root graph; present `UICloudSharingController` with
  `publicPermission = .readWrite`; share by link (Messages/AirDrop/etc.).
- Join → open link → scene/App `userDidAcceptCloudKitShareWith` → device joins the shared
  zone; the Group's profiles/records appear; the joiner's own profiles can be added as
  children of the shared `Group`.
- Conflict/merge: `NSPersistentCloudKitContainer` handles store-level merge; app-level
  dedupe (e.g., two members create the same profile) uses a **pure `SyncMergeResolver`**
  in `ToothBuddyCore` (LWW per field-group by `modifiedAt`; brushing records are an
  append union → no loss; tombstoned deletes win over stale updates).
- "Someone brushed" awareness: a CloudKit subscription triggers a **silent** dashboard
  refresh — no nagging push to other members.
- **Interactive user steps (cannot be automated), at the start of P2.5:** in Xcode with
  the Apple-Developer account, enable iCloud (CloudKit) + container + push; provide a 2nd
  iCloud account + 2nd device for share/convergence smoke.

## 7. Data Model & Migration
### 7.1 Core Data entities ↔ ToothBuddyCore DTOs
- `CDGroup(id, name, createdAt, modifiedAt)` — optional root; nil for pure-solo until a
  Group is created/joined.
- `CDProfile(id, name, colorTag, symbol, birthYear?, creatorLabel, createdAt, modifiedAt,
  group?→CDGroup)`.
- `CDBrushingRecord(id, profileID, startDate, endDate, modifiedAt)`.
- `CDProfileCare(profileID, lastBrushHeadReplaced?, brushHeadIntervalDays=90,
  lastDentistVisit?, dentistIntervalDays=180, modifiedAt)`.
- `CDAchievementUnlock(profileID, achievementID, unlockedAt)` — replaces the old global
  `GamificationStore` UserDefaults set.
- DTO mirrors in Core: `Profile`, `Group`, `ProfileCareState`, plus existing
  `BrushingRecord` gaining non-optional `profileID: UUID`.

### 7.2 Migration (zero-loss; pure transform unit-tested in Core)
First launch of the P2.1 build:
1. If legacy `brushing_records.json` exists, decode it via a new
   `LegacyBrushingRecord` type (the old `{id,startDate,endDate}` shape, **no profileID**) —
   the live `BrushingRecord` keeps `profileID` non-optional and is never decoded from
   legacy data directly.
2. Create one default `CDProfile` (auto-named **"Me"**, default color/symbol; **no
   prompt**). No `CDGroup` (solo).
3. `MigrationTransform.migrate(legacy:defaultProfileID:) -> [BrushingRecord]` assigns every
   record `profileID = default`; persist into Core Data.
4. Migrate the existing global `GamificationStore` UserDefaults achievements →
   `CDAchievementUnlock` rows for the default profile.
5. Set an idempotent "migrated" flag; never re-run. Keep the legacy JSON untouched as a
   one-release backup.
The transform and the "already migrated?" predicate are **pure**, in Core, exhaustively
tested. Spec 01's `StreakEngine`/`ReminderPlanner` APIs gain a `profileID` filter path; their
existing tests are updated to construct records with a `profileID`.

## 8. Acceptance Criteria (per stage; each maps to a test)
**P2.1**
- AC1 Legacy JSON of N records → exactly 1 default profile owning exactly those N records;
  running migration twice changes nothing (idempotent); no record lost or duplicated.
- AC2 Records for profile A never appear in B's history/streak/achievements.
- AC3 `StreakEngine` per-profile is independent (A miss ≠ B reset).
- AC4 Achievements unlock per-profile independently.
- AC5 Active profile persists across relaunch (per device, not synced).
- AC6 0-profile impossible post-migration; 1 auto-selects; >1 shows picker; fresh install
  routes to first-run create-profile.

**P2.2**
- AC7 Creating a Group attaches existing chosen profiles as children of one `Group` root.
- AC8 Group dashboard lists every profile with metrics matching the engines/aggregator;
  no gating, visible to all.
- AC9 Leaving a Group removes only self; local-only profiles survive.

**P2.3**
- AC10 Brush-head due exactly `interval` days after anchor; "Mark done" resets; dentist
  analogous; notification scheduled only when authorized.

**P2.4**
- AC11 Report for a range contains exactly that profile's in-range sessions; totals/streak
  match engines; deterministic for fixed data (data model pure-tested).

**P2.5**
- AC12 `SyncMergeResolver` (pure): concurrent edits → LWW per field-group; tombstoned
  delete beats stale update; brushing records merge as union (no loss).
- AC13 Offline edits on two devices converge with no lost records (resolver unit tests +
  manual smoke with 2 accounts/devices).
- AC14 Adding a profile *after* the Group is shared succeeds (child-of-root mitigation;
  manual smoke — the key P2.5 risk).

## 9. Test Plan
- **Unit (`ToothBuddyCore`, `swift test`)** — TDD truth source: migration transform,
  `ProfileScopedAggregator`, dashboard metrics, brush-head/dentist due-date math,
  `SyncMergeResolver`, report data model. One test per pure-logic AC.
- **App target (`ToothBuddyTests`, `xcodebuild test`)** — Core Data CRUD against an
  in-memory store; migration against a temp store; profile/group relationships.
- **Manual smoke (per stage)** — profile picker & first-run; group create/join via link;
  dashboard; reminders fire; PDF share sheet; **P2.5**: 2 iCloud accounts + 2 devices,
  offline edits converge, add-profile-after-share works, leave-group behavior.

## 10. Docs to Update
`README.md` (Group feature, optional iCloud, no account needed solo), `ROADMAP.md`
(rename P2 "Family/Parent Layer" → "Group Sharing"), `PLAN.md` (P2 phase ticks + decision
log), `CHANGELOG.md`, this file's Status + §13, plus a `specs/02-Nx-*.md` annex per stage
if a stage grows large.

## 11. Out of Scope
- Any admin/roles/PIN/parent area (explicitly removed by the reframe).
- A creator-independent Group (surviving the creator deleting the app) — accepted
  CloudKit limitation; documented, not solved.
- True per-object ACLs inside the shared zone (CloudKit shares the whole zone readWrite).
- Social/leaderboards beyond the Group; web/Android; any hardware; kid-vs-adult behavior
  (P5; P2 only optionally stores `birthYear`).

## 12. Edge Cases (each gets a test or a smoke step)
1. Update from pre-P2 with records → exactly one default profile owns them (AC1).
2. Fresh install (no JSON) → first-run create-profile; no phantom default.
3. Delete the active profile → fall back to picker/another; never a 0-profile dead-end.
4. Same profile edited on two devices offline → converges via resolver; no loss (AC12/13).
5. iCloud signed out / unavailable → app fully functional locally; sync resumes later.
6. Join a Group while you already have local profiles → both coexist; your local profiles
   stay local unless you add them to the Group.
7. Group creator deletes the app → shared zone lost; surfaced as a known risk note (§11).
8. Member opens an expired/revoked share link → graceful "couldn't join" message.
9. Clock skew across devices → `modifiedAt` tolerant; resolver deterministic.
10. Large history per profile → dashboard/report stay O(n) (reuse Spec 01 engine).
11. Duplicate profile created by two members → `SyncMergeResolver` dedupe (AC12).

## 13. Decisions (all RESOLVED 2026-05-18 — Confirm gate covers approval of THIS spec)
- **Topology:** cross-Apple-ID sharing now, `CKShare` `publicPermission=.readWrite`,
  single shared zone, join-by-link.
- **Ownership:** single Group root graph; creator is the hidden CloudKit owner; **no admin
  UX**; accepted creator-quota / creator-leaves risk (documented, not solved).
- **No PIN / no parent area** — peer model, full trust; shared-device profile-switch risk
  accepted.
- **Persistence:** Core Data + `NSPersistentCloudKitContainer`, private + shared stores.
- **Staging:** P2.1→P2.5, each verify+commit; P2.5 (CloudKit) last & isolated.
- **Product defaults:** profiles max 8 + optional `birthYear`; dashboard week = last 7
  days, completion = active/7; brush-head 90d / dentist 180d, per-profile editable;
  report = PDF via share sheet; P2.5 silent dashboard refresh; migration default profile
  "Me" (no prompt), legacy JSON kept one release, fresh-install first-run create-profile.
- **No remaining blocking OPENs.** Confirm gate = user approves this rewritten spec.
