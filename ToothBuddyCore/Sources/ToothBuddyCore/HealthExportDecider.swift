import Foundation

/// Pure idempotency rule for the HealthKit `toothbrushingEvent` export (Spec 05 §6.6 /
/// AC5). The app keeps a per-device set of already-exported session ids; this decides
/// whether a given completed session should be written. Write-only, opt-in — this type
/// has no HealthKit dependency and never reads anything.
public enum HealthExportDecider {

    /// Export iff the session is completed AND not already exported.
    public static func shouldExport(sessionID: UUID,
                                    isCompleted: Bool,
                                    alreadyExportedIDs: Set<UUID>) -> Bool {
        isCompleted && !alreadyExportedIDs.contains(sessionID)
    }
}
