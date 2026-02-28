import SwiftUI

/// Small tooth emojis that float gently around the edges of the camera frame (bubble-like, semi-transparent).
struct FloatingToothBubblesView: View {
    /// Base positions as fractions of width/height (0...1), and phase for animation.
    private static let bubbles: [(x: CGFloat, y: CGFloat, phase: Double, size: CGFloat)] = [
        (0.15, 0.2, 0, 18),
        (0.85, 0.25, 1.2, 22),
        (0.12, 0.6, 2.1, 16),
        (0.88, 0.55, 0.7, 20),
        (0.25, 0.85, 1.5, 14),
        (0.75, 0.82, 2.8, 18),
    ]

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 0.04)) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                ZStack {
                    ForEach(Array(Self.bubbles.enumerated()), id: \.offset) { _, b in
                        Text("🦷")
                            .font(.system(size: b.size))
                            .opacity(0.55)
                            .position(
                                x: geo.size.width * b.x + 6 * sin(t + b.phase) + 4 * cos(t * 0.7 + b.phase),
                                y: geo.size.height * b.y + 5 * cos(t * 1.1 + b.phase) + 3 * sin(t * 0.5 + b.phase)
                            )
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}
