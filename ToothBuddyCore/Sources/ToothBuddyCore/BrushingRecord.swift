import Foundation

/// A single brushing session. Pure value type — lives in ToothBuddyCore so it is
/// unit-testable from the CLI.
///
/// U1 (quality-pivot): beyond start/end it now carries the session's quality signals —
/// per-zone coverage, active time, target, camera-verification, and guidance mode — so a
/// record can prove "brushed every zone for long enough" rather than just "ran a timer".
public struct BrushingRecord: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    /// Owning profile — always the single device owner (single-user model, U9).
    public var profileID: UUID
    public var startDate: Date
    public var endDate: Date

    /// Time the user was actually brushing (vs wall-clock end−start, which includes pauses).
    public var activeSeconds: Int
    /// Session goal in seconds (120 default, 180 optional). Per-zone target = target / zones.
    public var targetSeconds: Int
    /// Per-zone dwell seconds. In camera mode these are measured; in guided-only mode the
    /// engine fills them as the prescribed route advances.
    public var coverage: [CoarseZone: Int]
    /// True only when the camera was on and detected brushing for enough of the session.
    /// guided-only / no-camera sessions are `false` — the un-fakeable flag for dentist proof.
    public var cameraVerified: Bool
    /// Which guidance mode the session ran in.
    public var guidanceMode: GuidanceMode

    /// Wall-clock duration in whole seconds. Clamped at 0 (never negative).
    public var durationSeconds: Int {
        max(0, Int(endDate.timeIntervalSince(startDate)))
    }

    /// Stars 1–3 from duration: ≥2 min → 3, ≥1 min → 2, >0 → 1, else 0.
    public var starCount: Int {
        if durationSeconds >= 120 { return 3 }
        if durationSeconds >= 60 { return 2 }
        if durationSeconds > 0 { return 1 }
        return 0
    }

    /// Every zone brushed to its per-zone target AND total active time met the session target.
    /// The honest "did a good brush" signal — same rule in camera and guided-only mode.
    public var metMinimum: Bool {
        guard targetSeconds > 0, activeSeconds >= targetSeconds else { return false }
        let perZone = max(1, targetSeconds / CoarseZone.allCases.count)
        return CoarseZone.allCases.allSatisfy { (coverage[$0] ?? 0) >= perZone }
    }

    public init(id: UUID = UUID(), profileID: UUID, startDate: Date, endDate: Date,
                activeSeconds: Int? = nil, targetSeconds: Int = 120,
                coverage: [CoarseZone: Int] = [:], cameraVerified: Bool = false,
                guidanceMode: GuidanceMode = .fallbackTimed) {
        self.id = id
        self.profileID = profileID
        self.startDate = startDate
        self.endDate = endDate
        self.activeSeconds = activeSeconds ?? max(0, Int(endDate.timeIntervalSince(startDate)))
        self.targetSeconds = targetSeconds
        self.coverage = coverage
        self.cameraVerified = cameraVerified
        self.guidanceMode = guidanceMode
    }

    private enum CodingKeys: String, CodingKey {
        case id, profileID, startDate, endDate
        case activeSeconds, targetSeconds, coverage, cameraVerified, guidanceMode
    }

    // Backward-compatible decoding: a pre-enrichment record (only the four base keys)
    // decodes with sensible defaults instead of throwing. encode(to:) is synthesized.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        profileID = try c.decode(UUID.self, forKey: .profileID)
        startDate = try c.decode(Date.self, forKey: .startDate)
        endDate = try c.decode(Date.self, forKey: .endDate)
        targetSeconds = try c.decodeIfPresent(Int.self, forKey: .targetSeconds) ?? 120
        coverage = try c.decodeIfPresent([CoarseZone: Int].self, forKey: .coverage) ?? [:]
        cameraVerified = try c.decodeIfPresent(Bool.self, forKey: .cameraVerified) ?? false
        guidanceMode = try c.decodeIfPresent(GuidanceMode.self, forKey: .guidanceMode) ?? .fallbackTimed
        let duration = max(0, Int(endDate.timeIntervalSince(startDate)))
        activeSeconds = try c.decodeIfPresent(Int.self, forKey: .activeSeconds) ?? duration
    }
}
