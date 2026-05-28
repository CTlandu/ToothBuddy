# ToothBuddy Support

**Version 1.0** — last updated 2026-05-28

ToothBuddy is an offline iPhone and iPad app that helps you build a twice-a-day brushing habit. No account, no network, no subscription.

If you need help, please email `colintangxy@gmail.com`. We aim to respond within 3 business days.

---

## Frequently asked questions

### How do I start a brushing session?

Tap **Start brushing** on the main screen. The camera turns on so you can see yourself; tilt your phone so your face is in the frame. The on-screen guide will hint at which tooth zone to focus on. When you're done (after ~2 minutes, or when you tap **Done**), the session is logged.

### Does ToothBuddy record me?

**No.** Camera frames are processed on your device by Apple's Vision framework and discarded immediately. ToothBuddy has no photo library access. No image data leaves your device, ever. (See the [Privacy Policy](./privacy-policy.md).)

### How do I turn on Apple Health sync?

Open History on an adult profile and tap the "Save brushing to Apple Health" row. Grant permission when iOS asks. From then on every completed session will be written to Apple Health as a tooth-brushing event. To turn it off, go to iOS Settings → Privacy & Security → Health → ToothBuddy.

ToothBuddy only **writes** to Apple Health — it never reads any of your health data.

### How do reminders work?

After your first completed session, ToothBuddy asks if you'd like reminders. It then watches when you typically brush and schedules a morning + evening reminder near your usual times. If you skip an evening, it sends a gentle "streak at risk" nudge.

All scheduling happens on your device. No push servers are involved.

### Can my whole family use one device?

Yes — go to the **Family** tab and add a profile per family member. Each profile keeps separate brushing records, streaks, achievements, and care reminders. Everyone on the device sees everyone's progress on the Family dashboard (no roles, no admin — it's a peer view).

### When will multi-device family sync work?

Cross-device sync via CloudKit is built and tested, but it's currently disabled while we work through Apple's signing requirements. We'll ship it as part of a future update.

### How do I delete my data?

- **Delete one session:** swipe left on it in History → Delete. Then "Undo" appears for ~5 seconds in case you change your mind.
- **Delete a profile:** Family tab → tap profile → Delete profile. This deletes all that profile's records.
- **Delete everything:** delete the app from your home screen. iOS removes all local data with it. If you had previously written to Apple Health, that data still lives in your Apple Health database (you control it from the Health app).

### Why does my streak look frozen even though I missed a day?

ToothBuddy uses a "forgiving streak" rule: roughly one missed day per 7-day run is forgiven without breaking your streak. Two consecutive misses do reset it. The icon on the missed day shows a freeze badge to indicate it was bridged.

### The camera shows a black screen / "Allow camera access" doesn't fire

Go to iOS Settings → ToothBuddy → Camera and make sure access is granted. If you previously denied it, this is the only path to re-grant. Force-quitting the app and restarting it also helps if the session got into a stuck state.

### Does ToothBuddy work without the camera?

Yes. If you decline camera access, ToothBuddy falls back to a timed brushing sequence (a chime every ~30 seconds guiding you through quadrants). You still get the full streak, gamification, content, and Apple Health export — only the live zone overlay is missing.

### How do I add the widget to my home screen?

Long-press an empty area of your home screen → tap the **+** in the top corner → search "ToothBuddy" → choose the size. The widget shows your current streak and today's morning/evening status. It updates automatically.

### Does ToothBuddy work with Siri?

Yes. After installing, try:

- "Hey Siri, I brushed my teeth in ToothBuddy"
- "Hey Siri, start brushing in ToothBuddy"
- "Hey Siri, what's my brushing streak in ToothBuddy"

You can also create custom Shortcuts using the same actions in the Shortcuts app.

---

## Privacy and data

Short version: **your data stays on your device.** See the full [Privacy Policy](./privacy-policy.md).

---

## Contact

Bugs, feature requests, accessibility issues, anything: `colintangxy@gmail.com`. We read every email.
