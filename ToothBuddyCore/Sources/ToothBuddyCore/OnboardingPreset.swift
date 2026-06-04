import Foundation

/// Phase 1.5 / U2 — the optional "who's this phone mostly for?" onboarding preset.
///
/// IMPORTANT: a preset ONLY seeds default preference values — it never creates a runtime
/// behavior branch (no return of the old kid/adult `mode` split) and never touches
/// `ProfileMode`. Whatever a preset sets, the user can change item-by-item later in Settings.
/// Cases are plain (no String rawValue) so an internal identifier can never leak into the UI;
/// the cards render `displayName` / `caption`.
public enum OnboardingPreset: CaseIterable, Sendable {
    case kid
    case adult
    case intensive   // the north-star "dentist asked me to brush better" segment (braces, recurring cavities)

    /// User-facing card title.
    public var displayName: String {
        switch self {
        case .kid:       return String(localized: "For a kid")
        case .adult:     return String(localized: "For myself")
        case .intensive: return String(localized: "My dentist wants me to improve")
        }
    }

    /// User-facing card subtitle describing what the preset turns on.
    public var caption: String {
        switch self {
        case .kid:       return String(localized: "Playful coaching, the Sugar Bugs game, and celebration stars")
        case .adult:     return String(localized: "Quiet and minimal — just the essentials")
        case .intensive: return String(localized: "Longer 3-minute sessions, with a focus on covering every area")
        }
    }

    /// The bundle of preference defaults this preset seeds. Only these four are presetted;
    /// everything else keeps its all-on default to keep the choice low-friction.
    public var defaults: PreferenceDefaults {
        switch self {
        case .kid:
            return PreferenceDefaults(contentTone: .playful, gameEnabled: true,
                                      celebrationsEnabled: true, targetSeconds: 120)
        case .adult:
            return PreferenceDefaults(contentTone: .essentials, gameEnabled: false,
                                      celebrationsEnabled: false, targetSeconds: 120)
        case .intensive:
            return PreferenceDefaults(contentTone: .essentials, gameEnabled: false,
                                      celebrationsEnabled: true, targetSeconds: 180)
        }
    }
}

/// The subset of preferences an `OnboardingPreset` seeds. Pure value type so the mapping is
/// CLI-testable; the app layer applies it to `PreferencesStore`.
public struct PreferenceDefaults: Sendable, Equatable {
    public let contentTone: ContentTone
    public let gameEnabled: Bool
    public let celebrationsEnabled: Bool
    /// Only the two standard targets are valid (120 / 180).
    public let targetSeconds: Int

    public init(contentTone: ContentTone, gameEnabled: Bool,
                celebrationsEnabled: Bool, targetSeconds: Int) {
        self.contentTone = contentTone
        self.gameEnabled = gameEnabled
        self.celebrationsEnabled = celebrationsEnabled
        self.targetSeconds = targetSeconds
    }
}
