import SwiftUI
import ToothBuddyCore

/// Spec 05 §6.2 — the calm adult consistency curve. A quiet smoothed area + line over
/// the last `days`; no numbers shouting, no gamification. Pure data from Core
/// `HabitCurve`; the kid UI never shows this.
struct HabitCurveView: View {
    let records: [BrushingRecord]
    let profileID: UUID
    var days: Int = 30

    private var points: [HabitCurvePoint] {
        HabitCurve.points(records: records, profileID: profileID,
                          asOf: Date(), days: days, calendar: .current)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Consistency")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textMutedStrong)

            GeometryReader { geo in
                curve(in: geo.size)
            }
            .frame(height: 64)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(Theme.surfaceFrost))
    }

    @ViewBuilder
    private func curve(in size: CGSize) -> some View {
        let pts = points
        if pts.count >= 2 {
            let step = size.width / CGFloat(pts.count - 1)
            let coords = pts.enumerated().map { i, pt in
                CGPoint(x: CGFloat(i) * step,
                        y: size.height - CGFloat(pt.adherence) * size.height)
            }
            let line = Path { p in
                p.move(to: coords[0])
                coords.dropFirst().forEach { p.addLine(to: $0) }
            }
            let area = Path { p in
                p.move(to: CGPoint(x: 0, y: size.height))
                coords.forEach { p.addLine(to: $0) }
                p.addLine(to: CGPoint(x: size.width, y: size.height))
                p.closeSubpath()
            }
            ZStack {
                area.fill(LinearGradient(
                    colors: [Theme.accentBlue.opacity(0.22), Theme.accentBlue.opacity(0.02)],
                    startPoint: .top, endPoint: .bottom))
                line.stroke(Theme.accentBlue.opacity(0.85),
                            style: .init(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        } else {
            Text("A few more days and your curve appears here.")
                .font(.caption).foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
