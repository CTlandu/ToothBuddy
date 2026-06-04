import Foundation
import Combine
import ToothBuddyCore

/// Central per-device preferences (U7). Replaces the kid/adult mode split: every feature
/// defaults ON and the user turns off what they don't want. Backed by UserDefaults; inject a
/// throwaway suite in tests. Absorbs the previously-scattered `voiceCoachMuted` and content tone.
@MainActor
final class PreferencesStore: ObservableObject {
    static let shared = PreferencesStore()

    enum SessionMode: String, CaseIterable, Sendable { case audio, mirror }

    @Published var gameEnabled: Bool            { didSet { d.set(gameEnabled, forKey: K.game) } }
    @Published var celebrationsEnabled: Bool    { didSet { d.set(celebrationsEnabled, forKey: K.celebrations) } }
    @Published var showLevelAchievements: Bool  { didSet { d.set(showLevelAchievements, forKey: K.levels) } }
    @Published var showHabitCurve: Bool         { didSet { d.set(showHabitCurve, forKey: K.habit) } }
    @Published var voiceEnabled: Bool           { didSet { d.set(voiceEnabled, forKey: K.voice) } }
    @Published var healthConnectEnabled: Bool   { didSet { d.set(healthConnectEnabled, forKey: K.health) } }
    @Published var sessionMode: SessionMode     { didSet { d.set(sessionMode.rawValue, forKey: K.mode) } }
    @Published var contentTone: ContentTone     { didSet { d.set(contentTone.rawValue, forKey: K.tone) } }
    @Published var targetSeconds: Int           { didSet { d.set(targetSeconds, forKey: K.target) } }

    private let d: UserDefaults

    /// U2 — apply an onboarding preset's seeded defaults. Only sets the four presetted
    /// fields; everything else keeps its current value. targetSeconds is re-clamped to a
    /// valid standard (120/180) defensively.
    func apply(_ defaults: PreferenceDefaults) {
        contentTone = defaults.contentTone
        gameEnabled = defaults.gameEnabled
        celebrationsEnabled = defaults.celebrationsEnabled
        targetSeconds = defaults.targetSeconds == 180 ? 180 : 120
    }

    init(defaults: UserDefaults = .standard) {
        d = defaults
        gameEnabled = d.object(forKey: K.game) as? Bool ?? true
        celebrationsEnabled = d.object(forKey: K.celebrations) as? Bool ?? true
        showLevelAchievements = d.object(forKey: K.levels) as? Bool ?? true
        showHabitCurve = d.object(forKey: K.habit) as? Bool ?? true
        // Migrate the old standalone mute toggle: voiceEnabled defaults to !voiceCoachMuted.
        voiceEnabled = d.object(forKey: K.voice) as? Bool ?? !d.bool(forKey: "voiceCoachMuted")
        healthConnectEnabled = d.object(forKey: K.health) as? Bool ?? true
        sessionMode = SessionMode(rawValue: d.string(forKey: K.mode) ?? "") ?? .mirror
        contentTone = ContentTone(rawValue: d.string(forKey: K.tone) ?? "") ?? .playful
        // Only the two standard targets are valid; anything else falls back to 2 minutes.
        targetSeconds = (d.object(forKey: K.target) as? Int) == 180 ? 180 : 120
    }

    private enum K {
        static let game = "pref.gameEnabled"
        static let celebrations = "pref.celebrationsEnabled"
        static let levels = "pref.showLevelAchievements"
        static let habit = "pref.showHabitCurve"
        static let voice = "pref.voiceEnabled"
        static let health = "pref.healthConnectEnabled"
        static let mode = "pref.sessionMode"
        static let tone = "pref.contentTone"
        static let target = "pref.targetSeconds"
    }
}
