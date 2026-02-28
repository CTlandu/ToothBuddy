import Foundation

/// Persists brushing records to a JSON file in Application Support for easy export and extension.
@MainActor
final class BrushingStore: ObservableObject {
    static let shared = BrushingStore()

    @Published private(set) var records: [BrushingRecord] = []

    /// When non-nil, show "Record deleted. Undo" so the user can restore.
    @Published var lastDeletedRecord: BrushingRecord?

    private let fileName = "brushing_records.json"
    private var fileURL: URL? {
        guard let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let dir = support.appendingPathComponent("ToothBuddy", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent(fileName)
    }

    private init() {
        load()
    }

    func load() {
        guard let url = fileURL, FileManager.default.fileExists(atPath: url.path) else {
            records = []
            return
        }
        do {
            let data = try Data(contentsOf: url)
            records = try JSONDecoder().decode([BrushingRecord].self, from: data)
            records.sort { $0.startDate > $1.startDate }
        } catch {
            records = []
        }
    }

    /// Number of sessions that started today (for "Today's goal").
    var recordsTodayCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return records.filter { calendar.startOfDay(for: $0.startDate) == today }.count
    }

    /// Consecutive days with at least one session (today = day 1 if there is a session).
    var consecutiveDaysCount: Int {
        let calendar = Calendar.current
        let daysWithSessions = Set(records.map { calendar.startOfDay(for: $0.startDate) })
        var day = calendar.startOfDay(for: Date())
        var streak = 0
        while daysWithSessions.contains(day) {
            streak += 1
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return streak
    }

    /// Average session duration in seconds (0 if no records).
    var averageDurationSeconds: Int {
        guard !records.isEmpty else { return 0 }
        let total = records.reduce(0) { $0 + $1.durationSeconds }
        return total / records.count
    }

    func add(_ record: BrushingRecord) {
        records.insert(record, at: 0)
        save()
    }

    /// Removes the record by id, stores it in lastDeletedRecord for undo. Call restoreLastDeleted() to undo.
    func deleteRecord(id: UUID) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        lastDeletedRecord = records.remove(at: index)
        save()
    }

    /// Restores the last deleted record and clears lastDeletedRecord.
    func restoreLastDeleted() {
        guard let record = lastDeletedRecord else { return }
        records.insert(record, at: 0)
        lastDeletedRecord = nil
        save()
    }

    /// Clears the last-deleted reference without restoring (e.g. user dismissed the undo banner).
    func clearLastDeleted() {
        lastDeletedRecord = nil
    }

    private func save() {
        guard let url = fileURL else { return }
        do {
            let data = try JSONEncoder().encode(records)
            try data.write(to: url)
        } catch { }
    }
}
