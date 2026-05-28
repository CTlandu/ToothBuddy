# TestFlight + App Store Submission Checklist

Plan U11–U13 (`docs/plans/2026-05-28-002-feat-app-store-launch-plan.md`).

This is the user-driven sequence — items that **you** (the maintainer) execute. ce-work cannot do these because they involve Apple ID interactions, signing certificates, and Apple Web UI.

---

## Pre-upload (5 min — before opening Xcode Organizer)

- [ ] Replace placeholder URLs in:
  - `Support/Info.plist` — no URLs here (it's all done in xcstrings + listing)
  - `docs/app-store-listing.md` — replace `[VERCEL: https://toothbuddy.app/privacy]` and `[VERCEL: https://toothbuddy.app/support]` with real Vercel-hosted URLs
  - `docs/legal/privacy-policy.md` — confirm contact email
  - `docs/legal/support.md` — confirm contact email
  - Push the two markdown sources to your Vercel repo and deploy
- [ ] Verify Vercel pages are publicly reachable (try in a private browsing window)
- [ ] Run `bash scripts/audit.sh` — must pass 0 warning
- [ ] Confirm `MARKETING_VERSION` in `project.yml` = `1.0` (it is)
- [ ] Confirm `CURRENT_PROJECT_VERSION` = build number (start at `1`, bump for each upload)
- [ ] App icon, launch screen visible in simulator (cold launch shows coral background → app)
- [ ] Cold launch in zh-Hans simulator locale → main UI in Chinese
- [ ] Brushing session triggers Live Activity (on real device — sim doesn't show DI)

---

## Archive + upload (15 min)

1. **Open Xcode** (not just CLI):
   ```bash
   xcodegen generate
   open ToothBuddy.xcodeproj
   ```

2. **Product → Destination → Any iOS Device (arm64)**

3. **Product → Archive** (takes 1-3 min)

4. **Organizer pops up** — select the new archive

5. **Distribute App** → App Store Connect → Upload

6. Sign with **automatic signing** (DEVELOPMENT_TEAM 89A8S223WV is already in project.yml — no manual step)

7. Tap Upload, wait for "Upload Successful" (~5 min)

8. **Wait 10-20 min** for App Store Connect to process the build. Refresh https://appstoreconnect.apple.com → My Apps → ToothBuddy → TestFlight tab. The build will show "Processing..." then become available.

---

## TestFlight Internal Testing (1-2 days)

1. App Store Connect → ToothBuddy → **TestFlight** tab → **Internal Testing** group
2. **Invite yourself** (Apple ID) + 1-2 friends/family
3. They install **TestFlight app** from App Store, then accept the invite
4. Run through the smoke checklist below on each tester's device

### Tester smoke checklist (per device)

- [ ] Cold launch — app icon shows on home screen, launch screen is coral (not black)
- [ ] Onboarding — 4 slides + ready, all text shows correctly
- [ ] Create profile — name + color + symbol + mode flows work
- [ ] Brushing session — camera permission, Vision overlay, Sugar Bugs, complete session, Done sheet stars
- [ ] Live Activity — appears on Lock Screen + Dynamic Island during brushing
- [ ] Streak appears on history
- [ ] Switch language to zh-Hans (iOS Settings → Language)
- [ ] Repeat brushing session — all UI text in Chinese
- [ ] HealthKit grant (adult profile, History → Save brushing to Apple Health)
- [ ] Verify session appears in Apple Health → Browse → Other → Toothbrushing
- [ ] Siri: "Hey Siri, I brushed my teeth in ToothBuddy" → logs session
- [ ] Siri (zh): "Hey Siri, 我用 ToothBuddy 刷过牙了" → logs session
- [ ] Add Widget to home screen → shows streak

If any check fails, fix and ship a new build (`CURRENT_PROJECT_VERSION` bumped to `2`).

---

## App Preview video (U11, optional but recommended)

If recording one (15-30s):

1. Real device (better than sim for fluidity)
2. Settings → Date/Time → off auto, 9:41
3. Settings → Control Center → screen recording on
4. Open app → main screen
5. Start screen recording
6. Tap Start Brushing → wait for Vision overlay + Sugar Bugs to engage
7. Show Live Activity (Lock screen briefly)
8. Done → stars
9. Stop recording → AirDrop to Mac → trim in QuickTime

Upload to App Store Connect → App Information → App Preview & Screenshots → Add App Preview for iPhone 6.9" (and iPad 13" if you have that device or render).

---

## External TestFlight (optional, after Internal looks good)

Only do this if you want broader testing before App Store submission:

1. TestFlight tab → **External Testing** → create group
2. Add tester emails
3. **First external build needs Beta App Review** (24-48 hr by Apple)
4. Subsequent builds for same external group don't need Beta App Review

You can skip External entirely and go straight to App Store review.

---

## App Store Review submission (final step)

1. App Store Connect → ToothBuddy → **App Store** tab → **1.0 Prepare for Submission**

2. Fill in everything from `docs/app-store-listing.md`:
   - General Info / Pricing / Privacy (Nutrition Label = all Data Not Collected)
   - English (en-US) App Information + Version Info
   - Add language → Chinese (Simplified) → fill zh-Hans App Information + Version Info
   - Upload screenshots (iPhone 6.9" + iPad 13" × en + zh-Hans)
   - Upload App Preview video (en, optional zh-Hans)
   - Build → select the TestFlight build from earlier

3. **App Review Information**:
   - Sign-in required: No
   - Demo account: not applicable
   - Notes: paste entire content of `docs/app-store-review-notes.md`
   - Contact info: your phone + email

4. **Export Compliance**: No encryption beyond standard iOS

5. **Content Rights**: does not contain third-party content

6. **Advertising Identifier (IDFA)**: No

7. **Regulated Medical Device Declaration**: **No** (matches Category change + app definition)

8. **Submission options**:
   - "Manually release this version after approval" (recommended — you choose go-live date)

9. **Submit for Review** → confirm

10. Wait **24-48 hr** for App Review (usually faster). Status will move through:
    - "Waiting for Review" (in queue)
    - "In Review" (someone is looking at it; can be quick)
    - "Pending Developer Release" (approved! release when ready)
    - OR "Rejected" with feedback

### Common rejection paths + responses

| Rejection reason | Response |
|---|---|
| Guideline 4.2 minimum functionality | Reply citing Live Activity + Vision + Sugar Bugs + adaptive notifications as non-trivial value-add features. Lead screenshot 1 must show camera overlay clearly. |
| Guideline 5.1.1 incomplete usage description | Strengthen the specific permission's `NS*UsageDescription` in Info.plist with what / when / where info; resubmit. |
| Guideline 5.1.3 HealthKit | Reply with: "This app uses HealthKit write-only via `requestAuthorization(toShare:read:nil)`. No read scopes are ever requested. The user's brushing sessions are saved as `HKCategoryTypeIdentifier.toothbrushingEvent`. Full details in `docs/app-store-review-notes.md` already provided." |
| Privacy nutrition label inaccuracy | Double-check the 4 sections all say Data Not Collected. The HealthKit write goes to user's own Apple Health DB on their device → does not count as "collected" per Apple guidance. |
| Missing privacy policy URL | URL placeholder still in there — replace with real Vercel URL |
| Screenshot/marketing content not in app | Trace which screenshot has a feature not in the build. Replace with a real screenshot. |

---

## Post-approval

1. **Manual Release**: App Store Connect → ToothBuddy → Pending Developer Release → tap Release this version
2. Within ~24 hr, app is live and searchable
3. Take a screenshot of "Available on the App Store" — celebrate!

---

## After 1.0 ships

Write `docs/launch-postmortem.md`:
- Timeline (Plan start → TestFlight → submission → live)
- What went unexpected
- Apple review specific notes (any reject + recover patterns)
- What to do for 1.1 (deferred features from this plan)
