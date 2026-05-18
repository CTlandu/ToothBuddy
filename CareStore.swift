import Foundation
import CoreData
import Combine
import ToothBuddyCore

/// Per-profile brush-head / dentist care (Spec 02 §6.6). Due-date math is the pure
/// `CareDueCalculator` in ToothBuddyCore; this only persists anchors via `CDProfileCare`.
@MainActor
final class CareStore: ObservableObject {
    static let shared = CareStore()

    private let ctx: NSManagedObjectContext
    private let profiles: ProfileStore

    init(controller: PersistenceController = .shared, profiles: ProfileStore = .shared) {
        ctx = controller.viewContext
        self.profiles = profiles
    }

    private func care(for profileID: UUID, createIfMissing: Bool) -> CDProfileCare? {
        guard let cdp = profiles.managedProfile(profileID) else { return nil }
        if let c = cdp.care { return c }
        guard createIfMissing else { return nil }
        let c = CDProfileCare(context: ctx)
        c.brushHeadIntervalDays = Int64(CareKind.brushHead.defaultIntervalDays)
        c.dentistIntervalDays = Int64(CareKind.dentist.defaultIntervalDays)
        c.modifiedAt = Date()
        c.profile = cdp
        return c
    }

    private func anchor(_ c: CDProfileCare?, _ kind: CareKind) -> Date? {
        kind == .brushHead ? c?.lastBrushHeadReplaced : c?.lastDentistVisit
    }

    private func interval(_ c: CDProfileCare?, _ kind: CareKind) -> Int {
        let raw = kind == .brushHead ? c?.brushHeadIntervalDays : c?.dentistIntervalDays
        let v = Int(raw ?? 0)
        return v > 0 ? v : kind.defaultIntervalDays
    }

    func status(_ profileID: UUID, _ kind: CareKind) -> CareStatus {
        let c = care(for: profileID, createIfMissing: false)
        return CareDueCalculator.status(anchor: anchor(c, kind),
                                        intervalDays: interval(c, kind),
                                        now: Date(), calendar: .current)
    }

    /// "Mark done" — reset the anchor to now (Spec 02 AC10).
    func markDone(_ profileID: UUID, _ kind: CareKind) {
        guard let c = care(for: profileID, createIfMissing: true) else { return }
        let now = Date()
        switch kind {
        case .brushHead: c.lastBrushHeadReplaced = now
        case .dentist:   c.lastDentistVisit = now
        }
        c.modifiedAt = now
        if ctx.hasChanges { try? ctx.save() }
        objectWillChange.send()
    }

    /// Inputs for the pure `CareReminderPlanner`.
    func careInputs() -> [ProfileCareInput] {
        profiles.profiles.map { p in
            let c = profiles.managedProfile(p.id)?.care
            return ProfileCareInput(profileID: p.id,
                                    profileName: p.name,
                                    brushHeadAnchor: anchor(c, .brushHead),
                                    brushHeadIntervalDays: interval(c, .brushHead),
                                    dentistAnchor: anchor(c, .dentist),
                                    dentistIntervalDays: interval(c, .dentist))
        }
    }
}
