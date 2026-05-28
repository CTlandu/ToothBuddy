import Foundation
import MetricKit
import os

/// MetricKit subscriber wired in `MyApp.init`. Apple delivers a daily payload
/// (`MXMetricPayload`) and on-demand diagnostics (`MXDiagnosticPayload`) to
/// production / TestFlight builds — never to Debug builds — about 24 hours after
/// install. We log the high-value fields via `Logger`; nothing is shipped off-device
/// at this stage. Console.app (filter on subsystem `com.ctlandu.ToothBuddy`,
/// category `metrics`) will show them.
///
/// Quality audit 2026-05-28 / Plan U3.
///
/// Critical safety rule (Apple Developer Forums #714616):
/// **Never call `MXMetricManager.shared.remove(_:)`** — iOS 16.0–16.x has a documented
/// crash in subscriber-list mutation. Subscribe once, never unsubscribe. Subscribers
/// are weakly held, so subscription is cheap and idempotent if reasserted (we don't).
//
// AUDIT 2026-05-28 (Plan U3): `@unchecked Sendable` is the right choice for this
// subscriber. The only mutable state is the implicit objc weak/strong machinery
// inside NSObject, which is documented thread-safe; our own state (`log`) is a
// Logger (Sendable). The two delegate methods are `nonisolated` because MetricKit
// calls them on a private background queue. Wrapping in an actor would make
// `MyApp.init` async, which is impossible (App's init is synchronous).
final class MetricsSubscriber: NSObject, MXMetricManagerSubscriber, @unchecked Sendable {
    static let shared = MetricsSubscriber()

    private let log = Logger(subsystem: "com.ctlandu.ToothBuddy", category: "metrics")

    private override init() { super.init() }

    /// Subscribe the singleton. Safe to call exactly once from `MyApp.init`.
    func start() {
        MXMetricManager.shared.add(self)
        log.info("MetricKit subscriber started")
    }

    // MARK: - MXMetricManagerSubscriber
    //
    // Both delegate methods are `nonisolated` because MetricKit calls them on an
    // arbitrary background queue — under Swift 6 strict concurrency this is
    // required to avoid actor-hop overhead and isolation diagnostics.

    nonisolated func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            // Cold launch / resume timings — the headline number for "is the app fast?"
            if let launch = payload.applicationLaunchMetrics {
                log.info("MetricKit launch: ttd=\(launch.histogrammedTimeToFirstDraw.totalBucketCount, privacy: .public) buckets, optimized_ttd=\(launch.histogrammedOptimizedTimeToFirstDraw.totalBucketCount, privacy: .public) buckets, resume=\(launch.histogrammedApplicationResumeTime.totalBucketCount, privacy: .public) buckets")
            }
            // Hang time — surfaces frame-budget misses users would notice.
            if let resp = payload.applicationResponsivenessMetrics {
                log.info("MetricKit responsiveness: hangs=\(resp.histogrammedApplicationHangTime.totalBucketCount, privacy: .public) buckets")
            }
            // Cumulative CPU as a battery proxy. There's no direct
            // "battery % consumed" metric in MetricKit.
            if let cpu = payload.cpuMetrics {
                log.info("MetricKit cpu: total=\(cpu.cumulativeCPUTime.description, privacy: .public)")
            }
        }
    }

    nonisolated func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            if let crashes = payload.crashDiagnostics, !crashes.isEmpty {
                log.error("MetricKit crash diagnostics: \(crashes.count, privacy: .public) payload(s)")
            }
            if let hangs = payload.hangDiagnostics, !hangs.isEmpty {
                log.error("MetricKit hang diagnostics: \(hangs.count, privacy: .public) payload(s)")
            }
            if let cpuExc = payload.cpuExceptionDiagnostics, !cpuExc.isEmpty {
                log.error("MetricKit cpu-exception diagnostics: \(cpuExc.count, privacy: .public) payload(s)")
            }
        }
    }
}
