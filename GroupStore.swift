import Foundation
import CoreData
import Combine
import ToothBuddyCore

/// The peer Group (Spec 02 §6.4). Local-modeled in P2.2 — CloudKit sharing goes live in
/// P2.5. No roles, no admin: a single local `CDGroup` root that profiles relate into.
@MainActor
final class GroupStore: ObservableObject {
    static let shared = GroupStore()

    @Published private(set) var groupID: UUID?
    @Published private(set) var groupName: String?

    private let ctx: NSManagedObjectContext
    private let profiles: ProfileStore

    init(controller: PersistenceController = .shared, profiles: ProfileStore = .shared) {
        ctx = controller.viewContext
        self.profiles = profiles
        reload()
    }

    var hasGroup: Bool { groupID != nil }

    /// Every profile shown on the dashboard. In P2.2 (local) that is all device profiles;
    /// cross-device members arrive with P2.5 CloudKit.
    var dashboardProfiles: [Profile] { profiles.profiles }

    func reload() {
        let g = fetchGroup()
        groupID = g?.id
        groupName = g?.name
    }

    private func fetchGroup() -> CDGroup? {
        let req = NSFetchRequest<CDGroup>(entityName: "CDGroup")
        req.fetchLimit = 1
        return (try? ctx.fetch(req))?.first
    }

    /// Create the Group and attach the given profiles as members (Spec 02 AC7).
    @discardableResult
    func createGroup(name: String, attaching ids: [UUID]) -> Bool {
        guard let valid = Profile.validatedName(name), fetchGroup() == nil else { return false }
        let now = Date()
        let g = CDGroup(context: ctx)
        g.id = UUID(); g.name = valid; g.createdAt = now; g.modifiedAt = now
        for id in ids { profiles.managedProfile(id)?.group = g }
        save()
        reload()
        return true
    }

    func createGroupWithAllProfiles(name: String) -> Bool {
        createGroup(name: name, attaching: profiles.profiles.map(\.id))
    }

    /// Remove only this profile from the Group; it survives as a local profile (AC9).
    func leave(profileID: UUID) {
        profiles.managedProfile(profileID)?.group = nil
        save()
        reload()
    }

    /// Disband the local Group entirely; members are nullified (profiles survive).
    func deleteGroup() {
        guard let g = fetchGroup() else { return }
        ctx.delete(g)
        save()
        reload()
    }

    private func save() {
        guard ctx.hasChanges else { return }
        try? ctx.save()
    }
}
