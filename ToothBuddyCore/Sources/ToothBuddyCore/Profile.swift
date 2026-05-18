import Foundation

/// Fixed kid-friendly color palette. ToothBuddyCore stays platform-agnostic — the app
/// maps these to SwiftUI colors. Spec 02 §6.1.
public enum ProfileColor: String, Codable, CaseIterable, Sendable {
    case coral, tangerine, sunshine, lime, mint, sky, grape, bubblegum
}

/// Fixed kid-friendly avatar set. The raw value is a valid iOS 16 SF Symbol name
/// (`systemImage`); no photos are ever stored (privacy). Spec 02 §6.1.
public enum ProfileSymbol: String, Codable, CaseIterable, Sendable {
    case star, heart, bolt, leaf, paw, crown, sparkle, hare

    public var systemImage: String {
        switch self {
        case .star:    return "star.fill"
        case .heart:   return "heart.fill"
        case .bolt:    return "bolt.fill"
        case .leaf:    return "leaf.fill"
        case .paw:     return "pawprint.fill"
        case .crown:   return "crown.fill"
        case .sparkle: return "sparkles"
        case .hare:    return "hare.fill"
        }
    }
}

/// A brushing identity. Records, streak, achievements and reminders are all scoped to a
/// `Profile.id`. Spec 02 §6.1. `creatorLabel` is display-only (no permission meaning —
/// the peer Group model has no roles).
public struct Profile: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var colorTag: ProfileColor
    public var symbol: ProfileSymbol
    public var birthYear: Int?
    public var creatorLabel: String
    public var createdAt: Date
    public var modifiedAt: Date

    public init(id: UUID = UUID(),
                name: String,
                colorTag: ProfileColor,
                symbol: ProfileSymbol,
                birthYear: Int? = nil,
                creatorLabel: String = "",
                createdAt: Date = Date(),
                modifiedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.colorTag = colorTag
        self.symbol = symbol
        self.birthYear = birthYear
        self.creatorLabel = creatorLabel
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    /// Trimmed name if valid (non-empty, ≤ 24 chars after trimming), else nil.
    /// Single source of truth for name validation — used by every creation site.
    public static func validatedName(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 24 else { return nil }
        return trimmed
    }

    /// Default profile used by the zero-loss migration (Spec 02 §7.2 — auto-named "Me").
    public static func migrationDefault(id: UUID = UUID(), now: Date = Date()) -> Profile {
        Profile(id: id, name: "Me", colorTag: .sky, symbol: .star,
                creatorLabel: "", createdAt: now, modifiedAt: now)
    }
}
