# ToothBuddy Privacy Policy

**Effective date:** 2026-05-28 (version 1.0)

ToothBuddy is built on a simple privacy principle: **your data stays on your device.** This policy describes exactly what data ToothBuddy touches, where it goes, and what we don't do with it.

## Who we are

ToothBuddy is developed by an independent developer ("we"). Contact: `colintangxy@gmail.com`.

## What ToothBuddy does

ToothBuddy is an offline iPhone and iPad app that helps you build a twice-a-day brushing habit. It runs entirely on your device. There is no account, no server, no remote API, and no analytics.

## Data ToothBuddy touches

### 1. Your brushing records (stored on your device)

When you complete a brushing session, ToothBuddy saves a record of it — date, time, duration, which profile it belongs to. This is stored in Apple's Core Data system **on your device only**. We never see this data. There is no copy on any server.

If you create multiple profiles (e.g. for family members), each profile's records are isolated from the others.

If you delete the app, this data is deleted with it.

### 2. Camera frames (ephemeral, never recorded)

When you start a brushing session, ToothBuddy uses the front camera to give you coarse "which area you're brushing" feedback via Apple's on-device Vision framework. Camera frames:

- are processed entirely on your device
- are **never recorded, saved, photographed, or transmitted**
- are discarded as soon as the next frame arrives (~12 times per second)
- do not exist after the brushing session ends

ToothBuddy never accesses your photo library and never asks for photo permissions.

### 3. Apple Health (optional, write-only)

If you opt in via the History view (only on adult profiles), ToothBuddy can write your completed brushing sessions to Apple Health as **tooth-brushing events** (the standard `HKCategoryTypeIdentifier.toothbrushingEvent` Apple added in iOS 17).

- This is **write-only**. ToothBuddy never reads any health data.
- ToothBuddy never asks for any read permission — not heart rate, not steps, nothing.
- Each session is written at most once (deduplicated by external UUID).
- You can revoke this permission any time in iOS Settings → Privacy & Security → Health → ToothBuddy. Revoking does not affect your local brushing records.

The data ToothBuddy writes goes to **your** Apple Health database. We never see it.

### 4. Local notifications (on-device)

ToothBuddy can send you adaptive reminders ("time to brush", "your streak is at risk"). These notifications:

- are scheduled by ToothBuddy on your device using Apple's `UNUserNotificationCenter`
- are not sent through any server or push service (no APNs, no remote push)
- are based on your historical brushing times — that pattern stays on your device

You can disable notifications any time in iOS Settings or inside ToothBuddy.

### 5. Diagnostic metrics (Apple-provided, opt-in by you)

ToothBuddy subscribes to Apple's `MetricKit` to receive anonymous device-side performance metrics (cold launch time, hangs, CPU usage) and crash reports. This is the standard mechanism Apple gives to all apps so we can keep ToothBuddy fast and reliable. The payloads are processed by Apple on your device and never identify you.

You control this through your standard "Share With App Developers" toggle in iOS Settings → Privacy & Security → Analytics & Improvements.

## What ToothBuddy never does

- **No analytics.** No Mixpanel, no Segment, no Firebase, no Google Analytics, no Amplitude. There are no third-party SDKs in ToothBuddy.
- **No advertising.** ToothBuddy shows no ads, has no advertising identifier, and does not sell or share your data with advertisers.
- **No tracking.** ToothBuddy does not track you across apps or websites. Our privacy nutrition label on the App Store reflects this: **"Data Not Collected"** in all four categories.
- **No data sale.** We don't have your data to sell.
- **No marketing emails.** We don't have your email, unless you write to us.

## Children's privacy

ToothBuddy supports kid profiles and is appropriate for users of all ages (rated 4+ on the App Store).

Because ToothBuddy collects **zero personal information from anyone** — no account, no sign-in, no behavioral tracking, no data leaving the device — there is no children's data to safeguard under COPPA or GDPR-K from our side. We still recommend parental supervision for any device a child uses.

## Your rights

Because all of your ToothBuddy data lives on your device:

- **Access:** open the app — it's all there.
- **Delete:** delete the app, or delete individual brushing records in History view.
- **Export:** the dentist-shareable PDF report in the Family Dashboard exports a brushing history; this is generated on your device, by you, for you.

If you have written to Apple Health, that data lives in **your** Apple Health database. Manage it in the Apple Health app → Browse → Other Data → Toothbrushing.

## Changes to this policy

If we materially change this policy, we'll update the **Effective date** at the top and ship the change in an app update. The change history is visible in the public source repo.

## Contact

Questions, concerns, or feedback: `colintangxy@gmail.com`.
