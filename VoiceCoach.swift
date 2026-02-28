import AVFoundation
import Foundation

/// Manages text-to-speech for brushing zone announcements.
/// Persists the muted state so the user's preference is remembered across sessions.
@MainActor
final class VoiceCoach: ObservableObject {
    static let shared = VoiceCoach()

    @Published var isMuted: Bool {
        didSet { UserDefaults.standard.set(isMuted, forKey: "voiceCoachMuted") }
    }

    private let synthesizer = AVSpeechSynthesizer()

    private init() {
        isMuted = UserDefaults.standard.bool(forKey: "voiceCoachMuted")
    }

    /// Speaks the given text if not muted.
    func speak(_ text: String) {
        guard !isMuted else { return }
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        // Samantha Enhanced — clear, natural, widely available on iOS.
        // Falls back to system default en-US if not installed.
        utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.voice.enhanced.en-US.Samantha")
            ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.46
        utterance.pitchMultiplier = 1.08
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }

    /// Immediately stops any ongoing speech.
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
