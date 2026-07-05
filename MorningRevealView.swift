import SwiftUI
import ToothBuddyCore

/// U9 — the overnight "morning reveal" moment. Shown once when `OvernightCycle` reports a
/// reveal is available (evening send-off → next-day qualifying brush). Buddy wakes up and
/// hands over what he found while you slept. Gated on a real brush, never on app-open (P1).
struct MorningRevealView: View {
    let collectible: Collectible?
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)

            BuddyReactiveView(mood: .waking, scale: 1.8)
                .frame(width: 176, height: 205)

            Text("Good morning!")
                .font(Duo.Fnt.ebd(28))
                .foregroundColor(Duo.ink)

            Text("Buddy was out all night and came back with something for you.")
                .font(Duo.Fnt.sbd(14))
                .foregroundColor(Duo.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)

            if let c = collectible {
                VStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 30, weight: .black))
                        .foregroundColor(Duo.yellow)
                    Text(c.name)
                        .font(Duo.Fnt.ebd(20))
                        .foregroundColor(Duo.ink)
                    Text(c.rarity.rawValue.capitalized)
                        .font(Duo.Fnt.sbd(11))
                        .tracking(0.6)
                        .foregroundColor(Duo.muted)
                }
                .padding(.horizontal, 28).padding(.vertical, 18)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Duo.foamFill))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Duo.ink, lineWidth: Duo.outlineWidth))
            }

            Spacer(minLength: 0)

            DuoButton("YAY!", role: .primary) { onDismiss() }
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Duo.pageBackground.ignoresSafeArea())
    }
}
