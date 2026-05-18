import Foundation

/// One bite-sized oral-health lesson (Spec 03 §5.4). Original content, no licensed IP.
public struct Lesson: Identifiable, Equatable, Sendable {
    public let id: Int          // stable order index (1-based)
    public let title: String
    public let body: String
    public init(id: Int, title: String, body: String) {
        self.id = id; self.title = title; self.body = body
    }
}

/// Bundled, ordered course. Earlier lessons unlock first.
public enum CourseLibrary {
    public static let all: [Lesson] = [
        .init(id: 1, title: "Why two minutes?",
              body: "Plaque is a sticky film of bacteria. Two minutes is the time it takes a normal brush to disturb it across every surface — thirty seconds rarely reaches the back teeth."),
        .init(id: 2, title: "The 45° angle",
              body: "Point the bristles toward the gumline at about 45 degrees. That's where plaque hides and where gum disease starts."),
        .init(id: 3, title: "Small circles, light pressure",
              body: "Scrubbing hard wears enamel and hurts gums. Gentle little circles clean better and last longer."),
        .init(id: 4, title: "Don't forget the insides",
              body: "The tongue-side of the lower front teeth is the most-missed spot. Tilt the brush vertically and sweep."),
        .init(id: 5, title: "Tongue & breath",
              body: "Most bad-breath bacteria live on the tongue. A few gentle back-to-front strokes make a big difference."),
        .init(id: 6, title: "Spit, don't rinse",
              body: "Rinsing with water washes away the fluoride that keeps protecting your teeth. Just spit out the extra."),
        .init(id: 7, title: "Brush heads wear out",
              body: "Frayed bristles clean poorly. Swap the head about every three months — sooner if it splays."),
        .init(id: 8, title: "Timing around food",
              body: "After acidic or sugary food, enamel is briefly soft. Wait ~30 minutes before brushing so you don't scrub it away."),
    ]
}

/// Pure progression rule (Spec 03 §5.4 / AC6): one lesson is unlocked to start, then a new
/// one every `lessonEvery` qualifying (active) days, capped at the course size.
public enum CourseProgression {
    public static let lessonEvery = 2

    public static func unlockedCount(activeDays: Int, totalLessons: Int) -> Int {
        guard totalLessons > 0 else { return 0 }
        let days = max(0, activeDays)
        return min(totalLessons, 1 + days / lessonEvery)
    }
}
