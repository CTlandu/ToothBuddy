import SwiftUI

// MARK: - Main onboarding container

struct OnboardingView: View {
    @State private var page = 0
    let onComplete: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            Duo.pageBackground.ignoresSafeArea()

            // Slides via paged TabView (swipe gestures supported)
            TabView(selection: $page) {
                WelcomeOnboardingSlide(onNext: { advance() })
                    .tag(0)

                FeatureOnboardingSlide(
                    title: "Open & See Yourself!",
                    subtitle: "Your front camera turns on so you can watch yourself brush — no more missing a spot!",
                    dotPage: 1,
                    onNext: { advance() },
                    illustration: { CameraOnboardingIllustration() }
                )
                .tag(1)

                FeatureOnboardingSlide(
                    title: "Tap to Start Brushing!",
                    subtitle: "Hit the big button and your timer begins. Brush 2 full minutes to earn 3 stars!",
                    dotPage: 2,
                    onNext: { advance() },
                    illustration: { TimerOnboardingIllustration() }
                )
                .tag(2)

                FeatureOnboardingSlide(
                    title: "Unlock Achievements!",
                    subtitle: "Every session earns progress. Build your streak, earn badges, and level up your rank!",
                    dotPage: 3,
                    onNext: { advance() },
                    illustration: { AchievementsOnboardingIllustration() }
                )
                .tag(3)

                FeatureOnboardingSlide(
                    title: "Track Your Progress!",
                    subtitle: "Check your History tab after each brush. Watch your streak grow day by day!",
                    dotPage: 4,
                    isLast: true,
                    onNext: { advance() },
                    illustration: { HistoryOnboardingIllustration() }
                )
                .tag(4)

                ReadyOnboardingSlide(onStart: onComplete)
                    .tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // Skip button on feature slides
            if page >= 1 && page <= 4 {
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) { page = 5 }
                    } label: {
                        Text("Skip")
                            .font(Duo.Fnt.ebd(13))
                            .tracking(0.5)
                            .foregroundColor(Duo.ink)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(.white))
                            .overlay(Capsule().stroke(Duo.ink, lineWidth: 1.5))
                    }
                    .padding(.trailing, 22)
                    .padding(.top, 58)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: page)
            }
        }
    }

    private func advance() {
        withAnimation(.easeInOut(duration: 0.3)) {
            page = min(page + 1, 5)
        }
    }
}

// MARK: - Welcome slide

struct WelcomeOnboardingSlide: View {
    let onNext: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Buddy mascot with chunky glow rings
            ZStack {
                Circle()
                    .fill(Duo.green.opacity(0.10))
                    .frame(width: 240, height: 240)
                Circle()
                    .fill(Duo.green.opacity(0.06))
                    .frame(width: 280, height: 280)
                BuddyView()
                    .frame(width: 180, height: 200)
            }
            .scaleEffect(appeared ? 1 : 0.35)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.65, dampingFraction: 0.58).delay(0.1), value: appeared)

            Spacer().frame(height: 36)

            VStack(spacing: 12) {
                VStack(spacing: 0) {
                    Text("Meet")
                        .font(Duo.Fnt.ebd(44))
                        .foregroundColor(Duo.ink)
                    Text("ToothBuddy!")
                        .font(Duo.Fnt.ebd(44))
                        .foregroundColor(Duo.green)
                }
                .multilineTextAlignment(.center)

                Text("Your super fun brushing companion!\nLet's build a healthy habit together!")
                    .font(Duo.Fnt.sbd(15))
                    .foregroundColor(Duo.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 24)
            .animation(.easeOut(duration: 0.5).delay(0.35), value: appeared)

            Spacer()

            VStack(spacing: 12) {
                DuoButton("LET'S GO!", role: .primary, action: onNext)
                Text("Swipe through to learn how it works")
                    .font(Duo.Fnt.sbd(12))
                    .foregroundColor(Duo.muted.opacity(0.7))
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.75), value: appeared)
            .padding(.horizontal, 28)

            Spacer().frame(height: 52)
        }
        .onAppear { appeared = true }
        .onDisappear { appeared = false }
    }
}

// MARK: - Feature slide template

struct FeatureOnboardingSlide<I: View>: View {
    let title: String
    let subtitle: String
    let dotPage: Int
    var isLast: Bool = false
    let onNext: () -> Void
    @ViewBuilder let illustration: () -> I

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            illustration()
                .frame(height: 220)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.85)
                .offset(y: appeared ? 0 : 28)
                .animation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.05), value: appeared)

            Spacer().frame(height: 30)

            VStack(spacing: 12) {
                Text(title)
                    .font(Duo.Fnt.ebd(28))
                    .foregroundColor(Duo.ink)
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(Duo.Fnt.sbd(15))
                    .foregroundColor(Duo.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .animation(.easeOut(duration: 0.45).delay(0.15), value: appeared)
            .padding(.horizontal, 32)

            Spacer()

            // Dot indicators (pages 1–4)
            HStack(spacing: 8) {
                ForEach(1...4, id: \.self) { i in
                    Capsule()
                        .fill(dotPage == i ? Duo.green : Duo.stoneLight)
                        .overlay(Capsule().stroke(Duo.ink.opacity(dotPage == i ? 1 : 0.4),
                                                  lineWidth: 1.5))
                        .frame(width: dotPage == i ? 26 : 10, height: 10)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dotPage)
            .padding(.bottom, 18)

            DuoButton(isLast ? "ALMOST READY!" : "NEXT",
                      role: .primary, action: onNext)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.25), value: appeared)
            .padding(.horizontal, 28)

            Spacer().frame(height: 52)
        }
        .onAppear { appeared = true }
        .onDisappear { appeared = false }
    }
}

// MARK: - Ready slide

struct ReadyOnboardingSlide: View {
    let onStart: () -> Void
    @State private var appeared = false

    private let checklist: [(String, String)] = [
        ("camera.fill", "Camera is ready"),
        ("timer", "2-minute timer set"),
        ("trophy.fill", "Achievements waiting for you"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            FoamView()
                .frame(width: 140, height: 140)
                .scaleEffect(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.58).delay(0.1), value: appeared)

            Spacer().frame(height: 16)

            Text("You're all set!")
                .font(Duo.Fnt.ebd(34))
                .foregroundColor(Duo.ink)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.25), value: appeared)

            Text("Time to start your first brushing session.\nYour ToothBuddy is cheering for you!")
                .font(Duo.Fnt.sbd(15))
                .foregroundColor(Duo.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, 10)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.35), value: appeared)

            Spacer().frame(height: 32)

            // Animated checklist
            VStack(spacing: 10) {
                ForEach(Array(checklist.enumerated()), id: \.offset) { i, item in
                    DuoCard(face: .white, padding: 12) {
                        HStack(spacing: 14) {
                            Image(systemName: item.0)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Duo.green)
                                .frame(width: 28)
                            Text(item.1)
                                .font(Duo.Fnt.ebd(13))
                                .foregroundColor(Duo.ink)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(Duo.green)
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(x: appeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.4).delay(0.5 + Double(i) * 0.1), value: appeared)
                }
            }
            .padding(.horizontal, 28)

            Spacer()

            DuoButton("START BRUSHING!", role: .primary, action: onStart)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.85), value: appeared)
            .padding(.horizontal, 28)

            Spacer().frame(height: 52)
        }
        .onAppear { appeared = true }
        .onDisappear { appeared = false }
    }
}

// MARK: - Camera illustration

struct CameraOnboardingIllustration: View {
    @State private var pulsing = false

    var body: some View {
        ZStack {
            // Phone body
            RoundedRectangle(cornerRadius: 36)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 36)
                    .stroke(Duo.greenShadow.opacity(0.3), lineWidth: 2))
                .frame(width: 155, height: 200)
                .shadow(color: Duo.greenShadow.opacity(0.18), radius: 20, y: 8)

            // Screen gradient
            RoundedRectangle(cornerRadius: 28)
                .fill(LinearGradient(
                    colors: [Theme.cameraBrushingStart, Theme.cameraBrushingEnd],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 136, height: 182)

            // Face silhouette
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 48, height: 48)
                Ellipse()
                    .fill(Color.white.opacity(0.14))
                    .frame(width: 78, height: 56)
            }
            .offset(y: 22)

            // LIVE badge
            HStack(spacing: 4) {
                Circle()
                    .fill(Color(red: 248/255, green: 113/255, blue: 113/255))
                    .frame(width: 6, height: 6)
                    .opacity(pulsing ? 1.0 : 0.15)
                Text("LIVE")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(Duo.ink)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.white.opacity(0.88)))
            .offset(y: -76)

            // Corner brackets
            CornerBracketShape()
                .stroke(Duo.greenShadow, lineWidth: 2.5)
                .frame(width: 18, height: 18)
                .offset(x: -53, y: -80)

            CornerBracketShape()
                .stroke(Duo.greenShadow, lineWidth: 2.5)
                .frame(width: 18, height: 18)
                .rotationEffect(.degrees(90))
                .offset(x: 53, y: -80)

            CornerBracketShape()
                .stroke(Duo.greenShadow, lineWidth: 2.5)
                .frame(width: 18, height: 18)
                .rotationEffect(.degrees(-90))
                .offset(x: -53, y: 80)

            CornerBracketShape()
                .stroke(Duo.greenShadow, lineWidth: 2.5)
                .frame(width: 18, height: 18)
                .rotationEffect(.degrees(180))
                .offset(x: 53, y: 80)

            // Floating sparkles
            Image(systemName: "sparkles")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Duo.greenShadow.opacity(0.8))
                .offset(x: 88, y: -60)
            Image(systemName: "sparkle")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Duo.green.opacity(0.7))
                .offset(x: -90, y: -28)
        }
        .frame(width: 240, height: 230)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                pulsing = true
            }
        }
    }
}

private struct CornerBracketShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.height))
        p.addLine(to: .zero)
        p.addLine(to: CGPoint(x: rect.width, y: 0))
        return p
    }
}

// MARK: - Timer illustration

struct TimerOnboardingIllustration: View {
    @State private var seconds = 47

    var body: some View {
        let progress = min(Double(seconds) / 120.0, 1.0)

        ZStack {
            Circle()
                .fill(Duo.green.opacity(0.10))
                .frame(width: 170, height: 170)

            Circle()
                .stroke(Color.black.opacity(0.07), lineWidth: 14)
                .frame(width: 142, height: 142)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [Duo.green, Duo.greenShadow],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 142, height: 142)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.08), value: seconds)

            // Time display
            VStack(spacing: 4) {
                Text(String(format: "%02d:%02d", seconds / 60, seconds % 60))
                    .font(.system(size: 30, weight: .heavy, design: .rounded).monospacedDigit())
                    .foregroundColor(Duo.ink)
                Text("out of 2:00")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Duo.muted)
            }

            // Star rating
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: progress > Double(i + 1) / 3.0 ? "star.fill" : "star")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(progress > Double(i + 1) / 3.0
                                         ? Color(red: 251/255, green: 191/255, blue: 36/255)
                                         : Color.gray.opacity(0.3))
                }
            }
            .offset(y: 88)

            // Floating decorations
            Image(systemName: "drop.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Duo.greenShadow.opacity(0.8))
                .offset(x: 90, y: -54)
            Image(systemName: "drop.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Duo.green.opacity(0.7))
                .offset(x: -88, y: -38)
            Image(systemName: "drop.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Duo.green.opacity(0.5))
                .offset(x: 84, y: 62)
        }
        .frame(width: 220, height: 230)
        .onReceive(
            Timer.publish(every: 0.08, on: .main, in: .common).autoconnect()
        ) { _ in
            seconds = seconds >= 120 ? 0 : seconds + 1
        }
    }
}

// MARK: - Achievements illustration

struct AchievementsOnboardingIllustration: View {
    @State private var glowing = false

    private let badges: [(String, Bool)] = [
        ("drop.fill", true), ("5.circle.fill", true), ("flame.fill", true),
    ]

    var body: some View {
        ZStack {
            Circle()
                .fill(Duo.green.opacity(glowing ? 0.20 : 0.07))
                .frame(width: 120, height: 120)
                .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: glowing)

            Image(systemName: "trophy.fill")
                .font(.system(size: 68, weight: .bold))
                .foregroundColor(Color(red: 251/255, green: 191/255, blue: 36/255))
                .symbolRenderingMode(.hierarchical)
                .offset(y: -30)

            HStack(spacing: 8) {
                ForEach(Array(badges.enumerated()), id: \.offset) { _, badge in
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(badge.1
                                  ? Duo.green.opacity(0.2)
                                  : Color.black.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(badge.1
                                            ? Duo.greenShadow.opacity(0.4)
                                            : Color.black.opacity(0.08), lineWidth: 1)
                            )
                        Image(systemName: badge.0)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(badge.1 ? symbolColor(for: badge.0) : .gray.opacity(0.3))
                            .symbolRenderingMode(.hierarchical)
                    }
                    .frame(width: 52, height: 52)
                }
            }
            .offset(y: 72)

            Image(systemName: "star.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(red: 251/255, green: 191/255, blue: 36/255).opacity(0.9))
                .offset(x: 95, y: -58)
            Image(systemName: "star.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Duo.greenShadow.opacity(0.7))
                .offset(x: -96, y: -42)
            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Duo.green.opacity(0.8))
                .offset(x: 88, y: 28)
        }
        .frame(width: 230, height: 220)
        .onAppear { glowing = true }
    }
}

// MARK: - History illustration

struct HistoryOnboardingIllustration: View {
    private let rows: [(String, String, Int)] = [
        ("8:02 AM", "2:22", 3),
        ("9:45 PM", "1:58", 2),
        ("8:10 AM", "2:05", 3),
    ]

    var body: some View {
        VStack(spacing: 8) {
            // Streak banner
            HStack(spacing: 10) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.orange)
                    .symbolRenderingMode(.hierarchical)
                VStack(alignment: .leading, spacing: 1) {
                    Text("5-Day Streak!")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(Duo.ink)
                    Text("Keep it going!")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Duo.muted)
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 252/255, green: 196/255, blue: 92/255).opacity(0.18))
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(red: 251/255, green: 191/255, blue: 36/255).opacity(0.35), lineWidth: 1))
            )

            // Session rows
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack {
                    Text(row.0)
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(Duo.ink)
                    Spacer()
                    Text(row.1)
                        .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundColor(Duo.greenShadow)
                    HStack(spacing: 2) {
                        ForEach(0..<row.2, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Color(red: 251/255, green: 191/255, blue: 36/255))
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Duo.ink.opacity(0.15), lineWidth: 1))
                )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white.opacity(0.82))
                .overlay(RoundedRectangle(cornerRadius: 22)
                    .stroke(Duo.ink.opacity(0.15), lineWidth: 1))
        )
        .shadow(color: Color(red: 52/255, green: 211/255, blue: 153/255).opacity(0.15), radius: 16, y: 6)
        .frame(width: 248)
    }
}
