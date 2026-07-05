import Foundation

/// Collectible rarity. Higher weight = more likely to be granted.
public enum Rarity: String, Codable, CaseIterable, Sendable, Equatable {
    case common, rare, legendary

    public var weight: Int {
        switch self {
        case .common:    return 6
        case .rare:      return 3
        case .legendary: return 1
        }
    }
}

/// One item in Buddy's collection (a friend / souvenir Buddy brings back).
/// Content model only — final names/art are an implementation content decision; `id` is stable.
public struct Collectible: Identifiable, Equatable, Sendable, Codable {
    public let id: String
    public let name: String
    public let rarity: Rarity

    public init(id: String, name: String, rarity: Rarity) {
        self.id = id
        self.name = name
        self.rarity = rarity
    }

    /// v1 starter set — finite-but-large so a young kid doesn't exhaust it quickly.
    /// ~24 items across three rarities. Names are placeholders for the art pass.
    public static let all: [Collectible] = [
        // Common (12)
        .init(id: "c01", name: "Bubbly", rarity: .common),
        .init(id: "c02", name: "Minty", rarity: .common),
        .init(id: "c03", name: "Sudsy", rarity: .common),
        .init(id: "c04", name: "Pearl", rarity: .common),
        .init(id: "c05", name: "Sparkle Seed", rarity: .common),
        .init(id: "c06", name: "Little Cloud", rarity: .common),
        .init(id: "c07", name: "Foam Frog", rarity: .common),
        .init(id: "c08", name: "Sunny Cup", rarity: .common),
        .init(id: "c09", name: "Blue Drop", rarity: .common),
        .init(id: "c10", name: "Fuzzy Sock", rarity: .common),
        .init(id: "c11", name: "Star Pebble", rarity: .common),
        .init(id: "c12", name: "Toothy Snail", rarity: .common),
        // Rare (8)
        .init(id: "r01", name: "Rainbow Floss", rarity: .rare),
        .init(id: "r02", name: "Captain Brush", rarity: .rare),
        .init(id: "r03", name: "Moon Moth", rarity: .rare),
        .init(id: "r04", name: "Glow Fish", rarity: .rare),
        .init(id: "r05", name: "Cozy Fox", rarity: .rare),
        .init(id: "r06", name: "Bubble Whale", rarity: .rare),
        .init(id: "r07", name: "Sky Kite", rarity: .rare),
        .init(id: "r08", name: "Mint Dragonfly", rarity: .rare),
        // Legendary (4)
        .init(id: "l01", name: "Golden Molar", rarity: .legendary),
        .init(id: "l02", name: "Aurora Buddy", rarity: .legendary),
        .init(id: "l03", name: "Comet Cat", rarity: .legendary),
        .init(id: "l04", name: "Crystal Guardian", rarity: .legendary),
    ]
}
