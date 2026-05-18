import Foundation
@preconcurrency import AVFoundation
import QuartzCore
import ToothBuddyCore

/// Represents a brushing zone (mouth quadrant or area). Used for position monitoring.
/// **Unchanged public type** — BrushView depends on this verbatim.
enum BrushingZone: String, CaseIterable {
    case upperLeft = "Upper left"
    case upperRight = "Upper right"
    case lowerLeft = "Lower left"
    case lowerRight = "Lower right"
    case frontTop = "Front top"
    case frontBottom = "Front bottom"

    /// Short on-screen label shown inside the camera frame.
    var prompt: String {
        switch self {
        case .upperLeft:    return "Brush upper left teeth"
        case .upperRight:   return "Brush upper right teeth"
        case .lowerLeft:    return "Brush lower left teeth"
        case .lowerRight:   return "Brush lower right teeth"
        case .frontTop:     return "Brush front top teeth"
        case .frontBottom:  return "Brush front bottom teeth"
        }
    }

    /// Friendly spoken sentence read aloud by VoiceCoach.
    var announcement: String {
        switch self {
        case .upperLeft:    return "Now brush your upper left teeth!"
        case .upperRight:   return "Now brush your upper right teeth!"
        case .lowerLeft:    return "Now brush your lower left teeth!"
        case .lowerRight:   return "Now brush your lower right teeth!"
        case .frontTop:     return "Time for your front top teeth!"
        case .frontBottom:  return "Now brush your front bottom teeth!"
        }
    }
}

/// Protocol for brushing position monitoring. **Unchanged.**
@MainActor
protocol BrushingZoneMonitoring {
    var currentZone: BrushingZone? { get }
    func startMonitoring()
    func stopMonitoring()
}

/// Camera-driven coarse-zone guidance (Spec 04 / 04.2). Engagement-grade only — never
/// clinical. All inference is the unit-tested `ToothBuddyCore` engine; this class is glue
/// + lifecycle. Public surface (shared / currentZone / start / stop) is byte-compatible
/// with the previous mock so BrushView is unchanged. Falls back to the legacy timed
/// sequence whenever the camera is unavailable.
@MainActor
final class BrushingZoneMonitor: ObservableObject, BrushingZoneMonitoring {
    static let shared = BrushingZoneMonitor()

    @Published private(set) var currentZone: BrushingZone?
    /// Additive signal for the Sugar Bugs game (Spec 04.3 §5). True while the user is
    /// actively brushing the current zone (camera), or always-true in timed fallback so
    /// the game still plays. Does not affect any existing behavior or `currentZone`.
    @Published private(set) var isBrushingActive = false

    private let camera = CameraService.shared
    private let cfg = ZoneGuidanceConfig.default
    private let decisionInterval: TimeInterval = 1.0
    private let windowSeconds: Double = 1.2
    private let windowCap = 24

    private var window: [ZoneSample] = []
    private var coverage = ZoneCoverageTracker()
    private var guidanceState = GuidanceState()
    private var decisionTimer: Timer?
    private var observers: [NSObjectProtocol] = []
    private var running = false
    private var startTime: CFTimeInterval = 0
    private var lastFaceSeen: CFTimeInterval = 0
    private var fallbackMode = false

    private init() {}

    func startMonitoring() {
        guard !running else { return }                 // idempotent
        running = true
        startTime = CACurrentMediaTime()
        lastFaceSeen = startTime
        window.removeAll()
        coverage = ZoneCoverageTracker()
        guidanceState = GuidanceState()
        fallbackMode = !camera.isAuthorized            // no permission → timed at once

        if camera.isAuthorized {
            camera.attachVision(sink: { [weak self] sample in
                Task { @MainActor in self?.ingest(sample) }
            })
            registerInterruptionObservers()
        }

        let t = Timer(timeInterval: decisionInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        decisionTimer = t
        tick()                                         // emit an initial zone now
    }

    func stopMonitoring() {
        guard running else { return }                  // idempotent
        running = false
        decisionTimer?.invalidate()
        decisionTimer = nil
        camera.detachVision()   // keep the live preview; full stop on view teardown
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.removeAll()
        window.removeAll()
        currentZone = nil
        isBrushingActive = false
    }

    // MARK: - Frame ingest (hopped to main from the video queue)

    private func ingest(_ sample: ZoneSample) {
        guard running else { return }
        window.append(sample)
        let cutoff = sample.atSeconds - windowSeconds
        window.removeAll { $0.atSeconds < cutoff }
        if window.count > windowCap {
            window.removeFirst(window.count - windowCap)
        }
        if sample.face.isPresent { lastFaceSeen = sample.atSeconds }
    }

    // MARK: - Decision tick (≤ 1 currentZone change / sec → no UI/voice thrash)

    private func tick() {
        guard running else { return }
        let now = CACurrentMediaTime()
        let elapsed = now - startTime

        if !camera.isAuthorized {
            fallbackMode = true
        } else if now - lastFaceSeen > cfg.fallbackGrace {
            fallbackMode = true
        } else if !window.isEmpty {
            fallbackMode = false
        }

        let mode: GuidanceMode = fallbackMode ? .fallbackTimed : .camera
        var estimate: ZoneEstimate?
        if mode == .camera {
            let e = BrushingZoneEstimator.estimate(window: window, config: cfg)
            estimate = e
            if e.isActivelyBrushing, let z = e.zone {
                coverage.record(z, dt: decisionInterval)
            }
            isBrushingActive = e.isActivelyBrushing
        } else {
            isBrushingActive = true   // timed fallback: game still plays (Spec 04.3 §6.3)
        }

        let out = GuidanceDecider.decide(mode: mode,
                                         estimate: estimate,
                                         coverage: coverage,
                                         elapsed: elapsed,
                                         state: guidanceState,
                                         config: cfg)
        guidanceState = out.newState
        let mapped = Self.brushingZone(for: out.promptZone)
        if mapped != currentZone { currentZone = mapped }
    }

    // MARK: - Camera session interruptions (no frozen black preview)

    private func registerInterruptionObservers() {
        let c = NotificationCenter.default
        func observe(_ name: Notification.Name,
                     _ body: @escaping @MainActor () -> Void) {
            let o = c.addObserver(forName: name, object: nil, queue: nil) { _ in
                Task { @MainActor in body() }
            }
            observers.append(o)
        }
        observe(AVCaptureSession.wasInterruptedNotification) { [weak self] in
            self?.fallbackMode = true
        }
        observe(AVCaptureSession.interruptionEndedNotification) { [weak self] in
            self?.lastFaceSeen = CACurrentMediaTime()       // let camera try again
        }
        observe(AVCaptureSession.runtimeErrorNotification) { [weak self] in
            self?.fallbackMode = true
        }
    }

    /// CoarseZone → BrushingZone — total & 1:1. // must stay in sync with BrushingZone
    private static func brushingZone(for z: CoarseZone) -> BrushingZone {
        switch z {
        case .upperLeft:   return .upperLeft
        case .upperRight:  return .upperRight
        case .lowerLeft:   return .lowerLeft
        case .lowerRight:  return .lowerRight
        case .frontTop:    return .frontTop
        case .frontBottom: return .frontBottom
        }
    }
}
