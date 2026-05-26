import SwiftUI

/// Nunito font helpers — use these instead of .system() for consistent branding.
enum NunitoFont {
    static func regular(_ size: CGFloat) -> Font { .custom("Nunito-Regular",    size: size) }
    static func semiBold(_ size: CGFloat) -> Font { .custom("Nunito-SemiBold",  size: size) }
    static func bold(_ size: CGFloat) -> Font     { .custom("Nunito-Bold",      size: size) }
    static func extraBold(_ size: CGFloat) -> Font { .custom("Nunito-ExtraBold", size: size) }

    /// Default body font injected via .environment(\.font, NunitoFont.body)
    static let body: Font = .custom("Nunito-Regular", size: 16)
}

/// Theme tokens — now backed by Duolingo palette (see DuoTheme.swift).
/// Existing call sites stay untouched; values just shifted hue/saturation.
enum Theme {
    // Background gradient — paper-white → pale Duolingo green
    static let backgroundStart = Color(red: 0.969, green: 0.973, blue: 0.941)  // Duo.bgTop
    static let backgroundMid = Color(red: 0.953, green: 0.973, blue: 0.929)
    static let backgroundEnd = Color(red: 0.925, green: 0.969, blue: 0.910)    // Duo.bgBottom

    static var appBackground: LinearGradient {
        LinearGradient(
            colors: [backgroundStart, backgroundMid, backgroundEnd],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // Camera area: idle (cream) vs brushing (soft lip tint)
    static let cameraIdleStart = Color(red: 245/255, green: 238/255, blue: 228/255)
    static let cameraIdleEnd = Color(red: 235/255, green: 225/255, blue: 212/255)
    static let cameraBrushingStart = Color(red: 250/255, green: 232/255, blue: 232/255)  // soft rose
    static let cameraBrushingMid = Color(red: 245/255, green: 218/255, blue: 218/255)
    static let cameraBrushingEnd = Color(red: 238/255, green: 205/255, blue: 205/255)

    static func cameraGradient(brushing: Bool) -> LinearGradient {
        if brushing {
            return LinearGradient(
                colors: [cameraBrushingStart, cameraBrushingMid, cameraBrushingEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [backgroundStart, cameraIdleStart, cameraIdleEnd],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // Primary CTA — Duolingo green
    static let startButtonStart = Color(red: 0.345, green: 0.800, blue: 0.008)  // Duo.green
    static let startButtonEnd = Color(red: 0.247, green: 0.561, blue: 0.000)    // Duo.greenShadow
    // Stop / "done brushing" CTA — keep semantic warm red
    static let stopButtonStart = Color(red: 0.110, green: 0.690, blue: 0.965)   // Duo.blue (action-ready)
    static let stopButtonEnd = Color(red: 0.063, green: 0.514, blue: 0.714)     // Duo.blueShadow

    static var startButtonGradient: LinearGradient {
        LinearGradient(colors: [startButtonStart, startButtonEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var stopButtonGradient: LinearGradient {
        LinearGradient(colors: [stopButtonStart, stopButtonEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // Cards: same color family as buttons
    static let cardBlueStart = Color(red: 244/255, green: 166/255, blue: 166/255)
    static let cardBlueEnd = Color(red: 232/255, green: 152/255, blue: 152/255)
    static var doneCardGradient: LinearGradient {
        LinearGradient(colors: [cardBlueStart, cardBlueEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static let streakOrangeStart = Color(red: 245/255, green: 158/255, blue: 11/255)
    static let streakOrangeEnd = Color(red: 249/255, green: 115/255, blue: 22/255)
    static var streakGradient: LinearGradient {
        LinearGradient(colors: [streakOrangeStart, streakOrangeEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // Accent — Duolingo green (primary brand)
    static let accentBlue = Color(red: 0.345, green: 0.800, blue: 0.008)  // Duo.green
    // Text — Duolingo near-black ink
    static let textPrimary = Color(red: 0.169, green: 0.145, blue: 0.208)  // Duo.ink
    static let textMuted = Color(red: 0.443, green: 0.443, blue: 0.478)    // Duo.muted
    static let textMutedStrong = Color(red: 0.275, green: 0.243, blue: 0.314)
    static let borderLight = Color(red: 0.169, green: 0.145, blue: 0.208).opacity(0.12)
    static let borderAccent = Color(red: 0.169, green: 0.145, blue: 0.208).opacity(0.5)
    static let surfaceFrost = Color.white
    static let surfaceFrostBorder = Color(red: 0.169, green: 0.145, blue: 0.208).opacity(0.15)
}

/// Maps an SF Symbol name to a thematic accent color for icon display.
/// Used for achievement badges, level icons, and tip icons.
func symbolColor(for systemImage: String) -> Color {
    switch systemImage {
    case "flame.fill", "sunrise.fill":
        return Color(red: 249/255, green: 115/255, blue: 22/255)   // orange
    case "trophy.fill", "crown.fill":
        return Color(red: 251/255, green: 191/255, blue: 36/255)   // gold
    case "star.fill", "star.circle.fill":
        return Color(red: 251/255, green: 191/255, blue: 36/255)   // gold
    case "leaf.fill":
        return Color(red: 34/255, green: 197/255, blue: 94/255)    // green
    case "sparkles", "mouth.fill", "drop.fill":
        return Theme.startButtonEnd                                  // coral
    case "5.circle.fill", "10.circle.fill":
        return Color(red: 59/255, green: 130/255, blue: 246/255)   // blue
    default:
        return Theme.startButtonEnd
    }
}

/// Button style: scale down on press with a spring bounce back.
struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

/// Renders the custom tooth PNG asset at the given size.
/// Use this everywhere 🦷 would have been shown as a standalone icon.
struct ToothImageView: View {
    var size: CGFloat

    var body: some View {
        Image("tooth")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

/// Star rating 1–3, matching JSX StarRow (filled vs grayscale).
struct StarRatingView: View {
    let count: Int
    var maxCount: Int = 3
    var size: CGFloat = 22

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<maxCount, id: \.self) { i in
                Image(systemName: i < count ? "star.fill" : "star")
                    .font(.system(size: size, weight: .semibold))
                    .foregroundColor(i < count
                                     ? Color(red: 251/255, green: 191/255, blue: 36/255)
                                     : Color.gray.opacity(0.3))
            }
        }
    }
}
