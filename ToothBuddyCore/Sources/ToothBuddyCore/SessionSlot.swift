import Foundation

/// Morning vs evening session slot. Boundary is `boundaryHour` (local): `hour < boundaryHour`
/// is morning, `hour >= boundaryHour` is evening. Spec 01 §4.1 (DECIDED boundary = 12).
public enum SessionSlot: String, Codable, CaseIterable, Sendable {
    case morning
    case evening

    public init(hour: Int, boundaryHour: Int) {
        self = hour < boundaryHour ? .morning : .evening
    }

    public static func slot(for date: Date, boundaryHour: Int, calendar: Calendar) -> SessionSlot {
        let hour = calendar.component(.hour, from: date)
        return SessionSlot(hour: hour, boundaryHour: boundaryHour)
    }
}
