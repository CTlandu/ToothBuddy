// MARK: - DuoComponents.swift
//
// Reusable Duolingo-style primitives. Each component is a thin wrapper over
// SwiftUI that applies the signature "chunky outline + 4pt depth shadow +
// press-to-flatten" treatment.

import SwiftUI

// =====================================================================
// MARK: - DuoButton — primary CTA with depth + press animation
// =====================================================================

/// Color/role choice for `DuoButton`.
enum DuoButtonRole {
    case primary       // green
    case secondary     // blue
    case warning       // yellow
    case danger        // red

    var face: Color {
        switch self {
        case .primary:   return Duo.green
        case .secondary: return Duo.blue
        case .warning:   return Duo.yellow
        case .danger:    return Duo.red
        }
    }
    var shadow: Color {
        switch self {
        case .primary:   return Duo.greenShadow
        case .secondary: return Duo.blueShadow
        case .warning:   return Duo.yellowShadow
        case .danger:    return Duo.redShadow
        }
    }
    var foreground: Color {
        // Yellow needs ink text for legibility; everything else white.
        self == .warning ? Duo.ink : .white
    }
}

struct DuoButton: View {
    let title: String
    let role: DuoButtonRole
    let action: () -> Void
    var compact: Bool = false

    init(_ title: String,
         role: DuoButtonRole = .primary,
         compact: Bool = false,
         action: @escaping () -> Void) {
        self.title = title
        self.role = role
        self.compact = compact
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Duo.Fnt.ebd(compact ? 14 : 16))
                .tracking(0.5)
                .foregroundColor(role.foreground)
                .padding(.vertical, compact ? 10 : 14)
                .padding(.horizontal, 18)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(DuoButtonStyle(role: role))
    }
}

/// Underlying ButtonStyle — applies the offset shadow + press-to-flatten.
struct DuoButtonStyle: ButtonStyle {
    let role: DuoButtonRole

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: Duo.cornerRadius, style: .continuous)
                .fill(role.shadow)
                .offset(y: configuration.isPressed ? 0 : Duo.depthOffset)

            configuration.label
                .background(
                    RoundedRectangle(cornerRadius: Duo.cornerRadius, style: .continuous)
                        .fill(role.face)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Duo.cornerRadius, style: .continuous)
                        .stroke(Duo.ink, lineWidth: Duo.outlineWidth)
                )
                .offset(y: configuration.isPressed ? Duo.depthOffset : 0)
        }
        .animation(.spring(response: 0.18, dampingFraction: 0.7),
                   value: configuration.isPressed)
    }
}

// =====================================================================
// MARK: - DuoCard — chunky outlined surface
// =====================================================================

/// Wraps any content in a Duolingo-style chunky card (outlined + depth shadow).
struct DuoCard<Content: View>: View {
    var face: Color = .white
    var padding: CGFloat = 14
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Duo.cornerRadius, style: .continuous)
                    .fill(face)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Duo.cornerRadius, style: .continuous)
                    .stroke(Duo.ink, lineWidth: Duo.outlineWidth)
            )
            .background(
                RoundedRectangle(cornerRadius: Duo.cornerRadius, style: .continuous)
                    .fill(Duo.ink)
                    .offset(y: Duo.depthOffset)
            )
    }
}

/// `.duoCard()` view modifier — same look, applied to whatever the modifier wraps.
struct DuoCardModifier: ViewModifier {
    var face: Color = .white
    var padding: CGFloat = 14

    func body(content: Content) -> some View {
        DuoCard(face: face, padding: padding) { content }
    }
}

extension View {
    func duoCard(face: Color = .white, padding: CGFloat = 14) -> some View {
        modifier(DuoCardModifier(face: face, padding: padding))
    }
}

// =====================================================================
// MARK: - DuoBadge — pill with depth (level / streak / count)
// =====================================================================

/// A chunky outlined capsule, often used for level / streak indicators.
struct DuoBadge: View {
    let text: String
    var leadingEmoji: String? = nil
    var role: DuoButtonRole = .primary

    var body: some View {
        ZStack {
            Capsule().fill(role.shadow).offset(y: 3)
            HStack(spacing: 4) {
                if let e = leadingEmoji { Text(e) }
                Text(text)
                    .font(Duo.Fnt.ebd(11))
                    .tracking(0.5)
                    .foregroundColor(role.foreground)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Capsule().fill(role.face))
            .overlay(Capsule().stroke(Duo.ink, lineWidth: Duo.outlineWidth))
        }
        .fixedSize(horizontal: true, vertical: true)
    }
}

// =====================================================================
// MARK: - DuoProgressBar — segmented "pips" or a fill bar
// =====================================================================

struct DuoProgressPips: View {
    let completed: Int
    let total: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { idx in
                RoundedRectangle(cornerRadius: 5)
                    .fill(idx < completed ? Duo.green : Duo.stoneLight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Duo.ink, lineWidth: 1.5)
                    )
                    .frame(height: 10)
            }
        }
    }
}

// =====================================================================
// MARK: - DuoWordmark — chunky logo text (Duolingo-Feather-Bold flavor)
// =====================================================================

/// Logo-style display text — Nunito ExtraBold with crisp 1pt ink outline
/// (simulated via 4 axis-aligned 0-radius shadows) plus 4pt ink drop shadow.
/// Use this for the app wordmark, big celebratory labels, anywhere the text
/// needs to read as a chunky brand element rather than body copy.
struct DuoWordmark: View {
    let text: String
    let size: CGFloat
    var face: Color = .white
    var ink: Color = Duo.ink
    var tracking: CGFloat = 0.5
    var dropOffset: CGFloat = 4

    var body: some View {
        ZStack {
            // Chunky drop shadow — same word offset down, ink-colored.
            Text(text)
                .font(Duo.Fnt.ebd(size))
                .tracking(tracking)
                .foregroundColor(ink)
                .offset(y: dropOffset)

            // Foreground word with simulated 1pt outline via 4 axis-aligned
            // 0-radius shadows. (SwiftUI Text has no native stroke modifier.)
            Text(text)
                .font(Duo.Fnt.ebd(size))
                .tracking(tracking)
                .foregroundColor(face)
                .shadow(color: ink, radius: 0, x:  1, y:  0)
                .shadow(color: ink, radius: 0, x: -1, y:  0)
                .shadow(color: ink, radius: 0, x:  0, y:  1)
                .shadow(color: ink, radius: 0, x:  0, y: -1)
        }
        .fixedSize()
    }
}

// =====================================================================
// MARK: - DuoSectionHeader — small uppercase label above sections
// =====================================================================

struct DuoSectionHeader: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(Duo.Fnt.ebd(11))
                .tracking(0.8)
                .foregroundColor(Duo.ink)
            Spacer()
            if let t = trailing {
                Text(t)
                    .font(Duo.Fnt.ebd(11))
                    .foregroundColor(Duo.muted)
            }
        }
    }
}
