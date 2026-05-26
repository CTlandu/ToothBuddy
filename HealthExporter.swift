import Foundation
import ToothBuddyCore

#if canImport(HealthKit)
import HealthKit

/// Spec 05 §6.6 — write-only, opt-in, revocable, idempotent export of completed
/// sessions to Apple Health as `.toothbrushingEvent`. NEVER reads any Health data.
/// The local record is always the source of truth; revoking permission silently
/// disables export with no error spam and no local data loss.
@MainActor
final class HealthExporter {
    static let shared = HealthExporter()

    private let store = HKHealthStore()
    private let exportedKey = "ToothBuddy.healthExportedIDs.v1"

    private var toothbrushingType: HKCategoryType? {
        HKObjectType.categoryType(forIdentifier: .toothbrushingEvent)
    }

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// Has the user explicitly granted share authorization for tooth-brushing?
    var isAuthorized: Bool {
        guard isAvailable, let t = toothbrushingType else { return false }
        return store.authorizationStatus(for: t) == .sharingAuthorized
    }

    private var exportedIDs: Set<UUID> {
        get {
            Set((UserDefaults.standard.array(forKey: exportedKey) as? [String] ?? [])
                .compactMap(UUID.init(uuidString:)))
        }
        set {
            UserDefaults.standard.set(newValue.map(\.uuidString), forKey: exportedKey)
        }
    }

    /// Contextual opt-in (Spec 05 §6.6) — request **share-only** authorization for the
    /// single tooth-brushing type. No read types are ever requested.
    func requestAuthorization() async -> Bool {
        guard isAvailable, let t = toothbrushingType else { return false }
        do {
            try await store.requestAuthorization(toShare: [t], read: [])
            return isAuthorized
        } catch {
            return false
        }
    }

    /// Write one sample for a completed session, idempotently. No-op unless available,
    /// authorized, and `HealthExportDecider` says so.
    func exportIfNeeded(sessionID: UUID, start: Date, end: Date, isCompleted: Bool) {
        guard isAvailable, isAuthorized, let t = toothbrushingType else { return }
        guard HealthExportDecider.shouldExport(sessionID: sessionID,
                                               isCompleted: isCompleted,
                                               alreadyExportedIDs: exportedIDs) else { return }
        let sample = HKCategorySample(
            type: t,
            value: HKCategoryValue.notApplicable.rawValue,
            start: start, end: max(start, end),
            metadata: [HKMetadataKeyExternalUUID: sessionID.uuidString])
        store.save(sample) { [weak self] ok, _ in
            guard ok else { return }   // failure → leave unmarked; safe to retry later
            Task { @MainActor in
                self?.exportedIDs.insert(sessionID)
            }
        }
    }
}

#else
@MainActor
final class HealthExporter {
    static let shared = HealthExporter()
    var isAvailable: Bool { false }
    var isAuthorized: Bool { false }
    func requestAuthorization() async -> Bool { false }
    func exportIfNeeded(sessionID: UUID, start: Date, end: Date, isCompleted: Bool) {}
}
#endif
