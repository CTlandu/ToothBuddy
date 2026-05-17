# ToothBuddy

An iOS app that helps children and adults build better brushing habits through guided feedback, timing, and gamification.

---

## Overview

**ToothBuddy** makes brushing more effective and engaging. It uses the device camera and on-device guidance to give real-time feedback on brushing (e.g., zone coverage and timing), provides short tips to correct habits, tracks brushing history, and rewards consistency through achievements and streaks.

- **Target users:** Kids and adults who want to improve their daily brushing routine.
- **Platform:** iOS (iPhone & iPad), built with SwiftUI.
- **Status:** Active, long-term project under ongoing development.

---

## Features

- **Guided brushing:** On-screen guidance with a timer and brushing-zone monitoring for pacing and coverage.
- **Voice coaching, sound, and haptics:** Audible and tactile cues during a session.
- **Brushing history:** Streaks, average duration, total sessions, and per-session star ratings, persisted locally.
- **Forgiving streak:** A rolling-grace streak that survives the occasional missed day (≈1 forgiven day per 7-day run), plus longest-streak tracking — so one slip doesn't erase weeks of progress.
- **Smart reminders:** Local morning/evening reminders that adapt to your typical brushing times, plus a gentle evening "streak at risk" nudge. No account, no network.
- **Gamification:** Achievements and rewards to encourage consistency.
- **Tips:** Short educational cards on better brushing.
- **Onboarding:** Shown once on first run; returning users go straight to the app.

---

## Roadmap

Planned and exploratory directions for the long-term project:

- Camera + on-device ML feedback (pressure, angle, missed areas).
- Richer gamification (challenges, goals, customization).
- Cloud sync and multi-device support.
- Parent/dentist dashboards and shared progress.
- Localization beyond English.

---

## Tech Stack & Requirements

- **UI:** SwiftUI
- **Minimum:** iOS 16.0
- **Devices:** iPhone and iPad
- **Category:** Health / Medical
- **Built with:** Xcode or Swift Playgrounds (Mac / iPad)

The core experience runs **offline**; no network is required.

---

## How to Run

1. Open the project in **Xcode** or **Swift Playgrounds** (Mac or iPad).
2. Open the **ToothBuddy.swiftpm** package (File → Open, then select the `.swiftpm` folder/file).
3. Select a simulator or device and run (▶️).

On first run, the app asks for camera permission so you can see yourself while brushing. If the prompt does not appear, add `NSCameraUsageDescription` to your app target's Info in Xcode.

---

## Project Structure

- `Package.swift` — Swift package and app configuration.
- `MyApp.swift` — App entry point.
- `ContentView.swift` — Main tab container.
- `OnboardingView.swift` — First-run onboarding flow.
- `BrushView.swift` — Main brushing screen: camera preview, timer, goal, zone feedback.
- `BrushingZoneMonitor.swift` — Tracks brushing zones/coverage during a session.
- `CameraPreviewView.swift` — Front-camera preview (AVFoundation) for SwiftUI.
- `HistoryView.swift` — Streak card, stats, and recent sessions with star rating.
- `TipsView.swift` — Educational brushing tip cards.
- `GamificationStore.swift` — Achievements and rewards logic.
- `VoiceCoach.swift` — Spoken brushing guidance.
- `SoundManager.swift` — Sound effects and haptic feedback.
- `Theme.swift` — Colors, gradients, and shared UI components (e.g., `StarRatingView`).
- `BrushingRecord.swift` — Model for one brushing session.
- `BrushingStore.swift` — Persists records to a JSON file; provides today count, streak, average duration.

---

## License & Third-Party Code

All code in this repository is original. Any use of open-source or third-party code is declared where applicable.
