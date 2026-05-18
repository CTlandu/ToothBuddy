import Foundation
import CoreData
import Combine
import ToothBuddyCore

/// Active-profile-scoped brushing store, backed by Core Data (Spec 02). Public surface is
/// kept compatible with existing call sites (records / streak / add / delete / undo).
@MainActor
final class BrushingStore: ObservableObject {
    static let shared = BrushingStore()

    /// The ACTIVE profile's records, newest first.
    @Published private(set) var records: [BrushingRecord] = []
    /// Forgiving streak (Spec 01) for the active profile.
    @Published private(set) var streak: StreakResult = .empty
    /// When non-nil, show "Record deleted. Undo".
    @Published var lastDeletedRecord: BrushingRecord?
    /// True while a session is active; ContentView hides the tab bar.
    @Published var isBrushing = false

    private let ctx: NSManagedObjectContext
    private let profiles: ProfileStore
    private var cancellables: Set<AnyCancellable> = []
    private let migratedKey = "ToothBuddy.didMigrateToCoreData_v1"
    private let legacyAchievementsKey = "ToothBuddy.unlockedAchievements"

    init(controller: PersistenceController = .shared, profiles: ProfileStore = .shared) {
        ctx = controller.viewContext
        self.profiles = profiles
        runMigrationIfNeeded()
        reload()
        profiles.$activeProfileID
            .dropFirst()
            .sink { [weak self] _ in self?.reload() }
            .store(in: &cancellables)
    }

    // MARK: Derived

    var consecutiveDaysCount: Int { streak.currentStreak }
    var longestStreak: Int { streak.longestStreak }

    var recordsTodayCount: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return records.filter { cal.startOfDay(for: $0.startDate) == today }.count
    }

    var averageDurationSeconds: Int {
        guard !records.isEmpty else { return 0 }
        return records.reduce(0) { $0 + $1.durationSeconds } / records.count
    }

    // MARK: Load

    func reload() {
        guard let pid = profiles.activeProfileID else {
            records = []; streak = .empty; return
        }
        let req = NSFetchRequest<CDBrushingRecord>(entityName: "CDBrushingRecord")
        req.predicate = NSPredicate(format: "profile.id == %@", pid as CVarArg)
        req.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        let rows = (try? ctx.fetch(req)) ?? []
        records = rows.compactMap { $0.toDTO() }
        recomputeStreak()
    }

    private func recomputeStreak() {
        streak = StreakEngine.evaluate(records: records, now: Date(),
                                       config: .default, calendar: .current)
    }

    // MARK: Mutations

    /// Record a completed session for the active profile.
    func recordSession(start: Date, end: Date) {
        guard let pid = profiles.activeProfileID,
              let cdp = profiles.managedProfile(pid) else { return }
        let r = CDBrushingRecord(context: ctx)
        r.id = UUID(); r.startDate = start; r.endDate = end
        r.modifiedAt = Date(); r.profile = cdp
        saveAndReload()
        GamificationStore.shared.checkAndUnlock(records: records)
    }

    func deleteRecord(id: UUID) {
        let req = NSFetchRequest<CDBrushingRecord>(entityName: "CDBrushingRecord")
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        req.fetchLimit = 1
        guard let row = (try? ctx.fetch(req))?.first else { return }
        lastDeletedRecord = row.toDTO()
        ctx.delete(row)
        saveAndReload()
    }

    func restoreLastDeleted() {
        guard let rec = lastDeletedRecord,
              let cdp = profiles.managedProfile(rec.profileID) else { return }
        let r = CDBrushingRecord(context: ctx)
        r.id = rec.id; r.startDate = rec.startDate; r.endDate = rec.endDate
        r.modifiedAt = Date(); r.profile = cdp
        lastDeletedRecord = nil
        saveAndReload()
    }

    func clearLastDeleted() { lastDeletedRecord = nil }

    private func saveAndReload() {
        if ctx.hasChanges { try? ctx.save() }
        reload()
    }

    // MARK: Zero-loss migration (Spec 02 §7.2 / AC1) — idempotent.

    private func runMigrationIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: migratedKey) else { return }
        defer { defaults.set(true, forKey: migratedKey) }

        guard let support = FileManager.default.urls(for: .applicationSupportDirectory,
                                                     in: .userDomainMask).first else { return }
        let legacyURL = support.appendingPathComponent("ToothBuddy/brushing_records.json")
        guard let data = try? Data(contentsOf: legacyURL),
              let legacy = try? MigrationTransform.decodeLegacy(data),
              !legacy.isEmpty else { return }   // fresh install → nothing to migrate

        // Create the default profile and own all legacy records.
        guard let def = profiles.createProfile(name: "Me", color: .sky, symbol: .star,
                                               makeActive: true),
              let cdp = profiles.managedProfile(def.id) else { return }
        for rec in MigrationTransform.migrate(legacy: legacy, defaultProfileID: def.id) {
            let r = CDBrushingRecord(context: ctx)
            r.id = rec.id; r.startDate = rec.startDate; r.endDate = rec.endDate
            r.modifiedAt = Date(); r.profile = cdp
        }
        // Migrate legacy global achievements → this profile.
        if let aData = defaults.data(forKey: legacyAchievementsKey),
           let ids = try? JSONDecoder().decode([String].self, from: aData) {
            for aid in ids {
                let a = CDAchievementUnlock(context: ctx)
                a.achievementID = aid; a.unlockedAt = Date(); a.profile = cdp
            }
        }
        if ctx.hasChanges { try? ctx.save() }
        // Legacy JSON is intentionally left on disk as a one-release backup.
    }
}
