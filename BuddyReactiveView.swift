// MARK: - BuddyReactiveView.swift
//
// R-1 PROTOTYPE (2026-07-03, redesigned) — de-risks the retention-engine spine:
// "can a hand-rigged SwiftUI Buddy feel alive without Rive/Lottie?"
//
// State-driven, layered SwiftUI (NOT one static Canvas like DuoCharacters.BuddyView).
// Everything (body + face + arms) lives in ONE 120×140 coordinate space so proportions
// stay consistent. Continuous motion (breathe / random blink / brushing-wiggle /
// celebrate-jump) is driven per-frame by TimelineView; discrete pose (mouth / eyes /
// arms / blush) is mood-driven and spring-animated. Zero dependencies — pure SwiftUI, iOS 17+.
//
// Design anchor: Duolingo shape-language (baby-schema big eyes, clear silhouette,
// geometric building blocks, no sharp points, chunky ink outline + 4pt depth shadow).
//
// Not wired into the app yet — see BuddyLabView / BuddyMoodGallery + #Preview to run it.
// Requirements: docs/brainstorms/2026-07-03-toothbuddy-retention-engine-requirements.md (R4).

import SwiftUI

// =====================================================================
// MARK: - Mood
// =====================================================================

enum BuddyMood: String, CaseIterable, Identifiable {
    case idle        // 待机:呼吸 + 随机眨眼
    case brushing    // 刷牙中:开心咧嘴 + 轻晃
    case celebrate   // 达标庆祝:跳起 + 星星
    case sad         // 漏刷后:蔫(可恢复,绝不死)
    case waking      // 早上揭晓:醒来登场

    var id: String { rawValue }
    var label: String {
        switch self {
        case .idle:      return "待机"
        case .brushing:  return "刷牙中"
        case .celebrate: return "庆祝"
        case .sad:       return "蔫了"
        case .waking:    return "醒来"
        }
    }
}

// =====================================================================
// MARK: - Pose (discrete, mood-driven)
// =====================================================================

private enum EyeStyle { case open, happy, sad }

private struct BuddyPose {
    var eye: EyeStyle
    var mouthCurve: CGFloat   // -1 frown … +1 smile (fraction of the mouth's half-height)
    var grin: CGFloat         // 0…1 open-grin height; >0 hides the stroked mouth
    var arms: CGFloat         // 0 down … 1 up
    var blush: Double
    var saturation: Double
    var sparkles: Bool
    var baseYOffset: CGFloat  // resting vertical shift (droop when sad)

    static func of(_ mood: BuddyMood) -> BuddyPose {
        switch mood {
        case .idle:
            return .init(eye: .open,  mouthCurve: 0.85, grin: 0,    arms: 0.06, blush: 0.9,  saturation: 1.0, sparkles: false, baseYOffset: 0)
        case .brushing:
            return .init(eye: .happy, mouthCurve: 0.85, grin: 0.85, arms: 0.20, blush: 1.0,  saturation: 1.0, sparkles: false, baseYOffset: 0)
        case .celebrate:
            return .init(eye: .happy, mouthCurve: 0.85, grin: 1.0,  arms: 1.0,  blush: 1.0,  saturation: 1.0, sparkles: true,  baseYOffset: 0)
        case .sad:
            return .init(eye: .sad,   mouthCurve: -0.55, grin: 0,   arms: 0.0,  blush: 0.30, saturation: 0.62, sparkles: false, baseYOffset: 5)
        case .waking:
            return .init(eye: .open,  mouthCurve: 0.55, grin: 0.22, arms: 0.1,  blush: 0.85, saturation: 1.0, sparkles: false, baseYOffset: 0)
        }
    }
}

// =====================================================================
// MARK: - BuddyReactiveView
// =====================================================================

struct BuddyReactiveView: View {
    var mood: BuddyMood
    var scale: CGFloat = 1.7

    // One shared design space. Everything below is authored in these units.
    private let refW: CGFloat = 120
    private let refH: CGFloat = 140

    var body: some View {
        let pose = BuddyPose.of(mood)
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            content(t: t, pose: pose)
        }
        .frame(width: refW * scale, height: refH * scale)
    }

    /// Body-space (120×140) point → scaled frame point.
    private func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * scale, y: y * scale) }

    private func content(t: Double, pose: BuddyPose) -> some View {
        let live = aliveness(t: t)
        let blink = self.blink(t: t)
        let W = refW * scale, H = refH * scale
        let stroke = 4.6 * scale
        let handY = 96 + (34 - 96) * pose.arms   // arm-end Y, tracks `raise`

        return ZStack {
            // Arms (behind body) + little rounded hands at their ends
            ArmsShape(raise: pose.arms)
                .stroke(Duo.ink, style: StrokeStyle(lineWidth: 4.8 * scale, lineCap: .round))
                .frame(width: W, height: H)
            Circle().fill(Duo.ink).frame(width: 10 * scale, height: 10 * scale).position(P(8, handY))
            Circle().fill(Duo.ink).frame(width: 10 * scale, height: 10 * scale).position(P(112, handY))

            // Ink depth-shadow (Duolingo chunky depth)
            BodyShape()
                .fill(Duo.ink)
                .frame(width: W, height: H)
                .offset(y: 3.0 * scale)

            // Body face + chunky outline
            BodyShape()
                .fill(Duo.cream)
                .overlay(BodyShape().stroke(Duo.ink, lineWidth: stroke))
                .frame(width: W, height: H)

            // Cheeks
            Ellipse().fill(Duo.blush).opacity(pose.blush)
                .frame(width: 18 * scale, height: 12 * scale).position(P(34, 80))
            Ellipse().fill(Duo.blush).opacity(pose.blush)
                .frame(width: 18 * scale, height: 12 * scale).position(P(86, 80))

            // Eyes — large, baby-schema, set low
            EyeView(style: pose.eye, blink: blink, s: scale).position(P(46, 66))
            EyeView(style: pose.eye, blink: blink, s: scale).position(P(74, 66))

            // Mouth — stroked smile/frown crossfading with an open grin
            MouthShape(curve: pose.mouthCurve)
                .stroke(Duo.ink, style: StrokeStyle(lineWidth: stroke * 0.82, lineCap: .round))
                .frame(width: 30 * scale, height: 17 * scale)
                .opacity(pose.grin > 0.1 ? 0 : 1)
                .position(P(60, 88))
            GrinShape(open: pose.grin)
                .fill(Duo.ink)
                .frame(width: 26 * scale, height: 17 * scale)
                .opacity(pose.grin > 0.1 ? 1 : 0)
                .position(P(60, 90))
        }
        .frame(width: W, height: H)
        .saturation(pose.saturation)
        .scaleEffect(x: live.sx, y: live.sy, anchor: .bottom)
        .rotationEffect(.degrees(live.rot))
        .offset(y: live.yOff + pose.baseYOffset)
        .overlay { if pose.sparkles { SparkleLayer(t: t, scale: scale) } }
        .animation(.spring(response: 0.42, dampingFraction: 0.66), value: mood)
    }

    // Continuous per-frame "alive" transform.
    private func aliveness(t: Double) -> (sx: CGFloat, sy: CGFloat, yOff: CGFloat, rot: Double) {
        switch mood {
        case .idle, .waking:
            let b = sin(t * 1.9)
            return (1 + 0.020 * b, 1 + 0.028 * b, CGFloat(-b) * 2.0, 0)
        case .sad:
            let b = sin(t * 1.15)
            return (1 + 0.010 * b, 1 - 0.006 * b, CGFloat(b) * 1.0, sin(t * 0.9) * 1.1)
        case .brushing:
            let s = 1 + 0.018 * sin(t * 6.2)
            return (CGFloat(s), CGFloat(s), 0, sin(t * 9.0) * 3.0)
        case .celebrate:
            let j = abs(sin(t * 4.6))                    // 0 grounded … 1 top of jump
            let sx = 1 + (1 - j) * 0.06 - j * 0.03
            let sy = 1 - (1 - j) * 0.06 + j * 0.05
            return (CGFloat(sx), CGFloat(sy), CGFloat(-j) * 20, sin(t * 4.6) * 3.2)
        }
    }

    // Irregular blink: each ~2.6s window blinks once at a jittered offset, with an
    // occasional double. Returns eye vertical scale (~1 open, ~0.1 closed).
    private func blink(t: Double) -> CGFloat {
        guard mood == .idle || mood == .waking || mood == .sad else { return 1 }
        let period = 2.6
        let idx = (t / period).rounded(.down)
        let r = frac(sin(idx * 91.7) * 4271.3)           // pseudo-random 0…1 per window
        let start = idx * period + 0.5 + r * (period - 1.1)
        let dip: (Double) -> CGFloat = { dt in
            guard dt >= 0, dt <= 0.16 else { return 1 }
            return max(0.10, 1 - sin(dt / 0.16 * .pi))
        }
        var b = dip(t - start)
        if r > 0.80 { b = min(b, dip(t - start - 0.28)) } // sometimes a double blink
        return b
    }

    private func frac(_ x: Double) -> Double { x - x.rounded(.down) }
}

// =====================================================================
// MARK: - Sub-shapes & sub-views
// =====================================================================

/// Cute tooth silhouette: rounded dome + two soft feet with a gentle valley.
/// Authored in a 120×140 box; scales to fill its frame. No sharp points (Duolingo rule).
private struct BodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 120, sy = rect.height / 140
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy)
        }
        var path = Path()
        path.move(to: p(60, 12))
        path.addCurve(to: p(20, 54),   control1: p(33, 12),  control2: p(20, 30))   // left shoulder
        path.addCurve(to: p(31, 116),  control1: p(20, 84),  control2: p(21, 100))  // left side down
        path.addCurve(to: p(50, 114),  control1: p(36, 127), control2: p(46, 127))  // left foot
        path.addCurve(to: p(60, 100),  control1: p(54, 105), control2: p(56, 100))  // into valley
        path.addCurve(to: p(70, 114),  control1: p(64, 100), control2: p(66, 105))  // out of valley
        path.addCurve(to: p(89, 116),  control1: p(74, 127), control2: p(84, 127))  // right foot
        path.addCurve(to: p(100, 54),  control1: p(99, 100), control2: p(100, 84))  // right side up
        path.addCurve(to: p(60, 12),   control1: p(100, 30), control2: p(87, 12))   // right shoulder
        path.closeSubpath()
        return path
    }
}

/// Stroked mouth. `curve` −1 frown … +1 smile (fraction of half-height). Animatable.
private struct MouthShape: Shape {
    var curve: CGFloat
    var animatableData: CGFloat {
        get { curve }
        set { curve = newValue }
    }
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let y = rect.midY
        let controlY = y + curve * rect.height * 0.5
        p.move(to: CGPoint(x: rect.minX, y: y - curve * rect.height * 0.14))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: y - curve * rect.height * 0.14),
                       control: CGPoint(x: rect.midX, y: controlY))
        return p
    }
}

/// Filled open-grin. `open` 0…1 scales the mouth height. Animatable.
private struct GrinShape: Shape {
    var open: CGFloat
    var animatableData: CGFloat {
        get { open }
        set { open = newValue }
    }
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let h = rect.height * max(0.001, open)
        let top = rect.minY
        let inset = rect.width * (1 - max(0.35, open)) * 0.18  // narrower when barely open
        p.move(to: CGPoint(x: rect.minX + inset, y: top))
        p.addQuadCurve(to: CGPoint(x: rect.maxX - inset, y: top),
                       control: CGPoint(x: rect.midX, y: top + 2))
        p.addQuadCurve(to: CGPoint(x: rect.minX + inset, y: top),
                       control: CGPoint(x: rect.midX, y: top + h))
        p.closeSubpath()
        return p
    }
}

/// Both arms in one full-frame shape; `raise` 0 (hang) … 1 (up, cheering). Animatable.
private struct ArmsShape: Shape {
    var raise: CGFloat
    var animatableData: CGFloat {
        get { raise }
        set { raise = newValue }
    }
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 120, sy = rect.height / 140
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy)
        }
        var path = Path()
        // Left arm: shoulder → hand swings from down-out (y96) to up (y34).
        path.move(to: p(22, 68))
        path.addQuadCurve(to: p(8, 96 + (34 - 96) * raise), control: p(5, 80))
        // Right arm mirror.
        path.move(to: p(98, 68))
        path.addQuadCurve(to: p(112, 96 + (34 - 96) * raise), control: p(115, 80))
        return path
    }
}

/// A single eye. Open = big pupil + highlight (blinks); happy = ^ arc; sad = ⌣ droop arc.
private struct EyeView: View {
    var style: EyeStyle
    var blink: CGFloat
    var s: CGFloat

    var body: some View {
        switch style {
        case .open:
            ZStack {
                Circle().fill(Duo.ink).frame(width: 15 * s, height: 15 * s)
                Circle().fill(.white).frame(width: 4.6 * s, height: 4.6 * s)
                    .offset(x: 2.0 * s, y: -3.0 * s)
            }
            .scaleEffect(x: 1, y: blink, anchor: .center)
        case .happy:
            ArcEye(up: true)
                .stroke(Duo.ink, style: StrokeStyle(lineWidth: 3.4 * s, lineCap: .round))
                .frame(width: 18 * s, height: 10 * s)
        case .sad:
            ArcEye(up: false)
                .stroke(Duo.ink, style: StrokeStyle(lineWidth: 3.2 * s, lineCap: .round))
                .frame(width: 15 * s, height: 8 * s)
        }
    }
}

/// Curved eye. up = caret ^ (happy); down = droop ⌣ (sad).
private struct ArcEye: Shape {
    var up: Bool
    func path(in rect: CGRect) -> Path {
        var p = Path()
        if up {
            p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY),
                           control: CGPoint(x: rect.midX, y: rect.minY))
        } else {
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                           control: CGPoint(x: rect.midX, y: rect.maxY))
        }
        return p
    }
}

/// Celebrate sparkles orbiting Buddy's head, driven by time.
private struct SparkleLayer: View {
    var t: Double
    var scale: CGFloat

    var body: some View {
        // Tidy arc of twinkles across the crown — never orbiting down into the face.
        let angles: [Double] = [-128, -90, -52]
        return ZStack {
            ForEach(0..<angles.count, id: \.self) { i in
                let a = angles[i] * .pi / 180
                let r = 54.0 * Double(scale)
                let x = cos(a) * r
                let y = sin(a) * r - 4 * Double(scale)
                let tw = 0.5 + 0.5 * (0.5 + 0.5 * sin(t * 3.4 + Double(i) * 1.6))
                Image(systemName: "sparkle")
                    .font(.system(size: 17 * scale / 1.7, weight: .black))
                    .foregroundStyle(Duo.yellow)
                    .scaleEffect(tw)
                    .offset(x: x, y: y)
            }
        }
    }
}

// =====================================================================
// MARK: - BuddyLabView — interactive demo (tap to switch states)
// =====================================================================

struct BuddyLabView: View {
    @State private var mood: BuddyMood = .idle
    @State private var running = false

    var body: some View {
        ZStack {
            Duo.pageBackground.ignoresSafeArea()
            VStack(spacing: 8) {
                Text("Buddy 反应原型")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(Duo.ink)
                Text("R-1 · 手搓 SwiftUI,无 Rive/Lottie")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Duo.muted)

                Spacer(minLength: 0)
                BuddyReactiveView(mood: mood, scale: 2.2).frame(height: 300)
                Text(mood.label)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(Duo.ink)
                    .padding(.horizontal, 16).padding(.vertical, 6)
                    .background(Capsule().fill(Duo.cream))
                    .overlay(Capsule().stroke(Duo.ink, lineWidth: 2))
                Spacer(minLength: 0)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 10)], spacing: 10) {
                    ForEach(BuddyMood.allCases) { m in
                        Button {
                            running = false
                            mood = m
                        } label: {
                            Text(m.label)
                                .font(.system(size: 15, weight: .heavy, design: .rounded))
                                .foregroundStyle(mood == m ? .white : Duo.ink)
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 14).fill(mood == m ? Duo.blue : Duo.cream))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Duo.ink, lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)

                Button {
                    Task { await runBrushSequence() }
                } label: {
                    Text(running ? "演示中…" : "▶︎ 模拟一次刷牙")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Duo.green))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Duo.ink, lineWidth: 2))
                        .shadow(color: Duo.greenShadow, radius: 0, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(running)
            }
            .padding(20)
        }
    }

    private func runBrushSequence() async {
        running = true
        mood = .waking
        try? await Task.sleep(for: .seconds(1.2))
        mood = .brushing
        try? await Task.sleep(for: .seconds(3.0))
        mood = .celebrate
        try? await Task.sleep(for: .seconds(2.4))
        mood = .idle
        running = false
    }
}

// =====================================================================
// MARK: - BuddyMoodGallery — all 5 states at once (screenshot / preview)
// =====================================================================

struct BuddyMoodGallery: View {
    var body: some View {
        ZStack {
            Duo.pageBackground.ignoresSafeArea()
            VStack(spacing: 10) {
                Text("Buddy · 5 个反应状态")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(Duo.ink)
                Text("手搓 SwiftUI · 无 Rive/Lottie · R-1 原型")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Duo.muted)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(BuddyMood.allCases) { m in
                        VStack(spacing: 2) {
                            BuddyReactiveView(mood: m, scale: 1.15)
                            Text(m.label)
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .foregroundStyle(Duo.ink)
                                .padding(.horizontal, 12).padding(.vertical, 3)
                                .background(Capsule().fill(Duo.cream))
                                .overlay(Capsule().stroke(Duo.ink, lineWidth: 1.5))
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
            .padding(.vertical, 24)
        }
    }
}

// =====================================================================
// MARK: - Previews
// =====================================================================

#Preview("Buddy Lab") { BuddyLabView() }
#Preview("All moods") { BuddyMoodGallery() }
