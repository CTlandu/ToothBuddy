import Foundation
import CoreData
import Combine
import ToothBuddyCore

/// Owns profiles + the per-device active profile (Spec 02 §6.1–§6.2). Active profile is
/// device-local in UserDefaults and NEVER synced.
@MainActor
final class ProfileStore: ObservableObject {
    static let shared = ProfileStore(autoCreateOwner: true)

    @Published private(set) var profiles: [Profile] = []
    @Published private(set) var activeProfileID: UUID?

    private let ctx: NSManagedObjectContext
    private let activeKey = "ToothBuddy.activeProfileID"

    init(controller: PersistenceController = .shared, autoCreateOwner: Bool = false) {
        ctx = controller.container.viewContext
        if let s = UserDefaults.standard.string(forKey: activeKey) {
            activeProfileID = UUID(uuidString: s)
        }
        reload()
        if autoCreateOwner { ensureOwnerProfile() }
    }

    /// U9 — single-user model: guarantee one owner profile exists and is active.
    /// Only the shared instance auto-creates; tests opt out (default false).
    private func ensureOwnerProfile() {
        if profiles.isEmpty {
            _ = createProfile(name: "Me", color: .sky, symbol: .star, makeActive: true)
        } else if activeProfileID == nil {
            setActive(profiles.first?.id)
        }
    }

    var activeProfile: Profile? {
        profiles.first { $0.id == activeProfileID }
    }

    func reload() {
        let req = NSFetchRequest<CDProfile>(entityName: "CDProfile")
        req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        let rows = (try? ctx.fetch(req)) ?? []
        profiles = rows.compactMap { $0.toDTO() }
        // Keep the active selection valid.
        if let id = activeProfileID, !profiles.contains(where: { $0.id == id }) {
            setActive(profiles.first?.id)
        } else if activeProfileID == nil, profiles.count == 1 {
            setActive(profiles.first?.id)
        }
    }

    func setActive(_ id: UUID?) {
        activeProfileID = id
        if let id { UserDefaults.standard.set(id.uuidString, forKey: activeKey) }
        else { UserDefaults.standard.removeObject(forKey: activeKey) }
    }

    @discardableResult
    func createProfile(name: String, color: ProfileColor, symbol: ProfileSymbol,
                        birthYear: Int? = nil, creatorLabel: String = "",
                        mode: ProfileMode = .kid,
                        makeActive: Bool = true) -> Profile? {
        guard let valid = Profile.validatedName(name) else { return nil }
        let now = Date()
        let dto = Profile(name: valid, colorTag: color, symbol: symbol,
                          birthYear: birthYear, creatorLabel: creatorLabel,
                          createdAt: now, modifiedAt: now, mode: mode)
        let cd = CDProfile(context: ctx)
        cd.apply(dto)
        save()
        reload()
        if makeActive { setActive(dto.id) }
        return dto
    }

    /// Flip a profile's experience mode (Spec 05 §6.1). Per-profile — siblings unaffected.
    func setMode(_ mode: ProfileMode, for id: UUID) {
        guard let cd = managedProfile(id) else { return }
        cd.mode = mode.rawValue
        cd.modifiedAt = Date()
        save()
        reload()
    }

    func deleteProfile(_ id: UUID) {
        let req = NSFetchRequest<CDProfile>(entityName: "CDProfile")
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        for row in (try? ctx.fetch(req)) ?? [] { ctx.delete(row) }   // cascades records
        save()
        reload()
    }

    /// Look up the managed object for relationship wiring (used by BrushingStore).
    func managedProfile(_ id: UUID) -> CDProfile? {
        let req = NSFetchRequest<CDProfile>(entityName: "CDProfile")
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        req.fetchLimit = 1
        return (try? ctx.fetch(req))?.first
    }

    private func save() {
        guard ctx.hasChanges else { return }
        try? ctx.save()
    }
}
