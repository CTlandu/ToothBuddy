import Foundation

/// Represents a brushing zone (mouth quadrant or area). Used for position monitoring.
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

/// Protocol for brushing position monitoring. Real implementation would use camera/ML.
@MainActor
protocol BrushingZoneMonitoring {
    var currentZone: BrushingZone? { get }
    func startMonitoring()
    func stopMonitoring()
}

/// Mock implementation: cycles through zones on a timer. Replace with real camera/ML later.
@MainActor
final class BrushingZoneMonitor: ObservableObject, BrushingZoneMonitoring {
    static let shared = BrushingZoneMonitor()

    @Published private(set) var currentZone: BrushingZone?

    private var zoneTimer: Timer?
    private static let zoneInterval: TimeInterval = 15

    private init() {}

    func startMonitoring() {
        currentZone = BrushingZone.allCases.randomElement()
        zoneTimer?.invalidate()
        zoneTimer = Timer.scheduledTimer(withTimeInterval: Self.zoneInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.advanceToNextZone()
            }
        }
        RunLoop.main.add(zoneTimer!, forMode: .common)
    }

    func stopMonitoring() {
        zoneTimer?.invalidate()
        zoneTimer = nil
        currentZone = nil
    }

    private func advanceToNextZone() {
        guard let current = currentZone,
              let idx = BrushingZone.allCases.firstIndex(of: current) else {
            currentZone = BrushingZone.allCases.randomElement()
            return
        }
        let nextIdx = (idx + 1) % BrushingZone.allCases.count
        currentZone = BrushingZone.allCases[nextIdx]
    }
}
