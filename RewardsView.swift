import SwiftUI

/// Placeholder for the Rewards tab (matches JSX tab bar; content can be added later).
struct RewardsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // Gems card
                VStack(spacing: 8) {
                    Text("💎")
                        .font(.system(size: 48))
                    Text("120 Gems")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Keep brushing to earn more!")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textMutedStrong)
                }
                .frame(maxWidth: .infinity)
                .padding(18)
                .background(
                    LinearGradient(
                        colors: [Color(red: 124/255, green: 58/255, blue: 237/255), Color(red: 168/255, green: 85/255, blue: 247/255)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 18)

                Text("ACHIEVEMENTS")
                    .font(.system(size: 12, weight: .heavy))
                    .tracking(1.5)
                    .foregroundColor(Theme.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)

                Text("Coming soon!")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
            }
            .padding(.bottom, 24)
        }
        .background(Theme.appBackground)
    }
}
