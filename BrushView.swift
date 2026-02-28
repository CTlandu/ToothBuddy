import SwiftUI

struct BrushView: View {
    @StateObject private var store = BrushingStore.shared
    @State private var isBrushing = false
    @State private var startDate: Date?
    @State private var elapsedSeconds = 0
    @State private var timer: Timer?
    /// Shown after stopping: duration and star count for the "Great job!" card.
    @State private var lastDone: (duration: Int, stars: Int)?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                cameraSection
                if let done = lastDone {
                    doneCard(duration: done.duration, stars: done.stars)
                }
                if !isBrushing {
                    goalBar
                }
                buttonSection
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .background(Theme.appBackground)
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

            // Live camera preview (clipped to same shape)
            CameraPreviewView()
                .clipShape(RoundedRectangle(cornerRadius: 32))
                .allowsHitTesting(false)

            if isBrushing {
                // LIVE pill
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

            // Bottom: tooth character + timer or "Ready to brush?"
            VStack(spacing: 6) {
                toothCharacter
                if isBrushing {
                    Text(formattedTime(elapsedSeconds))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .tracking(2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                } else if lastDone == nil {
                    Text("Ready to brush? 🪥")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.textMutedStrong)
                }
            }
            .padding(.bottom, 28)
        }
        .frame(height: 310)
        .padding(.bottom, 20)
    }

    private var toothCharacter: some View {
        Text("🦷")
            .font(.system(size: 60))
            .rotationEffect(.degrees(isBrushing ? 4 : 0))
            .animation(
                isBrushing ? .easeInOut(duration: 0.2).repeatForever(autoreverses: true) : .default,
                value: isBrushing
            )
    }

    private func doneCard(duration: Int, stars: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("GREAT JOB! 🎉")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.textMutedStrong)
                Text(formattedTime(duration))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(doneMessage(duration))
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textMutedStrong)
            }
            Spacer()
            StarRatingView(count: stars, size: 24)
        }
        .padding(18)
        .background(Theme.doneCardGradient)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.bottom, 16)
    }

    private func doneMessage(_ duration: Int) -> String {
        if duration >= 120 { return "Perfect brushing time! 🏆" }
        if duration >= 60 { return "Good job! Keep going! 💪" }
        return "Try for 2 minutes! ⏱️"
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
    }

    private var buttonSection: some View {
        Button {
            if isBrushing {
                stopBrushing()
            } else {
                lastDone = nil
                startBrushing()
            }
        } label: {
            Text(isBrushing ? "✅ Done Brushing!" : "🪥 Start Brushing!")
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
        .buttonStyle(.plain)
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
        lastDone = nil
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
        lastDone = (record.durationSeconds, record.starCount)
        startDate = nil
        isBrushing = false
        elapsedSeconds = 0
    }
}
