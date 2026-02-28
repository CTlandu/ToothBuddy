import Foundation

/// A single brushing session: start time, end time, and optional quality placeholder for future use.
struct BrushingRecord: Identifiable, Codable, Equatable {
    var id: UUID
    var startDate: Date
    var endDate: Date

    var durationSeconds: Int {
        Int(endDate.timeIntervalSince(startDate))
    }

    /// Stars 1–3 from duration: ≥2 min → 3, ≥1 min → 2, else 1.
    var starCount: Int {
        if durationSeconds >= 120 { return 3 }
        if durationSeconds >= 60 { return 2 }
        if durationSeconds > 0 { return 1 }
        return 0
    }

    init(id: UUID = UUID(), startDate: Date, endDate: Date) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
    }
}
