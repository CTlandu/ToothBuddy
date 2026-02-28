import UIKit

/// Triggers haptic feedback for key UX interactions.
@MainActor
enum SoundManager {

    // MARK: - Public interaction presets

    /// Called when the user taps "Start Brushing!"
    static func startBrushing() {
        impact(.medium)
    }

    /// Called when the user taps "Done Brushing!"
    static func doneBrushing() {
        notification(.success)
    }

    /// Called when the brushing zone changes.
    static func zoneChanged() {
        impact(.light)
    }

    /// Called when a tab bar button is tapped.
    static func tabTapped() {
        selection()
    }

    /// Called when the result sheet Done button is tapped.
    static func sheetDismissed() {
        impact(.light)
    }

    /// Called when an achievement is unlocked.
    static func achievementUnlocked() {
        notification(.success)
    }

    // MARK: - Private haptic helpers

    private static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.prepare()
        gen.impactOccurred()
    }

    private static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(type)
    }

    private static func selection() {
        let gen = UISelectionFeedbackGenerator()
        gen.prepare()
        gen.selectionChanged()
    }
}
