import Foundation
import CoreData
import Combine
import ToothBuddyCore

/// Active-profile-scoped brushing store, backed by Core Data (Spec 02). Public surface is
/// kept compatible with existing call sites (records / streak / add / delete / undo).
@MainActor
final class BrushingStore: ObservableObject {
    static let shared: BrushingStore = {
        let s = BrushingStore()
        s.widgetSyncEnabled = true   // only the shared instance drives the widget
        return s
    }()

    /// Spec 05 §6.4 — true only on the fully-constructed shared singleton. Checked in
    /// `reload()` so the in-`init()` reload does NOT touch `BrushingStore.shared`
    /// (that would reentrantly evaluate the static during its own initialization and
    /// trap at launch); unit-test stores keep it false so they stay isolated.
    private var widgetSyncEnabled = false

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
        // Spec 05 §6.4 — keep the widget snapshot in lock-step with every change that
        // flows through reload() (session logged, profile switched). Shared instance
        // only, so unit tests with their own store stay isolated.
        defer { if widgetSyncEnabled { WidgetBridge.refresh() } }
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

    /// Every profile's records (for the Group dashboard, Spec 02 §6.5).
    func allRecords() -> [BrushingRecord] {
        let req = NSFetchRequest<CDBrushingRecord>(entityName: "CDBrushingRecord")
        req.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        return ((try? ctx.fetch(req)) ?? []).compactMap { $0.toDTO() }
    }

    // MARK: Mutations

    /// Record a completed session for the active profile.
    func recordSession(start: Date, end: Date) {
        guard let pid = profiles.activeProfileID,
              let cdp = profiles.managedProfile(pid) else { return }
        let r = CDBrushingRecord(context: ctx)
        let sid = UUID()
        r.id = sid; r.startDate = start; r.endDate = end
        r.modifiedAt = Date(); r.profile = cdp
        saveAndReload()
        GamificationStore.shared.checkAndUnlock(records: records)
        // Spec 05 §6.6 — opt-in, idempotent Health export (no-op unless authorized).
        if widgetSyncEnabled {
            HealthExporter.shared.exportIfNeeded(sessionID: sid, start: start,
                                                 end: end, isCompleted: true)
        }
    }

    /// One-tap / Siri quick-log (Spec 05 §6.3). Idempotent within the current AM/PM
    /// slot — a second call in the same slot does not duplicate or inflate the streak.
    /// Logs a ~2-minute session ending at `now`. Does NOT affect the in-app flow.
    @discardableResult
    func quickLogForCurrentSlot(now: Date = Date()) -> QuickLogDecision {
        guard let pid = profiles.activeProfileID,
              let cdp = profiles.managedProfile(pid) else { return .noProfile }
        reload()   // ensure `records` reflects the active profile (intent cold-launch)
        if QuickLog.isCurrentSlotLogged(records: records, profileID: pid,
                                        now: now, calendar: .current) {
            return .alreadyLoggedThisSlot
        }
        let r = CDBrushingRecord(context: ctx)
        let sid = UUID()
        let start = now.addingTimeInterval(-120)
        r.id = sid
        r.startDate = start
        r.endDate = now
        r.modifiedAt = Date(); r.profile = cdp
        saveAndReload()
        GamificationStore.shared.checkAndUnlock(records: records)
        if widgetSyncEnabled {
            HealthExporter.shared.exportIfNeeded(sessionID: sid, start: start,
                                                 end: now, isCompleted: true)
        }
        return .logged
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
