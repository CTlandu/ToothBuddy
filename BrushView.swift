import SwiftUI
import AVFoundation
import os
import ToothBuddyCore

struct BrushView: View {
    @StateObject private var store = BrushingStore.shared
    @StateObject private var zoneMonitor = BrushingZoneMonitor.shared
    @StateObject private var gamification = GamificationStore.shared
    @StateObject private var voiceCoach = VoiceCoach.shared
    @StateObject private var profiles = ProfileStore.shared
    @StateObject private var intentBridge = BrushingIntentBridge.shared
    @StateObject private var prefs = PreferencesStore.shared
    /// Spec 05 §6.1 — the active profile's experience mode (per-profile; a kid sibling
    /// on the same device is unaffected). Drives the calm adult presentation.
    private var isAdult: Bool { profiles.activeProfile?.mode == .adult }
    /// U5 — smart-mirror (camera visual) vs audio-first (eyes-free). Drives the brushing UI.
    private var isMirror: Bool { prefs.sessionMode == .mirror }
    /// Spec 05 §6.1 — the calm "morning ✓ / evening ✓" summary shown instead of stars
    /// for an adult profile. Derived from the active profile's records (today).
    private var adultSlotSummary: String {
        let cal = Calendar.current
        let today0 = cal.startOfDay(for: Date())
        var am = false, pm = false
        for r in store.records where cal.startOfDay(for: r.startDate) == today0 {
            switch SessionSlot.slot(for: r.startDate, boundaryHour: 12, calendar: cal) {
            case .morning: am = true
            case .evening: pm = true
            }
        }
        return "Morning \(am ? "✓" : "—")   ·   Evening \(pm ? "✓" : "—")"
    }
    @State private var isBrushing = false
    @State private var startDate: Date?
    @State private var elapsedSeconds = 0
    @State private var timer: Timer?
    /// Spec 03 §5.3 — varying spoken content for this session (content/encourage cues
    /// only; quadrant guidance stays with zoneMonitor to avoid overlap).
    @State private var sessionCues: [ScriptCue] = []
    @State private var spokenCueTimes: Set<Int> = []
    @State private var showDoneSheet = false
    @State private var doneSheetRecord: BrushingRecord?
    /// True once camera permission is granted so the preview view gets a valid session.
    @State private var cameraAuthorized = false
    /// Quality audit 2026-05-28 / Plan U2 — interval state for the whole brushing
    /// session (begin in `startBrushing`, end in `stopBrushing`). Visible in
    /// Instruments → Points of Interest as "BrushingSession".
    @State private var sessionSignpost: OSSignpostIntervalState?

    var body: some View {
        VStack(spacing: 0) {
            if !isBrushing {
                goalBar
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            rotatingTipSection
            cameraSection
            if isBrushing {
                timerSection
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
            }
            buttonSection
                .padding(.bottom, 12)
            Spacer()
        }
        .padding(.top, 8)
        .padding(.horizontal, 18)
        // Spec 05 §6.3 — StartBrushingIntent: begin a session once, then clear the
        // request. Handles both a warm app (onChange) and a cold launch (onAppear).
        .onChange(of: intentBridge.startRequested) { _, _ in handleIntentStart() }
        .onAppear { handleIntentStart() }
        .onAppear {
            tipStartDate = Date()
            tipRotationTimer?.invalidate()
            tipRotationTimer = Timer.scheduledTimer(withTimeInterval: Self.tipDuration, repeats: true) { _ in
                Task { @MainActor in
                    // Advance through the shuffled queue; reshuffle when exhausted.
                    let next = queuePosition + 1
                    if next >= shuffledQueue.count {
                        shuffledQueue = Array(0..<Self.brushTips.count).shuffled()
                        queuePosition = 0
                    } else {
                        queuePosition = next
                    }
                    tipStartDate = Date()
                }
            }
            RunLoop.main.add(tipRotationTimer!, forMode: .common)
        }
        .onDisappear {
            tipRotationTimer?.invalidate()
            tipRotationTimer = nil
        }
        .animation(.easeOut(duration: 0.35), value: isBrushing)
        .onChange(of: zoneMonitor.currentZone) { _, newZone in
            if let zone = newZone {
                SoundManager.zoneChanged()
                voiceCoach.speak(zone.announcement)
            }
        }
        .sheet(isPresented: $showDoneSheet) {
            if let record = doneSheetRecord {
                ZStack {
                    Duo.pageBackground.ignoresSafeArea()
                    DoneResultSheet(record: record, isAdult: isAdult,
                                    slotSummary: adultSlotSummary,
                                    onDismiss: { showDoneSheet = false }, onDelete: {
                        store.deleteRecord(id: record.id)
                        showDoneSheet = false
                    })
                    .padding(.top, 8)
                }
                .presentationDetents([.height(560)])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - 100 fun facts, each ≤ 47 characters so they fit in 2 lines at large font
    private static let brushTips: [String] = [
        // Teeth (20)
        "Enamel is the hardest substance you make! 🦷",
        "Your teeth are as unique as fingerprints!",
        "Sharks grow up to 50,000 teeth per life!",
        "Enamel can't heal — so protect it daily!",
        "Egyptians brushed with crushed rock salt! 😬",
        "The first bristle toothbrush was made 1498!",
        "Elephants grow 6 full sets of teeth! 🐘",
        "A snail's tongue has 25,000 tiny teeth! 🐌",
        "Plover birds clean crocodile teeth for free!",
        "Replace your toothbrush every 3 months!",
        "Plaque hardens into tartar in 24 hours!",
        "Mouth bacteria double every 20 minutes!",
        "Sugar feeds bacteria that erode enamel!",
        "Water is the best drink for teeth! 💧",
        "Teeth can reveal your age within 3 years!",
        "'Dentist' comes from the Latin word 'dens'.",
        "Toothpaste once came in jars, not tubes!",
        "Tooth decay is the world's most common disease!",
        "Cows have no upper front teeth — just gum!",
        "You'll spend ~38 days brushing in your life!",
        // Body (25)
        "Stomach acid can slowly dissolve metal! ⚗️",
        "Babies have ~270 bones; adults have 206!",
        "Your heart beats 100,000 times a day! 💓",
        "Your small intestine is 6 metres long!",
        "You produce 1–2 litres of saliva a day!",
        "Saliva neutralises acid to protect teeth!",
        "Fingernails grow 4× faster than toenails!",
        "Humans can detect over a trillion scents! 👃",
        "Eyes can spot 10 million different colours!",
        "Humans are the only animals with a chin!",
        "Yawning is contagious — did you just yawn? 🥱",
        "Humans glow very faintly in the dark!",
        "Your brain keeps developing until age 25!",
        "Short-term memory holds ~7 items at once!",
        "Your heart is about the size of your fist!",
        "Your lungs have the area of a tennis court!",
        "Babies are born without kneecaps!",
        "Taste buds live only about 10 days!",
        "You share 60% of your DNA with a banana! 🍌",
        "Every atom in your body was once in a star! ✨",
        "Human bones beat concrete in strength!",
        "Ice cream headaches hit the roof of your mouth!",
        "You make 100,000 antibodies every second!",
        "Your brain uses 20% of your body's energy!",
        "Your DNA uncoiled would stretch 2 metres!",
        // Nature & Animals (25)
        "3,000-year-old tomb honey was still edible!",
        "A flamingo group is a 'flamboyance'! 🦩",
        "Octopuses have 3 hearts and blue blood! 🐙",
        "Sea otters hold hands while sleeping! 🦦",
        "Butterflies taste with their feet! 🦋",
        "Trees share nutrients via underground fungi!",
        "Cats lack the gene for tasting sweetness! 🐱",
        "Wombat poop is cube-shaped to avoid rolling!",
        "Giraffes sleep just 30 minutes a day!",
        "The platypus lays eggs and uses venom! 🦆",
        "Dolphins use unique whistles as their names! 🐬",
        "Elephants are known to mourn their dead!",
        "Plants warn each other with airborne signals!",
        "A chameleon's tongue strikes in 0.07 seconds!",
        "Crows remember specific human faces!",
        "Mantis shrimps punch with bullet speed! 🦐",
        "Sea cucumbers breathe through their posteriors!",
        "Pigeons can recognise themselves in mirrors!",
        "Sponges are animals with no brain or heart!",
        "A blue whale's tongue weighs one elephant! 🐋",
        "One clam was found to be 507 years old!",
        "A group of owls is called a parliament! 🦉",
        "Polar bear fur is colorless, not white!",
        "Hippos sweat a natural sunscreen! 🦛",
        "Blue whales have no teeth — they filter krill!",
        // Science & Space (15)
        "Lightning is 5x hotter than the Sun's surface! ⚡",
        "1.3 million Earths fit inside the Sun! ☀️",
        "Sunlight takes 8 minutes to reach Earth!",
        "On HD 189733b, it rains sideways glass!",
        "Neutron stars can spin 700 times per second!",
        "Near a black hole, time itself slows down!",
        "Water can boil and freeze at the same time!",
        "Sound travels 4x faster in water than air!",
        "A Mars day is only 40 minutes longer than ours!",
        "Cleopatra is closer to now than to pyramids!",
        "T. Rex lived closer to now than to Stegosaurus!",
        "50% of Earth's oxygen comes from plankton!",
        "Stars outnumber all grains of sand on Earth!",
        "The Great Wall used rice paste as mortar!",
        "The smell of rain has a name: petrichor! 🌧",
        // Medicine & Health (15)
        "Penicillin was discovered by accident from mold!",
        "Fluoride in toothpaste strengthens enamel!",
        "Lack of vitamin C loosens teeth — it's scurvy!",
        "The first X-ray taken was of a human hand!",
        "Aspirin comes from willow tree bark! 🌿",
        "The first vaccine targeted smallpox in 1796!",
        "LASIK uses a laser thinner than a human hair!",
        "Your gut bacteria outnumber Milky Way stars!",
        "Your appendix may protect good gut bacteria!",
        "Most body cells are replaced every 7–10 years!",
        "2 min of brushing removes 39,000 bacteria!",
        "Sugarless gum after meals neutralises acid!",
        "Bees visit 2 million flowers per lb of honey! 🐝",
        "Your body makes new red blood cells each second!",
        "Your enamel is as thin as an eggshell!",
    ]

    // Shuffled queue ensures no repeat until all 100 facts have been shown once.
    @State private var shuffledQueue: [Int] = Array(0..<brushTips.count).shuffled()
    @State private var queuePosition: Int = 0

    private var currentTipIndex: Int { shuffledQueue[queuePosition] }
    @State private var tipRotationTimer: Timer?
    /// When the current tip started, used for the countdown ring.
    @State private var tipStartDate = Date()
    private static let tipDuration: Double = 6
    /// Drives the pulsing animation on the LIVE red dot.
    @State private var liveDotPulse = false

    private var rotatingTipSection: some View {
        HStack(alignment: .center, spacing: isBrushing ? 14 : 10) {
            Text(Self.brushTips[currentTipIndex])
                .id(currentTipIndex)
                .font(.system(size: isBrushing ? 22 : 15, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(isBrushing ? .center : .leading)
                .lineLimit(2)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
                .animation(.easeInOut(duration: 0.35), value: queuePosition)
                .frame(maxWidth: .infinity,
                       minHeight: isBrushing ? 62 : 42,
                       maxHeight: isBrushing ? 62 : 42,
                       alignment: isBrushing ? .center : .leading)

            TimelineView(.animation(minimumInterval: 0.05)) { context in
                let elapsed = context.date.timeIntervalSince(tipStartDate)
                let progress = max(0, min(1, elapsed / Self.tipDuration))
                ZStack {
                    Circle()
                        .stroke(Color.black.opacity(0.12), lineWidth: isBrushing ? 3 : 2.5)
                    Circle()
                        .trim(from: 0, to: 1 - progress)
                        .stroke(Theme.accentBlue, style: StrokeStyle(lineWidth: isBrushing ? 3 : 2.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: isBrushing ? 28 : 22, height: isBrushing ? 28 : 22)
                .animation(.linear(duration: 0.05), value: progress)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 14)
        .padding(.vertical, isBrushing ? 14 : 8)
        .scaleEffect(isBrushing ? 1 : 0.92)
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: isBrushing)
        .animation(.easeInOut(duration: 0.35), value: queuePosition)
    }

    private var cameraSection: some View {
        ZStack(alignment: .bottom) {
            // Chunky Duo-style depth shadow (replaces the prior soft black blur)
            RoundedRectangle(cornerRadius: 32)
                .fill(Duo.ink)
                .offset(y: 6)

            // Gradient background (cream when idle, soft rose when brushing)
            RoundedRectangle(cornerRadius: 32)
                .fill(Theme.cameraGradient(brushing: isBrushing))
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Duo.ink, lineWidth: 2)
                )

            // Live camera preview ONLY while brushing — idle state shows BuddyView
            // (no point pointing the camera at a not-yet-brushing user).
            if cameraAuthorized, isBrushing, isMirror {
                CameraPreviewView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .allowsHitTesting(false)
            }

            // Sugar Bugs game (Spec 04.3) — U5/U8: shown in mirror mode when the user
            // keeps the game on (Settings), no longer gated by kid/adult.
            if isBrushing, isMirror, prefs.gameEnabled {
                BrushGameOverlay()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .allowsHitTesting(false)
            }

            if isBrushing, isMirror {
                // LIVE pill + disclaimer aligned to top
                VStack(spacing: 5) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(red: 248/255, green: 113/255, blue: 113/255))
                            .frame(width: 8, height: 8)
                            .opacity(liveDotPulse ? 1.0 : 0.15)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                                    liveDotPulse = true
                                }
                            }
                            .onDisappear { liveDotPulse = false }
                        Text("LIVE")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(Theme.textPrimary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.85))
                    .clipShape(Capsule())

                    Text("Preview only — not saved to cloud or device.")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.textPrimary.opacity(0.65))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 14)
                .frame(maxHeight: .infinity, alignment: .top)
            } else if isBrushing {
                audioGuideView
            } else {
                // Idle hero — BuddyView mascot centered, camera-off message below.
                VStack(spacing: 16) {
                    BuddyView()
                        .frame(width: 140, height: 160)
                    Text("Ready to brush?")
                        .font(Duo.Fnt.ebd(22))
                        .tracking(0.3)
                        .foregroundColor(Duo.ink)
                    Text("Tap START to begin a 2-min session.")
                        .font(Duo.Fnt.sbd(13))
                        .foregroundColor(Duo.muted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Bottom of camera: zone instruction + mute toggle when brushing only.
            VStack(spacing: 8) {
                if isBrushing, isMirror, let zone = zoneMonitor.currentZone {
                    HStack(spacing: 8) {
                        Text(zone.prompt)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.92))
                                    .shadow(color: Color.black.opacity(0.08), radius: 6, y: 2)
                            )

                        // Mute / unmute button
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                voiceCoach.isMuted.toggle()
                            }
                        } label: {
                            Image(systemName: voiceCoach.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(voiceCoach.isMuted ? Theme.textMuted : Theme.textPrimary)
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.92))
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.08), radius: 4, y: 1)
                        }
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .frame(height: 400)
        .padding(.bottom, 16)
        .animation(.easeInOut(duration: 0.4), value: isBrushing)
        .onAppear { requestCameraIfNeeded() }
    }

    /// U5 — eyes-free brushing view: no camera, no game. Big mascot + current-zone prompt
    /// + reassurance that the phone can be set down; voice does the guiding.
    private var audioGuideView: some View {
        VStack(spacing: 18) {
            BuddyView()
                .frame(width: 120, height: 138)
            if let zone = zoneMonitor.currentZone {
                Text(zone.prompt)
                    .font(Duo.Fnt.ebd(20))
                    .tracking(0.2)
                    .foregroundColor(Duo.ink)
                    .multilineTextAlignment(.center)
                    .contentTransition(.opacity)
            }
            Text("Eyes-free — set your phone down, I'll guide you by voice.")
                .font(Duo.Fnt.sbd(13))
                .foregroundColor(Duo.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { voiceCoach.isMuted.toggle() }
            } label: {
                Image(systemName: voiceCoach.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(voiceCoach.isMuted ? Theme.textMuted : Theme.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.92))
                    .clipShape(Circle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
    }

    private func requestCameraIfNeeded() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraAuthorized = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { cameraAuthorized = granted }
            }
        default:
            break
        }
    }

    private var goalBar: some View {
        let sessionsToday = store.recordsTodayCount
        let goal = 2
        return DuoCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("TODAY'S GOAL")
                        .font(Duo.Fnt.ebd(11))
                        .tracking(0.8)
                        .foregroundColor(Duo.ink)
                    Spacer()
                    DuoBadge(text: "LV \(gamification.level)",
                             leadingEmoji: "🌱",
                             role: .primary)
                    Text("\(min(sessionsToday, goal))/\(goal)")
                        .font(Duo.Fnt.ebd(12))
                        .foregroundColor(Duo.muted)
                        .padding(.leading, 6)
                }
                DuoProgressPips(completed: min(sessionsToday, goal), total: goal)
                Text("A.M. · P.M.")
                    .font(Duo.Fnt.sbd(11))
                    .foregroundColor(Duo.muted)
            }
        }
        .padding(.bottom, 18)
        .animation(.easeOut(duration: 0.5), value: store.recordsTodayCount)
    }

    private var buttonSection: some View {
        DuoButton(
            isBrushing ? "DONE BRUSHING!" : "START BRUSHING!",
            role: isBrushing ? .secondary : .primary
        ) {
            if isBrushing {
                stopBrushing()
            } else {
                startBrushing()
            }
        }
    }

    // MARK: - Timer display between camera and button

    private var timerSection: some View {
        HStack(spacing: 12) {
            Text(formattedTime(elapsedSeconds))
                .font(.system(size: 48, weight: .bold, design: .rounded).monospacedDigit())
                .tracking(2)
                .foregroundColor(timerColor(for: elapsedSeconds))
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.4), value: elapsedSeconds)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    /// Smoothly interpolates the timer color: red (0s) → yellow (60s) → green (120s+).
    private func timerColor(for seconds: Int) -> Color {
        let s = Double(max(0, seconds))
        if s <= 60 {
            let t = s / 60.0
            return Color(
                red: 1.0,
                green: lerp(0.23, 0.77, t),
                blue: lerp(0.19, 0.0, t)
            )
        } else if s <= 120 {
            let t = (s - 60) / 60.0
            return Color(
                red: lerp(1.0, 0.20, t),
                green: lerp(0.77, 0.78, t),
                blue: lerp(0.0, 0.35, t)
            )
        } else {
            return Color(red: 0.20, green: 0.78, blue: 0.35)
        }
    }

    private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + (b - a) * min(1, max(0, t))
    }

    private func formattedTime(_ totalSeconds: Int) -> String {
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    /// Consume a pending StartBrushingIntent (Spec 05 §6.3). Idempotent & crash-safe:
    /// only starts when not already brushing; always clears the flag.
    private func handleIntentStart() {
        guard intentBridge.startRequested else { return }
        intentBridge.consume()
        if !isBrushing { startBrushing() }
    }

    private func startBrushing() {
        // Quality audit 2026-05-28 / Plan U2 — open a signpost interval covering the
        // entire session. Paired in stopBrushing().
        sessionSignpost = appSignposter.beginInterval("BrushingSession")
        SoundManager.startBrushing()
        startDate = Date()
        isBrushing = true
        store.isBrushing = true
        elapsedSeconds = 0
        zoneMonitor.targetSeconds = prefs.targetSeconds
        zoneMonitor.useCamera = isMirror   // U5 — audio-first mode never opens the camera
        voiceCoach.isMuted = !prefs.voiceEnabled
        zoneMonitor.startMonitoring()
        // Spec 05 §6.5 — Live Activity (additive; no-op if unsupported/disabled).
        BrushingLiveActivity.start(
            profileName: profiles.activeProfile?.name ?? "ToothBuddy",
            totalSeconds: prefs.targetSeconds)
        // Build this session's varying content timeline (Spec 03). Tone now comes from
        // Settings (U7), not the profile's kid/adult mode.
        let tone = prefs.contentTone
        let cal = Calendar.current
        let dayIdx = Int(cal.startOfDay(for: Date()).timeIntervalSinceReferenceDate / 86_400)
        let kinds: [ContentKind] = tone == .essentials
            ? [.tip] : [.fact, .joke, .storyBeat, .tip]
        let kind = kinds[((dayIdx % kinds.count) + kinds.count) % kinds.count]
        let content = ContentSelector.pick(kind: kind, now: Date(),
                                           history: ContentHistoryStore.shared.recent(),
                                           tone: tone, calendar: cal)
        sessionCues = SessionScript.build(durationSeconds: prefs.targetSeconds, tone: tone,
                                          content: content, calendar: cal)
        spokenCueTimes = []
        if let cid = content?.id { ContentHistoryStore.shared.record(cid) }
        // Announce the first zone immediately after a short delay so the TTS doesn't overlap
        // with any system sound from the button tap.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [self] in
            if let zone = zoneMonitor.currentZone {
                voiceCoach.speak(zone.announcement)
            }
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                guard let start = startDate else { return }
                // U4 — prescribed route done (all zones brushed to target): wrap up.
                if zoneMonitor.sessionIsComplete { stopBrushing(); return }
                elapsedSeconds = Int(Date().timeIntervalSince(start))
                // Spec 05 §6.5 — refresh the Live Activity every 5s (chatty-safe).
                if elapsedSeconds % 5 == 0 {
                    BrushingLiveActivity.update(
                        secondsRemaining: max(0, prefs.targetSeconds - elapsedSeconds),
                        zoneHint: zoneMonitor.currentZone?.announcement ?? "Keep brushing")
                }
                for cue in sessionCues
                where cue.atSecond == elapsedSeconds
                    && (cue.kind == .content || cue.kind == .encourage)
                    && !spokenCueTimes.contains(cue.atSecond) {
                    spokenCueTimes.insert(cue.atSecond)
                    voiceCoach.speak(cue.text)
                }
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func stopBrushing() {
        // Quality audit 2026-05-28 / Plan U2 — close the session signpost interval.
        if let s = sessionSignpost {
            appSignposter.endInterval("BrushingSession", s)
            sessionSignpost = nil
        }
        SoundManager.doneBrushing()
        timer?.invalidate()
        timer = nil
        // U4 — speak the wrap-up line (no-op if voice off), instead of an abrupt cut.
        if let wrap = sessionCues.first(where: { $0.kind == .wrap }) {
            voiceCoach.speak(wrap.text)
        } else {
            voiceCoach.stop()
        }
        zoneMonitor.stopMonitoring()
        BrushingLiveActivity.end()   // Spec 05 §6.5 — never a stuck activity
        store.isBrushing = false
        guard let start = startDate else { return }
        // U3 — persist the session's quality signals from the monitor (read after stop;
        // the monitor keeps its accumulators until the next startMonitoring()).
        store.recordSession(start: start, end: Date(),
                            activeSeconds: zoneMonitor.sessionActiveSeconds,
                            targetSeconds: zoneMonitor.targetSeconds,
                            coverage: zoneMonitor.sessionCoverage,
                            cameraVerified: zoneMonitor.sessionCameraVerified,
                            guidanceMode: zoneMonitor.sessionGuidanceMode)
        // Contextual permission (after first completed session) + refresh reminders. Spec 01 §4.7.
        NotificationScheduler.shared.requestAuthorizationIfNeeded()
        NotificationScheduler.shared.reschedule(records: store.records, streak: store.streak)
        doneSheetRecord = store.records.first
        showDoneSheet = true
        startDate = nil
        isBrushing = false
        elapsedSeconds = 0
        sessionCues = []
        spokenCueTimes = []
    }
}

// MARK: - Done result popup: Duo-style chunky card with Foam celebration
private struct DoneResultSheet: View {
    let record: BrushingRecord
    /// Spec 05 §6.1 — adult ⇒ no stars/confetti, calm copy, quiet slot summary.
    var isAdult: Bool = false
    var slotSummary: String = ""
    let onDismiss: () -> Void
    let onDelete: () -> Void
    @State private var cardAppeared = false

    private var stars: Int { record.starCount }
    private var duration: Int { record.durationSeconds }

    private var title: String {
        if isAdult { return String(localized: "Brushing logged") }
        switch stars {
        case 3: return String(localized: "Perfect!")
        case 2: return String(localized: "Good job!")
        default: return String(localized: "Every brush counts!")
        }
    }

    private var titleColor: Color {
        if isAdult { return Duo.ink }
        switch stars {
        case 3: return Duo.green
        case 2: return Duo.blue
        default: return Duo.yellowShadow
        }
    }

    private var message: String {
        if isAdult {
            return duration >= 120
                ? String(localized: "Logged a full two-minute session.")
                : String(localized: "Logged. Aim for two minutes when you can.")
        }
        switch stars {
        case 3: return String(localized: "You brushed for 2 minutes. That's the recommended time.")
        case 2: return String(localized: "You're building a great habit. Keep it up!")
        default: return String(localized: "Try for 2 minutes next time. You've got this!")
        }
    }

    private var funFact: String {
        if isAdult { return slotSummary }
        switch stars {
        case 3: return String(localized: "Did you know? Tooth enamel is the hardest part of your body.")
        case 2: return String(localized: "Fun fact: Kids have 20 baby teeth. Taking care of them now helps your adult teeth.")
        default: return String(localized: "Tip: Brushing twice a day helps keep cavities away.")
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            // Hero — Foam celebration for kid (3 stars = biggest), calm Buddy for adult.
            if isAdult {
                BuddyView()
                    .frame(width: 70, height: 80)
            } else {
                FoamView()
                    .frame(width: stars >= 3 ? 110 : 90,
                           height: stars >= 3 ? 110 : 90)
            }

            Text(title)
                .font(Duo.Fnt.ebd(26))
                .tracking(0.3)
                .foregroundColor(titleColor)

            Text(formattedTime)
                .font(Duo.Fnt.ebd(40).monospacedDigit())
                .tracking(2)
                .foregroundColor(Duo.ink)

            if !isAdult {
                StarRatingView(count: stars, size: 26)
            }

            VStack(spacing: 6) {
                Text(message)
                    .font(Duo.Fnt.sbd(14))
                    .foregroundColor(Duo.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(funFact)
                    .font(Duo.Fnt.reg(12))
                    .foregroundColor(Duo.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 8)

            DuoButton("DONE", role: isAdult ? .secondary : .primary) {
                SoundManager.sheetDismissed()
                onDismiss()
            }
            .padding(.top, 4)

            Button("Delete this record", action: onDelete)
                .font(Duo.Fnt.sbd(12))
                .foregroundColor(Duo.red)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Duo.ink)
                    .offset(y: Duo.depthOffset)
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Duo.ink, lineWidth: Duo.outlineWidth)
                    )
            }
        )
        .padding(.horizontal, 20)
        .scaleEffect(cardAppeared ? 1 : 0.9)
        .opacity(cardAppeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                cardAppeared = true
            }
        }
    }

    private var formattedTime: String {
        let m = duration / 60
        let s = duration % 60
        return String(format: "%02d:%02d", m, s)
    }
}
