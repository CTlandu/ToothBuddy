# App Store Screenshots

Plan U10 (`docs/plans/2026-05-28-002-feat-app-store-launch-plan.md`).

## Required sets

App Store Connect requires (as of 2026):

| Set | Pixel size | Devices it auto-scales to |
|-----|-----------|--------------------------|
| iPhone 6.9" | 1320 × 2868 (portrait) | iPhone 16 Pro Max + auto-scales smaller |
| iPad 13" | 2064 × 2752 (portrait) | iPad Pro 13" + auto-scales smaller |

Quantity per set per locale: 3-10 screenshots. We aim for **5 scenes × 2 locales × 2 device sets = 20 PNGs**.

Locales: `en` (English) + `zh-Hans` (Simplified Chinese). Set the simulator language before each capture batch.

## Capture procedure

### One-time simulator setup

1. **iPhone 16 Pro Max** simulator (`xcrun simctl create "iPhone 16 Pro Max"` if missing)
2. **iPad Pro 13-inch (M4)** simulator
3. Both: Settings → Date & Time → off auto, set to **2026-05-28 09:41**
4. Both: Settings → Battery Percentage → on, full battery, Wi-Fi connected (use `simctl status_bar` for clean status bar)

### Status bar

```bash
xcrun simctl status_bar booted override \
  --time "9:41" \
  --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode notSupported \
  --batteryState charged --batteryLevel 100
```

### Per-locale switch

iOS Simulator → Settings → General → Language & Region → iPhone Language → set to English / 简体中文, then erase install state with `simctl uninstall`. Re-run app fresh.

## Scene catalog (5 scenes designed for Apple Guideline 4.2 minimum-functionality defense)

| # | Scene | What's visible | Why this scene |
|---|-------|---------------|----------------|
| 1 | Main brush + Vision + Sugar Bugs | Front-camera live, Sugar Bugs hopping near zones, HUD overlay, "Brush" button green | "Non-trivial functionality" — defeats Guideline 4.2 minimum-functionality rejections |
| 2 | Live Activity + Dynamic Island | Lock screen with Live Activity banner; Dynamic Island compact view if possible | Shows depth of Apple ecosystem integration; impressive to reviewers and users |
| 3 | Family Dashboard | 3-4 profiles, streak badges, care chips (brush head / dentist), Report menu visible | Shows family layer — main differentiator vs competitor apps |
| 4 | History + Habit Curve (adult mode) | Habit curve over 4 weeks, recent sessions list, streak header | Adult mode = calm proof-point; shows the app respects different user types |
| 5 | Tips course | Unlocked + locked lesson cards in a row, tip card peeking | Content engine — shows app has more than just timer |

## Per-scene capture steps

### Scene 1 — Main brush + Vision + Sugar Bugs

1. Open app, navigate to Brush tab
2. Make sure profile mode = kid (so Sugar Bugs shows)
3. Tap "START BRUSHING"
4. Wait ~5s for Sugar Bugs to spawn and zones to register
5. `Cmd+S` (sim) or `xcrun simctl io booted screenshot scene-1-brushing.png`

### Scene 2 — Live Activity + Dynamic Island

1. Start a brushing session (Scene 1 first)
2. Press home / lock screen
3. Take screenshot of Lock Screen with Live Activity visible
4. For Dynamic Island: press power on lock screen, capture with Dynamic Island compact view

### Scene 3 — Family Dashboard

1. Navigate to Family tab
2. Ensure ≥3 profiles exist (create with different colors)
3. Have varied streak data (use existing test data or seed manually)
4. Screenshot

### Scene 4 — History + Habit Curve

1. Switch to an adult profile (or convert one via picker)
2. Navigate to History tab
3. Screenshot showing habit curve + recent sessions

### Scene 5 — Tips course

1. Navigate to Tips tab
2. Scroll to "ORAL-HEALTH COURSE" section
3. Capture showing at least 2 unlocked + 1 locked lesson card

## File naming convention

```
docs/app-store-screenshots/iphone-69/en/scene-1-brushing.png
docs/app-store-screenshots/iphone-69/en/scene-2-live-activity.png
docs/app-store-screenshots/iphone-69/en/scene-3-family.png
docs/app-store-screenshots/iphone-69/en/scene-4-history.png
docs/app-store-screenshots/iphone-69/en/scene-5-tips.png

docs/app-store-screenshots/iphone-69/zh-Hans/scene-1-brushing.png
...

docs/app-store-screenshots/ipad-13/en/scene-1-brushing.png
...

docs/app-store-screenshots/ipad-13/zh-Hans/scene-1-brushing.png
...
```

## Avoid (Apple-documented rejection signals)

- Status bar showing real carrier name (use simctl override → no carrier)
- Status bar time other than 9:41
- Device frame mockups (Apple wants real screenshots)
- Screenshots of UI that doesn't exist in the shipped app
- Localized strings still in English when uploading the zh-Hans set
- File size > 8 MB per image — compress with `pngcrush` if needed

## Quality check

For each PNG before upload:

```bash
sips -g pixelWidth -g pixelHeight scene-N-foo.png
# Expected: pixelWidth=1320 pixelHeight=2868 (iPhone)
# Expected: pixelWidth=2064 pixelHeight=2752 (iPad)
```

## Status

- [ ] iPhone 6.9" × en × 5
- [ ] iPhone 6.9" × zh-Hans × 5
- [ ] iPad 13" × en × 5
- [ ] iPad 13" × zh-Hans × 5
