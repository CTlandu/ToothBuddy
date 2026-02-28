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

/// Cream gradient theme, evoking teeth/oral care.
enum Theme {
    // Background gradient: ivory -> cream -> warm cream
    static let backgroundStart = Color(red: 255/255, green: 251/255, blue: 245/255)  // #FFFBF5
    static let backgroundMid = Color(red: 248/255, green: 243/255, blue: 236/255)   // #F8F3EC
    static let backgroundEnd = Color(red: 240/255, green: 232/255, blue: 224/255)    // #F0E8E0

    static var appBackground: LinearGradient {
        LinearGradient(
            colors: [backgroundStart, backgroundMid, backgroundEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
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

    // Buttons: child lip color (soft coral / rose pink)
    static let startButtonStart = Color(red: 244/255, green: 166/255, blue: 166/255)   // #F4A6A6 soft coral
    static let startButtonEnd = Color(red: 232/255, green: 152/255, blue: 152/255)     // #E89898 deeper coral
    static let stopButtonStart = Color(red: 244/255, green: 63/255, blue: 94/255)
    static let stopButtonEnd = Color(red: 251/255, green: 146/255, blue: 60/255)

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

    // Accent: child lip color (soft coral pink)
    static let accentBlue = Color(red: 232/255, green: 180/255, blue: 184/255)  // #E8B4B8 dusty rose
    // Text on light background
    static let textPrimary = Color(red: 45/255, green: 45/255, blue: 45/255)
    static let textMuted = Color(red: 107/255, green: 107/255, blue: 107/255)
    static let textMutedStrong = Color(red: 80/255, green: 80/255, blue: 80/255)
    static let borderLight = Color.black.opacity(0.06)
    static let borderAccent = Color.black.opacity(0.15)
    static let surfaceFrost = Color.white.opacity(0.85)
    static let surfaceFrostBorder = Color.black.opacity(0.08)
}

/// Button style: scale down on press with a spring bounce back.
struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: configuration.isPressed)
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
                Text("⭐")
                    .font(.system(size: size))
                    .grayscale(i < count ? 0 : 1)
                    .opacity(i < count ? 1 : 0.3)
            }
        }
    }
}
