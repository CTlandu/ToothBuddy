import SwiftUI
import AVFoundation

struct BrushView: View {
    @StateObject private var store = BrushingStore.shared
    @State private var isBrushing = false
    @State private var startDate: Date?
    @State private var elapsedSeconds = 0
    @State private var timer: Timer?
    @State private var showDoneSheet = false
    @State private var doneSheetRecord: BrushingRecord?
    /// True once camera permission is granted so the preview view gets a valid session.
    @State private var cameraAuthorized = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                cameraSection
                if !isBrushing {
                    goalBar
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                buttonSection
                rotatingTipSection
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .animation(.easeOut(duration: 0.35), value: isBrushing)
        .sheet(isPresented: $showDoneSheet) {
            if let record = doneSheetRecord {
                ZStack {
                    Theme.appBackground
                        .opacity(0.95)
                        .ignoresSafeArea()
                    DoneResultSheet(record: record, onDismiss: { showDoneSheet = false }, onDelete: {
                        store.deleteRecord(id: record.id)
                        showDoneSheet = false
                    })
                    .padding(.top, 8)
                }
                .presentationDetents([.height(380)])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Rotating tips (encouragement, fun facts, reminders) for kids
    private static let brushTips: [String] = [
        "You're doing great! Keep it up! 🌟",
        "Super star brusher! ⭐",
        "Nice and gentle circles! 🫧",
        "Don't forget the back teeth!",
        "Brush the top teeth too!",
        "Get those hard-to-reach spots in the back!",
        "Did you know? Kids have 20 baby teeth.",
        "Fun fact: Tooth enamel is the hardest part of your body!",
        "Did you know? Elephants have 4 molars at a time.",
        "Fun fact: You'll have 32 teeth as an adult!",
        "Almost there—keep brushing! 💪",
        "Smile! You're taking care of your teeth! 😁",
        "Don't rush—2 minutes is perfect! ⏱️",
        "Remember to brush your tongue too!",
        "You're making your teeth happy! 🦷",
    ]

    @State private var currentTipIndex = 0
    @State private var tipRotationTimer: Timer?
    /// When the current tip started, used for the countdown ring.
    @State private var tipStartDate = Date()
    private static let tipDuration: Double = 6

    private var rotatingTipSection: some View {
        HStack(alignment: .center, spacing: isBrushing ? 14 : 10) {
            Text(Self.brushTips[currentTipIndex])
                .id(currentTipIndex)
                .font(.system(size: isBrushing ? 22 : 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(isBrushing ? .center : .leading)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
                .animation(.easeInOut(duration: 0.35), value: currentTipIndex)
                .frame(maxWidth: .infinity, alignment: isBrushing ? .center : .leading)

            // Circular countdown ring
            TimelineView(.animation(minimumInterval: 0.05)) { context in
                let elapsed = context.date.timeIntervalSince(tipStartDate)
                let progress = max(0, min(1, elapsed / Self.tipDuration))
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: isBrushing ? 3 : 2.5)
                    Circle()
                        .trim(from: 0, to: 1 - progress)
                        .stroke(Theme.accentBlue, style: StrokeStyle(lineWidth: isBrushing ? 3 : 2.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: isBrushing ? 28 : 22, height: isBrushing ? 28 : 22)
                .animation(.linear(duration: 0.05), value: progress)
            }
        }
        .frame(maxWidth: .infinity, minHeight: isBrushing ? 100 : 0)
        .padding(.horizontal, 14)
        .padding(.vertical, isBrushing ? 20 : 10)
        .padding(.top, 6)
        .animation(.easeInOut(duration: 0.35), value: isBrushing)
        .onAppear {
            tipStartDate = Date()
            tipRotationTimer = Timer.scheduledTimer(withTimeInterval: Self.tipDuration, repeats: true) { _ in
                Task { @MainActor in
                    currentTipIndex = Int.random(in: 0..<Self.brushTips.count)
                    tipStartDate = Date()
                }
            }
            RunLoop.main.add(tipRotationTimer!, forMode: .common)
        }
        .onDisappear {
            tipRotationTimer?.invalidate()
            tipRotationTimer = nil
        }
    }

    private var cameraSection: some View {
        ZStack(alignment: .bottom) {
            // Gradient background (shows behind/around camera)
            RoundedRectangle(cornerRadius: 32)
                .fill(Theme.cameraGradient(brushing: isBrushing))
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(isBrushing ? Theme.accentBlue : Color.clear, lineWidth: isBrushing ? 4 : 0)
                )
                .shadow(color: isBrushing ? Theme.accentBlue.opacity(0.5) : .black.opacity(0.4),
                        radius: isBrushing ? 20 : 16, y: isBrushing ? 6 : 8)

            // Live camera preview only when authorized; fill space so the host view gets real bounds
            if cameraAuthorized {
                CameraPreviewView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .allowsHitTesting(false)
                // Small tooth bubbles floating near the edges (like bubbles by the face)
                FloatingToothBubblesView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
            }

            if isBrushing {
                // LIVE pill + disclaimer (preview not saved)
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(red: 248/255, green: 113/255, blue: 113/255))
                            .frame(width: 8, height: 8)
                        Text("LIVE")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.18))
                    .clipShape(Capsule())
                    Text("Preview only — not saved to cloud or device.")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 14)
                .frame(maxHeight: .infinity, alignment: .top)
            } else {
                // Placeholder when not brushing
                Text("📷 Camera Preview")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.45))
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                    .frame(maxHeight: .infinity, alignment: .top)
            }

            // Bottom: timer or "Ready to brush?"
            VStack(spacing: 6) {
                if isBrushing {
                    Text(formattedTime(elapsedSeconds))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .tracking(2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                } else {
                    Text("Ready to brush?")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.textMutedStrong)
                }
            }
            .padding(.bottom, 28)
        }
        .frame(height: 400)
        .padding(.bottom, 20)
        .animation(.easeInOut(duration: 0.4), value: isBrushing)
        .onAppear { requestCameraIfNeeded() }
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
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("TODAY'S GOAL")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.textMuted)
                Spacer()
                Text("\(min(sessionsToday, goal))/\(goal) sessions")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.textMuted)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Theme.accentBlue, Color(red: 129/255, green: 140/255, blue: 248/255)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(min(sessionsToday, goal)) / CGFloat(goal))
                }
            }
            .frame(height: 10)
        }
        .padding(12)
        .background(Theme.surfaceFrost)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.surfaceFrostBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.bottom, 18)
        .animation(.easeOut(duration: 0.5), value: store.recordsTodayCount)
    }

    private var buttonSection: some View {
        Button {
            if isBrushing {
                stopBrushing()
            } else {
                startBrushing()
            }
        } label: {
            Text(isBrushing ? "Done Brushing!" : "Start Brushing!")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .tracking(1)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(isBrushing ? Theme.stopButtonGradient : Theme.startButtonGradient)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(
                    color: (isBrushing ? Theme.stopButtonStart : Theme.startButtonEnd).opacity(0.5),
                    radius: 15,
                    y: 6
                )
        }
        .buttonStyle(BounceButtonStyle())
    }

    private func formattedTime(_ totalSeconds: Int) -> String {
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func startBrushing() {
        startDate = Date()
        isBrushing = true
        elapsedSeconds = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                guard let start = startDate else { return }
                elapsedSeconds = Int(Date().timeIntervalSince(start))
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func stopBrushing() {
        timer?.invalidate()
        timer = nil
        guard let start = startDate else { return }
        let record = BrushingRecord(startDate: start, endDate: Date())
        store.add(record)
        doneSheetRecord = record
        showDoneSheet = true
        startDate = nil
        isBrushing = false
        elapsedSeconds = 0
    }
}

// MARK: - Done result popup: compact card, star-based feedback, delete option
private struct DoneResultSheet: View {
    let record: BrushingRecord
    let onDismiss: () -> Void
    let onDelete: () -> Void
    @State private var cardAppeared = false

    private var stars: Int { record.starCount }
    private var duration: Int { record.durationSeconds }

    private var title: String {
        switch stars {
        case 3: return "Perfect!"
        case 2: return "Good job!"
        default: return "Every brush counts!"
        }
    }

    private var titleColor: Color {
        switch stars {
        case 3: return Color(red: 0.4, green: 0.85, blue: 0.5)
        case 2: return Theme.accentBlue
        default: return Color(red: 1, green: 0.75, blue: 0.4)
        }
    }

    private var message: String {
        switch stars {
        case 3: return "You brushed for 2 minutes. That's the recommended time."
        case 2: return "You're building a great habit. Keep it up!"
        default: return "Try for 2 minutes next time. You've got this!"
        }
    }

    private var funFact: String {
        switch stars {
        case 3: return "Did you know? Tooth enamel is the hardest part of your body."
        case 2: return "Fun fact: Kids have 20 baby teeth. Taking care of them now helps your adult teeth."
        default: return "Tip: Brushing twice a day helps keep cavities away."
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundColor(titleColor)

            Text(formattedTime)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            StarRatingView(count: stars, size: 24)

            VStack(spacing: 6) {
                Text(message)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                Text(funFact)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 8)

            Button("Done", action: onDismiss)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Theme.accentBlue)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Button("Delete this record", action: onDelete)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Theme.backgroundMid, Theme.backgroundEnd.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Theme.accentBlue.opacity(0.35), lineWidth: 1)
                )
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
