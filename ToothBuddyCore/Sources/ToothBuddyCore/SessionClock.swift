import Foundation

/// Phase 1.5 / U3 — the single source of truth for a session's *active elapsed time*.
///
/// A brushing session's timer must count only the time the user is actually in the
/// session foreground and not interrupted. Wall-clock `end − start` over-counts: a phone
/// call, Siri, an alarm, or backgrounding the app all leave the wall clock running while
/// the user is not brushing, inflating the duration that ends up on a dentist-facing record.
///
/// `SessionClock` accumulates only *active segments*. The caller (BrushView) opens a segment
/// at session start, closes it on any pause signal (`scenePhase` leaving `.active`, or an
/// `AVAudioSession` interruption beginning), and opens a new one on resume. Querying
/// `activeSeconds(asOf:)` returns the summed active time — never the paused gaps.
///
/// Pure, deterministic value type in the monotonic-clock domain (caller passes
/// `CACurrentMediaTime()` timestamps). All transitions are functional (return a new clock)
/// so it lives comfortably in SwiftUI `@State` without mutation quirks, and is trivially
/// unit-testable from the CLI. Mirrors the codebase convention of pushing decidable logic
/// into `ToothBuddyCore` (see `CameraVerification`, `HealthExportDecider`).
public struct SessionClock: Equatable, Sendable {
    /// Summed duration of all completed (paused) active segments.
    private var accumulated: TimeInterval
    /// Start timestamp of the currently-open active segment, or `nil` while paused.
    private var segmentStart: TimeInterval?

    /// Begins a running clock with its first active segment open at `startedAt`.
    public init(startedAt: TimeInterval) {
        accumulated = 0
        segmentStart = startedAt
    }

    /// True while no active segment is open (the session is paused).
    public var isPaused: Bool { segmentStart == nil }

    /// Closes the current active segment at `t`. No-op if already paused (idempotent).
    public func paused(at t: TimeInterval) -> SessionClock {
        guard let start = segmentStart else { return self }
        var copy = self
        copy.accumulated += max(0, t - start)
        copy.segmentStart = nil
        return copy
    }

    /// Opens a new active segment at `t`. No-op if already running (idempotent).
    public func resumed(at t: TimeInterval) -> SessionClock {
        guard segmentStart == nil else { return self }
        var copy = self
        copy.segmentStart = t
        return copy
    }

    /// Total active seconds as of `now` — accumulated paused-out segments plus the
    /// currently-open segment (if running). Never counts paused gaps; never negative.
    public func activeSeconds(asOf now: TimeInterval) -> Int {
        var total = accumulated
        if let start = segmentStart {
            total += max(0, now - start)
        }
        return Int(total)
    }
}
