# ToothBuddy

A Swift Playgrounds app that helps children and adults build better brushing habits through guided feedback and timing—submitted for the **Swift Student Challenge**.

---

## Overview

**ToothBuddy** is a demo app that makes brushing more effective and engaging. It uses the device camera and on-device guidance to give real-time feedback on brushing (e.g., pressure and angle), provides short video tips to correct habits, and tracks brushing time. The demo is designed to showcase core features within about **3 minutes**, so judges can quickly experience the value without sign-up or long onboarding.

- **Target users:** Kids and adults who want to improve their brushing routine.
- **Platform:** iOS (iPhone & iPad), built as a `.swiftpm` (Swift Playgrounds App) for the Swift Student Challenge.

---

## Swift Student Challenge

This project follows SSC requirements:

- **Format:** `.swiftpm` (Swift Playgrounds App Project).
- **Size:** Uncompressed project contents stay under **25 MB** (code, assets, and resources).
- **Experience:** Core experience is **offline**; no network required for the demo.
- **Language:** All in-app text, voiceover, and submission materials are in **English**.
- **Runtime:** Runs on the latest Xcode or Swift Playgrounds (latest iOS/iPadOS or macOS recommended).

---

## Demo Scope (3-Minute Experience)

The demo focuses on what judges can try in a short session:

- **Guided brushing:** Simple visual/on-screen guidance (e.g., timer, zones or prompts).
- **Brushing timer:** Track how long you brush.
- **Lightweight feedback:** Conceptual or UI-based feedback on brushing (e.g., “good angle,” “slow down”) without requiring full ML/camera in the first version if needed to stay within 25 MB and 3 minutes.

Future directions (not required for the demo) may include: camera + AI feedback, mini puzzles while brushing, and cloud/parent/dentist dashboards. The current submission is a **focused, runnable demo** of the core idea.

---

## Tech Stack & Requirements

- **UI:** SwiftUI  
- **Minimum:** iOS 16.0  
- **Devices:** iPhone and iPad  
- **Category:** Medical  
- **Built with:** Xcode or Swift Playgrounds (Mac / iPad)

---

## How to Run

1. Open the project in **Xcode** or **Swift Playgrounds** (Mac or iPad).
2. Open the **ToothBuddy.swiftpm** package (File → Open, then select the `.swiftpm` folder/file).
3. Select a simulator or device and run (▶️).

No extra setup or network is required for the core demo. On first run, the app will ask for camera permission so you can see yourself while brushing. If the prompt does not appear, add `NSCameraUsageDescription` to your app target’s Info in Xcode.

---

## Project Structure

- `Package.swift` — Swift package and app configuration (auto-generated).
- `MyApp.swift` — App entry point.
- `ContentView.swift` — Tab container (Brush | History).
- `BrushView.swift` — Main brushing screen: camera preview, timer, Start/Done, goal bar, “Great job!” card.
- `CameraPreviewView.swift` — Front-camera preview (AVFoundation) for SwiftUI.
- `HistoryView.swift` — Streak card, stats (avg duration, total sessions), recent sessions with star rating.
- `RewardsView.swift` — Placeholder for the Rewards tab (gems + “Coming soon”).
- `Theme.swift` — Colors and gradients matching the design; `StarRatingView` for 1–3 stars.
- `BrushingRecord.swift` — Model for one brushing session (start/end, duration, star count).
- `BrushingStore.swift` — Persists records to a JSON file; provides today count, streak, average duration.
- `Info.plist` — Camera usage description for the brushing preview.

---

## Notes for Submission

- Keep total uncompressed size **under 25 MB** when adding images, audio, or 3D assets.
- All user-facing strings and any voiceover must be in **English**.
- Test on a recent iOS/iPadOS (and Swift Playgrounds if applicable) before submitting.

---

## License & Third-Party Code

All code in this repository is original for the Swift Student Challenge. Any use of open-source or third-party code will be declared in the official SSC submission form.
