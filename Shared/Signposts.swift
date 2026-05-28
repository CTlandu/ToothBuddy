import os

/// Single shared OSSignposter for the whole app + widget process. Wraps key hot paths
/// so Instruments → Points of Interest surfaces them on a timeline.
///
/// Quality audit 2026-05-28 / Plan U2.
/// Cost is ~200 ns per signpost call (Apple-documented), so safe to ship in release —
/// no `#if DEBUG` guards needed.
///
/// Subsystem chosen to match the app's bundle id; `.pointsOfInterest` is the OSLog
/// category that makes signposts auto-surface in the eponymous Instruments lane.
let appSignposter = OSSignposter(
    subsystem: "com.ctlandu.ToothBuddy",
    category: .pointsOfInterest
)

/// Convenience: time a block, named in Instruments. Use for non-overlapping intervals
/// (cold launch, brushing session, etc.).
@inline(__always)
func sp<T>(_ name: StaticString, _ work: () throws -> T) rethrows -> T {
    let state = appSignposter.beginInterval(name)
    defer { appSignposter.endInterval(name, state) }
    return try work()
}

/// Convenience: time a block when multiple intervals of the same name may overlap
/// (e.g., per-frame Vision processing). Mints a per-call signpost id so Instruments
/// can pair begin/end correctly.
@inline(__always)
func spOverlapping<T>(_ name: StaticString, _ work: () throws -> T) rethrows -> T {
    let id = appSignposter.makeSignpostID()
    let state = appSignposter.beginInterval(name, id: id)
    defer { appSignposter.endInterval(name, state) }
    return try work()
}
