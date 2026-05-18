import Foundation

// MARK: - Model (Spec 03 §5.1)

public enum ContentKind: String, Codable, CaseIterable, Sendable {
    case fact, joke, tip, storyBeat
}

public enum ContentTone: String, Codable, Sendable {
    case playful      // kids: everything
    case essentials   // adult/quiet: terse tips only
}

public enum ContentAudience: String, Codable, Sendable {
    case kid, everyone
}

public enum ContentSeason: String, Codable, Sendable {
    case none, winter, spring, summer, autumn, halloween
}

public struct ContentItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let kind: ContentKind
    public let text: String
    public let audience: ContentAudience
    public let season: ContentSeason

    public init(id: UUID = UUID(), kind: ContentKind, text: String,
                audience: ContentAudience = .everyone, season: ContentSeason = .none) {
        self.id = id; self.kind = kind; self.text = text
        self.audience = audience; self.season = season
    }
}

// MARK: - Bundled, original, offline content (Spec 03 §5.1; no licensed IP)

public enum ContentLibrary {
    public static let all: [ContentItem] = [
        // Facts
        .init(kind: .fact, text: "Tooth enamel is the hardest substance your body makes — even harder than bone!", audience: .everyone),
        .init(kind: .fact, text: "Your mouth makes about a swimming-pool's worth of spit over a lifetime. It washes away sugar bugs!", audience: .kid),
        .init(kind: .fact, text: "No two people have the same set of teeth — they're as unique as a fingerprint.", audience: .everyone),
        .init(kind: .fact, text: "A snail can have thousands of tiny teeth on its tongue. You only get 32 — take care of them!", audience: .kid),
        .init(kind: .fact, text: "Brushing for two minutes removes far more plaque than a quick thirty-second swipe.", audience: .everyone),
        .init(kind: .fact, text: "Reindeer have great teeth for chewing icy lichen — keep yours strong this winter too!", audience: .kid, season: .winter),
        .init(kind: .fact, text: "Spring smiles: flowers bloom and so does fresh breath — brush away winter's plaque!", audience: .kid, season: .spring),
        .init(kind: .fact, text: "Summer popsicles are fun, but sugar lingers — a good night brush keeps cavities away.", audience: .everyone, season: .summer),

        // Jokes
        .init(kind: .joke, text: "What did the tooth say to the dentist? You're filling me with joy!", audience: .kid),
        .init(kind: .joke, text: "Why did the toothbrush cross the road? To get to the other bristle!", audience: .kid),
        .init(kind: .joke, text: "What's a tooth's favorite music? Anything with good plaque-beat!", audience: .kid),
        .init(kind: .joke, text: "Why was the ghost's smile so spooky-clean? It always brushed before haunting!", audience: .kid, season: .halloween),
        .init(kind: .joke, text: "What do you call a bear with no teeth? A gummy bear!", audience: .kid),

        // Tips
        .init(kind: .tip, text: "Tilt the brush at 45 degrees toward the gumline and use small gentle circles.", audience: .everyone),
        .init(kind: .tip, text: "Don't forget the chewing surfaces and the backs of your front teeth.", audience: .everyone),
        .init(kind: .tip, text: "Brush your tongue too — it holds the bacteria that cause bad breath.", audience: .everyone),
        .init(kind: .tip, text: "Spit, don't rinse: leaving a little toothpaste protects your enamel longer.", audience: .everyone),
        .init(kind: .tip, text: "Replace your brush head every three months, or sooner if it looks frayed.", audience: .everyone),
        .init(kind: .tip, text: "Wait 30 minutes after sugary or acidic food before brushing.", audience: .everyone),
        .init(kind: .tip, text: "Autumn means more snacking — keep a brush and a glass of water handy after treats.", audience: .everyone, season: .autumn),

        // Story beats
        .init(kind: .storyBeat, text: "Captain Molar boards the Sugar Pirate ship — scrub the upper deck (top teeth) first!", audience: .kid),
        .init(kind: .storyBeat, text: "The cavity goblins are hiding in the back caves. Sweep them out with tiny circles!", audience: .kid),
        .init(kind: .storyBeat, text: "Almost there, hero — polish the shiny fronts so your smile can blind the dragon!", audience: .kid),
        .init(kind: .storyBeat, text: "Final mission: rinse the tongue bridge and the kingdom is safe till tonight.", audience: .kid),
        .init(kind: .storyBeat, text: "Frosty the Plaque Yeti melts away when you brush the lower-left snow cave!", audience: .kid, season: .winter),
    ]
}

// MARK: - Pure, deterministic selection (Spec 03 §5.2 / AC1–AC4)

public enum ContentSelector {

    public static func season(for date: Date, calendar: Calendar) -> ContentSeason {
        let c = calendar.dateComponents([.month, .day], from: date)
        let m = c.month ?? 1, d = c.day ?? 1
        if m == 10, d >= 24 { return .halloween }
        switch m {
        case 12, 1, 2:  return .winter
        case 3, 4, 5:   return .spring
        case 6, 7, 8:   return .summer
        default:        return .autumn   // 9, 10 (pre-24), 11
        }
    }

    private static func daysSinceReference(_ date: Date, _ calendar: Calendar) -> Int {
        Int(calendar.startOfDay(for: date).timeIntervalSinceReferenceDate / 86_400)
    }

    /// Deterministic pick. Tone gates kinds; seasonal items are preferred; an item in
    /// `history` is never returned until that pool is exhausted, then it resets.
    public static func pick(kind: ContentKind, now: Date, history: [UUID],
                            tone: ContentTone, calendar: Calendar) -> ContentItem? {
        // Tone: essentials → only neutral-audience tips, never jokes/story.
        if tone == .essentials, kind != .tip { return nil }

        var candidates = ContentLibrary.all.filter { $0.kind == kind }
        if tone == .essentials {
            candidates = candidates.filter { $0.audience == .everyone }
        }
        guard !candidates.isEmpty else { return nil }

        let cur = season(for: now, calendar: calendar)
        let seasonal = candidates.filter { $0.season == cur }
        let neutral  = candidates.filter { $0.season == .none }

        // Preference order: seasonal → neutral → any.
        for var pool in [seasonal, neutral, candidates] where !pool.isEmpty {
            pool.sort { $0.id.uuidString < $1.id.uuidString }   // stable order
            var fresh = pool.filter { !history.contains($0.id) }
            if fresh.isEmpty { fresh = pool }                   // pool exhausted → reset
            let seed = daysSinceReference(now, calendar) &* 4 &+ kindIndex(kind)
            let idx = ((seed % fresh.count) + fresh.count) % fresh.count
            return fresh[idx]
        }
        return nil
    }

    private static func kindIndex(_ k: ContentKind) -> Int {
        switch k { case .fact: return 0; case .joke: return 1
                   case .tip: return 2; case .storyBeat: return 3 }
    }
}
