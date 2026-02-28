import SwiftUI

/// Design tokens matching the ToothBuddy JSX UI (dark blue gradient, sky blue accent).
enum Theme {
    // Background gradients (hex -> 0–1)
    static let backgroundStart = Color(red: 15/255, green: 23/255, blue: 42/255)
    static let backgroundMid = Color(red: 30/255, green: 58/255, blue: 95/255)
    static let backgroundEnd = Color(red: 14/255, green: 165/255, blue: 233/255)

    static var appBackground: LinearGradient {
        LinearGradient(
            colors: [backgroundStart, backgroundMid, backgroundEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Camera area: idle (darker) vs brushing (lighter)
    static let cameraIdleStart = Color(red: 30/255, green: 58/255, blue: 95/255)
    static let cameraIdleEnd = Color(red: 14/255, green: 165/255, blue: 233/255)
    static let cameraBrushingStart = Color(red: 14/255, green: 165/255, blue: 233/255)
    static let cameraBrushingMid = Color(red: 56/255, green: 189/255, blue: 248/255)
    static let cameraBrushingEnd = Color(red: 125/255, green: 211/255, blue: 252/255)

    static func cameraGradient(brushing: Bool) -> LinearGradient {
        if brushing {
            return LinearGradient(
                colors: [cameraBrushingStart, cameraBrushingMid, cameraBrushingEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [cameraIdleStart, Color(red: 3/255, green: 105/255, blue: 161/255), cameraIdleEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // Buttons
    static let startButtonStart = Color(red: 14/255, green: 165/255, blue: 233/255)
    static let startButtonEnd = Color(red: 99/255, green: 102/255, blue: 241/255)
    static let stopButtonStart = Color(red: 244/255, green: 63/255, blue: 94/255)
    static let stopButtonEnd = Color(red: 251/255, green: 146/255, blue: 60/255)

    static var startButtonGradient: LinearGradient {
        LinearGradient(colors: [startButtonStart, startButtonEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var stopButtonGradient: LinearGradient {
        LinearGradient(colors: [stopButtonStart, stopButtonEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // Cards
    static let cardBlueStart = Color(red: 29/255, green: 78/255, blue: 216/255)
    static let cardBlueEnd = Color(red: 14/255, green: 165/255, blue: 233/255)
    static var doneCardGradient: LinearGradient {
        LinearGradient(colors: [cardBlueStart, cardBlueEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static let streakOrangeStart = Color(red: 245/255, green: 158/255, blue: 11/255)
    static let streakOrangeEnd = Color(red: 249/255, green: 115/255, blue: 22/255)
    static var streakGradient: LinearGradient {
        LinearGradient(colors: [streakOrangeStart, streakOrangeEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static let accentBlue = Color(red: 56/255, green: 189/255, blue: 248/255)
    static let textMuted = Color.white.opacity(0.5)
    static let textMutedStrong = Color.white.opacity(0.75)
    static let borderLight = Color.white.opacity(0.08)
    static let borderAccent = Color.white.opacity(0.3)
    static let surfaceFrost = Color.white.opacity(0.07)
    static let surfaceFrostBorder = Color.white.opacity(0.1)
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
