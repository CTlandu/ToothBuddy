import Foundation
import ToothBuddyCore

/// Persists brushing records to a JSON file in Application Support for easy export and extension.
@MainActor
final class BrushingStore: ObservableObject {
    static let shared = BrushingStore()

    @Published private(set) var records: [BrushingRecord] = []

    /// Forgiving streak (Spec 01). Recomputed from `records` on every change.
    @Published private(set) var streak: StreakResult = .empty

    /// When non-nil, show "Record deleted. Undo" so the user can restore.
    @Published var lastDeletedRecord: BrushingRecord?

    /// True while a brushing session is active; used by ContentView to hide the tab bar.
    @Published var isBrushing = false

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
        defer { recomputeStreak() }
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

    /// Single source of truth for the streak. Pure math lives in ToothBuddyCore.
    private func recomputeStreak() {
        streak = StreakEngine.evaluate(records: records,
                                       now: Date(),
                                       config: .default,
                                       calendar: .current)
    }

    /// Number of sessions that started today (for "Today's goal").
    var recordsTodayCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return records.filter { calendar.startOfDay(for: $0.startDate) == today }.count
    }

    /// Current forgiving streak. Backed by `streak` (Spec 01); kept for existing call sites.
    var consecutiveDaysCount: Int { streak.currentStreak }

    /// Longest streak ever achieved (never decreases).
    var longestStreak: Int { streak.longestStreak }

    /// Average session duration in seconds (0 if no records).
    var averageDurationSeconds: Int {
        guard !records.isEmpty else { return 0 }
        let total = records.reduce(0) { $0 + $1.durationSeconds }
        return total / records.count
    }

    func add(_ record: BrushingRecord) {
        records.insert(record, at: 0)
        save()
        Task { @MainActor in
            GamificationStore.shared.checkAndUnlock(records: records)
        }
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
        recomputeStreak()   // every mutation path (add/delete/restore) calls save()
        guard let url = fileURL else { return }
        do {
            let data = try JSONEncoder().encode(records)
            try data.write(to: url)
        } catch { }
    }
}
