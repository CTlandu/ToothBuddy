# App Store Review Notes — ToothBuddy

Copy-paste material for App Store Connect → App Review → **App Review Information → Notes**, and the **App Review Information → Sign-In Information** / **Demo Account** fields. This document lives in the repo so it stays version-controlled with the behavior it describes; it is **not** shipped in the app bundle.

Update this file when you change any of: HealthKit usage, camera usage, permission strings, app architecture (still offline?), or App Group identifier.

---

## TL;DR for the reviewer

> ToothBuddy is a fully offline, local-first iPhone/iPad app that helps kids and adults build a twice-a-day brushing habit. It needs **no account, no network, no demo credentials**. All data stays on-device except for an optional, write-only Apple Health export of the system-provided `toothbrushingEvent` category (iOS 17+).

---

## Regulated Medical Device declaration

**Answer: No.**

`LSApplicationCategoryType` is `public.app-category.healthcare-fitness`. ToothBuddy is a **habit-and-engagement app**, not a regulated medical device. It does not diagnose, treat, cure, mitigate, or prevent any disease. Camera-based zone hints are explicitly **guidance-grade only** (Vision face/hand landmark coarse 4–6 zone classification) — there is no clinical, per-tooth, pressure, angle, or plaque-removal measurement.

This matches Apple's 2026-03 Regulated Medical Device Status declaration requirement for Health & Fitness category apps.

---

## Demo account & sign-in

- **Sign-in required:** No.
- **Demo account:** Not applicable — there is no login, no server, no remote API.
- **Network calls:** None. The app makes zero outbound HTTP / WebSocket / push connections. The only first-party data crossing the app boundary is the optional HealthKit write (Apple Health on-device).

---

## Permissions requested at runtime

| Permission | Info.plist key | When asked | Why |
|---|---|---|---|
| Camera | `NSCameraUsageDescription` | When the user taps "Start brushing" on the main brushing screen (never on cold launch). | Front-camera preview so the user can see themselves while brushing; coarse face-position hints for the on-device Vision zone monitor. **No frames are recorded, transmitted, or persisted.** |
| Local Notifications | (no usage string — `UNUserNotificationCenter`) | Contextually after onboarding when the user opts into reminders. | Morning + evening adaptive brushing reminders and a "streak at risk" evening nudge. All scheduling is local; no push, no server, no APNs. |
| HealthKit (write-only) | `NSHealthUpdateUsageDescription` | When the user taps **"Save brushing to Apple Health"** in the adult History view (Spec 05 §6.6 — never on cold launch, never on a kid profile). | See "HealthKit specifics" below. |

The microphone, contacts, location, photo library, and motion APIs are **not** used and **not** declared.

---

## HealthKit specifics (relevant section for HealthKit reviewers)

### What we access

- **Exactly one HealthKit type:** `HKCategoryTypeIdentifier.toothbrushingEvent`.
- **Direction:** `HKHealthStore.requestAuthorization(toShare: [toothbrushingEvent], read: nil)` — **share-only authorization, never any read type**.
- **What we never do:** read any health data, infer user state from health data, sample heart rate / step count / sleep / anything else.

### Why we need it

To let users see their completed brushing sessions in the Apple Health "Toothbrushing" timeline alongside other health activities. This is a standard category Apple introduced specifically for tooth-brushing apps (iOS 17+).

### How the data flows

1. User completes a brushing session in-app (timer reaches 0 or user finishes early).
2. The local record (Core Data, on-device only) is written as the source of truth.
3. If — and only if — the user has previously tapped the contextual opt-in **and** HealthKit returned `.sharingAuthorized` for `toothbrushingEvent`, `HealthExporter.exportIfNeeded` writes one `HKCategorySample` with:
   - `start` / `end` = the session's actual times,
   - `metadata[HKMetadataKeyExternalUUID]` = the session's stable UUID,
   - `value = HKCategoryValue.notApplicable` (per Apple's spec for `toothbrushingEvent`).
4. A second idempotency net: the app tracks already-exported session ids in a per-device `UserDefaults` set, so a relaunch or duplicate completion path can never double-write.

If the user revokes authorization in Settings → Health, the exporter silently no-ops on subsequent sessions; local records remain intact.

### How to test the HealthKit flow

1. Build & run on a physical iOS 17+ device (HealthKit is not fully available in Simulator).
2. On first launch, complete onboarding → create a profile → in the profile sheet, set **Mode = Adult**.
3. Tap the brushing button on the main tab. Let the timer reach 0 (or tap "Done" early). A calm "Brushing logged" sheet appears.
4. Open the **History** tab. Find the row **"Save brushing to Apple Health"** and tap it. iOS will present the standard HealthKit permission sheet — grant **Toothbrushing: Allow**.
5. Complete one more brushing session.
6. Open **Apple Health → Browse → Other Data → Toothbrushing** — the session appears with ToothBuddy as the source.
7. (Optional) Verify revocation: open **Settings → Health → Data Access & Devices → ToothBuddy** and turn Toothbrushing off. Complete another session — no new Health entry is created and the in-app local record is unaffected.

---

## Privacy posture

- **Networking:** none.
- **Third-party SDKs:** none.
- **Analytics:** none.
- **Tracking:** none. `NSPrivacyTracking = false` and `NSPrivacyTrackingDomains` empty in `PrivacyInfo.xcprivacy` (and in the widget extension's manifest).
- **Data collected and linked / not linked to user:** **none.** Everything is on-device.
- **Required-reason APIs declared in `PrivacyInfo.xcprivacy`:**
  - `NSPrivacyAccessedAPICategoryUserDefaults` — reason **CA92.1** ("Access info from same app").
  - `NSPrivacyAccessedAPICategorySystemBootTime` — reason **35F9.1** (timing within the app, for camera-frame throttling and brushing-zone debouncing).

The privacy nutrition label in App Store Connect should be set to:
- **Data Used to Track You:** none.
- **Data Linked to You:** none.
- **Data Not Linked to You:** **Health & Fitness → Health (Other)** — *only if you choose to disclose the optional HealthKit write*; otherwise none. (Apple's guidance is that data written to Apple Health and never read back by the app does not require disclosure, but disclosing the category as "stored on user's device" is defensible and conservative.)

---

## Architecture (one-paragraph summary for the reviewer)

ToothBuddy is a SwiftUI app (iOS 16.0+, with iOS 16.1+ Live Activities gated by `if #available`). All user data is in a programmatic Core Data stack on-device. A peer "family group" feature is local-modeled today; CloudKit sync is planned (`P2.5b`) but not yet wired in this build. The app includes a Live Activity / Home-Screen Widget app-extension (`ToothBuddyWidget`) that reads a small JSON snapshot from a shared App Group (`group.com.ctlandu.ToothBuddy`) — no IPC beyond that. Pure logic is factored into a local Swift package (`ToothBuddyCore`) with 108 XCTest cases; the app target has 18 additional tests. No third-party dependencies.

---

## Common reviewer questions, pre-answered

**Q: Where can I see the camera-frame handling code to verify nothing is stored?**
A: `CameraService.swift` (single camera claim, preview + Vision share one session) and `VisionFrameProcessor.swift` (throttled, nonisolated). No `AVAssetWriter`, no `PHPhotoLibrary`, no upload code anywhere.

**Q: Is there any usage of `IDFA` / App Tracking Transparency?**
A: No. The app does not link against AdSupport, AppTrackingTransparency, or any ad framework, and does not query the IDFA. ATT prompt is intentionally not shown.

**Q: Does the app collect any data from children?**
A: No. The app has no user accounts, no remote storage, and no data collection. Profiles are local-only labels for who is brushing. Kid mode is a UI style toggle; it does not change the data-handling posture.

**Q: Why does the project folder end in `.swiftpm` but the project is an Xcode project?**
A: Historical: the project was originally a Swift Playgrounds package, then migrated to Xcode + XcodeGen on 2026-05-18 to enable entitlements (HealthKit, App Group, future CloudKit) that Swift Playgrounds cannot carry. The folder name is legacy only — a symlink (`ToothBuddy-src`) points to it. The source of truth is `project.yml`; `ToothBuddy.xcodeproj` is `.gitignore`'d and regenerated via `xcodegen generate`.
