import SwiftUI
import ToothBuddyCore

/// U9 — the overnight morning *greeting*. Shown once on app-open when `OvernightCycle` reports
/// a greeting is available (a new day after an evening send-off). Buddy is back from the night
/// and happy to see you — the emotional hook that pulls you to brush. It gives no reward (that
/// is earned by the brush itself, shown in the done sheet), so it never violates P1.
struct MorningRevealView: View {
    let owned: Int
    let total: Int
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)

            BuddyReactiveView(mood: .waking, scale: 1.8)
                .frame(width: 176, height: 205)

            Text("Good morning!")
                .font(Duo.Fnt.ebd(28))
                .foregroundColor(Duo.ink)

            Text("Buddy's back from the night and can't wait to brush with you.")
                .font(Duo.Fnt.sbd(14))
                .foregroundColor(Duo.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)

            HStack(spacing: 6) {
                Image(systemName: "sparkles").foregroundColor(Duo.yellow)
                Text("\(owned) of \(total) friends found together")
            }
            .font(Duo.Fnt.ebd(13))
            .foregroundColor(Duo.ink)
            .padding(.horizontal, 16).padding(.vertical, 9)
            .background(Capsule().fill(Duo.foamFill))
            .overlay(Capsule().stroke(Duo.ink, lineWidth: Duo.outlineWidth))

            Spacer(minLength: 0)

            DuoButton("LET'S BRUSH!", role: .primary) { onDismiss() }
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Duo.pageBackground.ignoresSafeArea())
    }
}
