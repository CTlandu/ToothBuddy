import Foundation
import CoreData
import Combine
import ToothBuddyCore

/// The retention loop's app-facing surface (U6). Derives the two-ring day, forgiving-streak
/// freeze economy, collection progress, and the overnight morning-reveal from the honest brush
/// record via ToothBuddyCore engines. Owns the persisted collection (`CDCollectibleUnlock`,
/// CloudKit-safe) and the device-local overnight state (`UserDefaults`). Mirrors the shape of
/// `GamificationStore` (injected triple, profile-scoped rows, `@MainActor`).
///
/// Rewards are granted only for *qualifying* (metMinimum) sessions — never quality/`cameraVerified`.
@MainActor
final class RetentionStore: ObservableObject {
    static let shared = RetentionStore()

    @Published private(set) var ownedCollectibleIds: Set<String> = []
    @Published private(set) var pendingCollectibleID: String?

    private let store: BrushingStore
    private let profiles: ProfileStore
    private let ctx: NSManagedObjectContext
    private let calendar: Calendar
    private let defaults: UserDefaults
    private var cancellables: Set<AnyCancellable> = []

    private static let lastRevealKey = "retention.lastReveal"
    private static let pendingKey = "retention.pendingCollectible"
    private let config = StreakConfig.default

    // `init` is `internal` (not `private`) so unit tests can inject an isolated
    // PersistenceController + ProfileStore + BrushingStore triple, mirroring GamificationStore.
    init(controller: PersistenceController = .shared,
         profiles: ProfileStore = .shared,
         brushing: BrushingStore = .shared,
         calendar: Calendar = .current,
         defaults: UserDefaults = .standard) {
        self.ctx = controller.viewContext
        self.profiles = profiles
        self.store = brushing
        self.calendar = calendar
        self.defaults = defaults
        self.pendingCollectibleID = defaults.string(forKey: Self.pendingKey)
        loadOwned()
        reconcileGrants()
        profiles.$activeProfileID
            .dropFirst()
            .sink { [weak self] _ in self?.reloadForProfileChange() }
            .store(in: &cancellables)
    }

    // MARK: Derived model (pure ToothBuddyCore engines)

    var rings: DayRingState {
        DayRings.today(records: store.records, now: Date(), calendar: calendar, config: config)
    }
    var weekProgress: WeekProgress {
        DayRings.weekProgress(records: store.records, now: Date(), calendar: calendar, config: config)
    }
    var freeze: FreezeState {
        StreakFreeze.evaluate(records: store.records, now: Date(), config: config, calendar: calendar)
    }
    var overnight: OvernightState {
        OvernightCycle.state(records: store.records, lastReveal: lastReveal,
                             now: Date(), calendar: calendar, config: config)
    }
    var collectionProgress: (owned: Int, total: Int) {
        CollectionEngine.progress(owned: ownedCollectibleIds)
    }
    var pendingCollectible: Collectible? {
        pendingCollectibleID.flatMap { id in Collectible.all.first { $0.id == id } }
    }

    private var lastReveal: Date? {
        let t = defaults.double(forKey: Self.lastRevealKey)
        return t > 0 ? Date(timeIntervalSinceReferenceDate: t) : nil
    }

    // MARK: Mutations

    /// Call after a session is recorded (same call-site as `GamificationStore.checkAndUnlock`).
    func refresh() {
        reconcileGrants()
        objectWillChange.send()
    }

    /// Mark the morning reveal as shown — clears the pending collectible, records the time.
    func consumeReveal() {
        defaults.set(Date().timeIntervalSinceReferenceDate, forKey: Self.lastRevealKey)
        defaults.removeObject(forKey: Self.pendingKey)
        pendingCollectibleID = nil
        objectWillChange.send()
    }

    // MARK: Internals

    /// Grant one collectible per qualifying session, until the catalog is exhausted. The most
    /// recently granted item becomes the pending morning-reveal.
    private func reconcileGrants() {
        let qualifying = store.records.filter { $0.metMinimum }.count
        let target = min(Collectible.all.count, qualifying)
        guard ownedCollectibleIds.count < target,
              let pid = profiles.activeProfileID,
              let cdp = profiles.managedProfile(pid) else { return }
        var granted: Collectible?
        while ownedCollectibleIds.count < target {
            guard let c = CollectionEngine.grant(owned: ownedCollectibleIds,
                                                 seed: ownedCollectibleIds.count) else { break }
            ownedCollectibleIds.insert(c.id)
            let row = CDCollectibleUnlock(context: ctx)
            row.collectibleID = c.id
            row.unlockedAt = Date()
            row.profile = cdp
            granted = c
        }
        if let g = granted {
            pendingCollectibleID = g.id
            defaults.set(g.id, forKey: Self.pendingKey)
        }
        if ctx.hasChanges { try? ctx.save() }
    }

    private func reloadForProfileChange() {
        loadOwned()
        pendingCollectibleID = defaults.string(forKey: Self.pendingKey)
        reconcileGrants()
    }

    private func loadOwned() {
        guard let pid = profiles.activeProfileID else { ownedCollectibleIds = []; return }
        let req = NSFetchRequest<CDCollectibleUnlock>(entityName: "CDCollectibleUnlock")
        req.predicate = NSPredicate(format: "profile.id == %@", pid as CVarArg)
        let rows = (try? ctx.fetch(req)) ?? []
        ownedCollectibleIds = Set(rows.compactMap { $0.collectibleID })
    }
}
