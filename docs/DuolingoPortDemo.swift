// MARK: - DuolingoPortDemo.swift
//
// PROOF-OF-PORT — direct 1:1 SwiftUI port of the Duolingo set from
// `docs/character-explorations.html` (Set 02).
//
// This file is NOT compiled by the app target (not listed in project.yml).
// It lives here so you can:
//   1. Drop it temporarily into Xcode (paste into a new file in the
//      ToothBuddy target or into Swift Playgrounds), and
//   2. See the SwiftUI render in the Xcode Preview canvas — pixel-for-
//      pixel within ~1pt of the HTML mockup.
//
// Once you say "ship this lane," I'll:
//   - move the Color tokens into `Theme.swift`,
//   - convert the character SVG paths into `Shape` types in a new
//     `Characters/` folder (or import them as PDFs via Asset Catalog),
//   - refactor `BrushView` / `HistoryView` / etc. to use these primitives.

import SwiftUI

// =====================================================================
// MARK: - Color tokens (Duolingo lane)
// =====================================================================

extension Color {
    /// Nearly-black ink used for every outline and dark text.
    static let duoInk          = Color(red: 0.169, green: 0.145, blue: 0.208)  // #2B2535
    static let duoCream        = Color(red: 0.980, green: 0.980, blue: 0.961)  // #FAFAF5
    static let duoGreen        = Color(red: 0.345, green: 0.800, blue: 0.008)  // #58CC02
    static let duoGreenShadow  = Color(red: 0.247, green: 0.561, blue: 0.000)  // #3F8F00
    static let duoBlue         = Color(red: 0.110, green: 0.690, blue: 0.965)  // #1CB0F6
    static let duoBlueShadow   = Color(red: 0.063, green: 0.514, blue: 0.714)  // #1083B6
    static let duoBlush        = Color(red: 1.000, green: 0.702, blue: 0.757)  // #FFB3C1
    static let duoBgTopGreen   = Color(red: 0.969, green: 0.973, blue: 0.941)  // #F7F8F0
    static let duoBgBottomGreen = Color(red: 0.925, green: 0.969, blue: 0.910) // #ECF7E8
}

// =====================================================================
// MARK: - 1. The "chunky outlined" button (Duolingo's signature element)
// =====================================================================

/// Direct port of the green/blue button in the HTML mockup.
/// Uses the offset-shadow trick (a solid duplicate offset 4pt down)
/// instead of `.shadow()`, which is what gives Duolingo its press-able
/// feel. Tap state slides the button down by 4pt to "press" it.
struct DuoButton: View {
    let title: String
    let action: () -> Void
    var color: Color = .duoGreen
    var shadowColor: Color = .duoGreenShadow

    @GestureState private var isPressed = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Nunito-ExtraBold", size: 16))
                .tracking(0.5)
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(DuoButtonStyle(color: color, shadowColor: shadowColor))
    }
}

private struct DuoButtonStyle: ButtonStyle {
    let color: Color
    let shadowColor: Color

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            // Layer 1: shadow block (offset 4pt — the "depth")
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(shadowColor)
                .offset(y: configuration.isPressed ? 0 : 4)

            // Layer 2: face + outline
            configuration.label
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(color)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.duoInk, lineWidth: 2)
                )
                .offset(y: configuration.isPressed ? 4 : 0)
        }
        .animation(.spring(response: 0.18, dampingFraction: 0.7),
                   value: configuration.isPressed)
    }
}

// =====================================================================
// MARK: - 2. "Today's goal" card
// =====================================================================

struct DuoGoalCard: View {
    let level: Int
    let completedSlots: Int
    let totalSlots: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("TODAY'S GOAL")
                    .font(.custom("Nunito-ExtraBold", size: 11))
                    .tracking(0.8)
                    .foregroundColor(.duoInk)
                Spacer()
                HStack(spacing: 4) {
                    Text("🌱")
                    Text("LV \(level)")
                        .font(.custom("Nunito-ExtraBold", size: 11))
                        .foregroundColor(.duoGreen)
                }
            }
            // Progress pips
            HStack(spacing: 4) {
                ForEach(0..<totalSlots, id: \.self) { idx in
                    RoundedRectangle(cornerRadius: 5)
                        .fill(idx < completedSlots ? Color.duoGreen : Color(white: 0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.duoInk, lineWidth: 1.5)
                        )
                        .frame(height: 10)
                }
            }
            Text("A.M. · P.M.")
                .font(.custom("Nunito-SemiBold", size: 11))
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.duoInk).offset(y: 4)
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.duoInk, lineWidth: 2)
                    )
            }
        )
    }
}

// =====================================================================
// MARK: - 3. Buddy character (the same SVG, in pure SwiftUI Shapes)
// =====================================================================

/// The tooth-body silhouette. Coordinates are normalized to a 140×160
/// reference frame and rescaled into whatever rect SwiftUI gives.
private struct ToothBody: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width / 140, rect.height / 160)
        let ox = (rect.width  - 140 * s) / 2 + rect.minX
        let oy = (rect.height - 160 * s) / 2 + rect.minY
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x*s, y: oy + y*s) }

        var path = Path()
        path.move(to: p(28, 38))
        path.addQuadCurve(to: p(50, 16), control: p(28, 18))
        path.addLine(to: p(90, 16))
        path.addQuadCurve(to: p(112, 38), control: p(112, 18))
        path.addLine(to: p(112, 98))
        path.addQuadCurve(to: p(96, 152),  control: p(112, 130))
        path.addQuadCurve(to: p(80, 152),  control: p(90, 158))
        path.addQuadCurve(to: p(72, 118),  control: p(72, 138))
        path.addQuadCurve(to: p(64, 152),  control: p(72, 138))
        path.addQuadCurve(to: p(48, 152),  control: p(54, 158))
        path.addQuadCurve(to: p(28, 98),   control: p(28, 130))
        path.closeSubpath()
        return path
    }
}

private struct BuddySmile: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width / 140, rect.height / 160)
        let ox = (rect.width  - 140 * s) / 2 + rect.minX
        let oy = (rect.height - 160 * s) / 2 + rect.minY
        var path = Path()
        path.move(to: CGPoint(x: ox + 55*s, y: oy + 84*s))
        path.addQuadCurve(to: CGPoint(x: ox + 86*s, y: oy + 86*s),
                          control: CGPoint(x: ox + 72*s, y: oy + 96*s))
        return path
    }
}

struct BuddyView: View {
    var body: some View {
        ZStack {
            // Drop shadow (offset 4pt — Duolingo style)
            ToothBody().fill(Color.duoInk).offset(y: 4)

            // Body fill + stroke
            ToothBody().fill(Color.duoCream)
            ToothBody().stroke(Color.duoInk, lineWidth: 3.5)

            // Cheek blush (positioned in the 140×160 normalized space)
            GeometryReader { geo in
                let s = min(geo.size.width / 140, geo.size.height / 160)
                let ox = (geo.size.width - 140*s) / 2
                let oy = (geo.size.height - 160*s) / 2
                Group {
                    Ellipse().fill(Color.duoBlush)
                        .frame(width: 18*s, height: 12*s)
                        .position(x: ox + 42*s, y: oy + 78*s)
                    Ellipse().fill(Color.duoBlush)
                        .frame(width: 18*s, height: 12*s)
                        .position(x: ox + 98*s, y: oy + 78*s)
                    // Eyes
                    Circle().fill(Color.duoInk)
                        .frame(width: 11*s, height: 11*s)
                        .position(x: ox + 55*s, y: oy + 62*s)
                    Circle().fill(Color.duoInk)
                        .frame(width: 11*s, height: 11*s)
                        .position(x: ox + 85*s, y: oy + 62*s)
                    // Eye highlights
                    Circle().fill(Color.white)
                        .frame(width: 3*s, height: 3*s)
                        .position(x: ox + 57*s, y: oy + 60*s)
                    Circle().fill(Color.white)
                        .frame(width: 3*s, height: 3*s)
                        .position(x: ox + 87*s, y: oy + 60*s)
                }
            }

            // Smile
            BuddySmile()
                .stroke(Color.duoInk, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
        }
        .frame(width: 140, height: 160)
    }
}

// =====================================================================
// MARK: - 4. Side-by-side preview — paste this into Xcode to see render
// =====================================================================

#Preview("Duolingo lane — components") {
    ScrollView {
        VStack(spacing: 28) {
            // Header
            HStack {
                Text("ToothBuddy")
                    .font(.custom("Nunito-ExtraBold", size: 18))
                    .foregroundColor(.duoInk)
                Spacer()
                // Level badge
                HStack(spacing: 4) {
                    Text("🌱")
                    Text("LV 0")
                }
                .font(.custom("Nunito-ExtraBold", size: 11))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    ZStack {
                        Capsule().fill(Color.duoGreenShadow).offset(y: 3)
                        Capsule().fill(Color.duoGreen)
                            .overlay(Capsule().stroke(Color.duoInk, lineWidth: 2))
                    }
                )
            }
            .padding(.horizontal)

            BuddyView()

            DuoGoalCard(level: 0, completedSlots: 0, totalSlots: 2)
                .padding(.horizontal)

            VStack(spacing: 14) {
                DuoButton(title: "START BRUSHING!", action: {})
                DuoButton(title: "LOG SESSION", action: {},
                          color: .duoBlue, shadowColor: .duoBlueShadow)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 24)
    }
    .background(
        LinearGradient(colors: [.duoBgTopGreen, .duoBgBottomGreen],
                       startPoint: .top, endPoint: .bottom)
    )
}
