import AudioToolbox
import UIKit

/// Plays system sounds and triggers haptic feedback for key UX interactions.
/// All sounds are iOS built-in — zero extra file size, fully offline.
@MainActor
enum SoundManager {

    // MARK: - Public interaction presets

    /// Called when the user taps "Start Brushing!"
    static func startBrushing() {
        AudioServicesPlaySystemSound(1322)   // unlock chime — energetic, "let's go"
        impact(.medium)
    }

    /// Called when the user taps "Done Brushing!"
    static func doneBrushing() {
        AudioServicesPlaySystemSound(1304)   // payment success — achievement feel
        notification(.success)
    }

    /// Called when the brushing zone changes.
    static func zoneChanged() {
        AudioServicesPlaySystemSound(1057)   // camera shutter — clean, subtle tick
        impact(.light)
    }

    /// Called when a tab bar button is tapped.
    static func tabTapped() {
        AudioServicesPlaySystemSound(1519)   // Peek — barely-there, polished
        selection()
    }

    /// Called when the result sheet Done button is tapped.
    static func sheetDismissed() {
        AudioServicesPlaySystemSound(1520)   // Pop — satisfying close
        impact(.light)
    }

    /// Called when an achievement is unlocked.
    static func achievementUnlocked() {
        AudioServicesPlaySystemSound(1025)   // News Flash — fanfare feel
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
