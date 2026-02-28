import SwiftUI

enum AppTab: String, CaseIterable {
    case brush
    case history
    case rewards
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .brush

    var body: some View {
        VStack(spacing: 0) {
            appHeader
            tabContent
            customTabBar
        }
        .background(Theme.appBackground.ignoresSafeArea())
        .ignoresSafeArea(edges: .bottom)
    }

    private var appHeader: some View {
        Text("🦷 ToothBuddy")
            .font(.system(size: 30, weight: .bold, design: .rounded))
            .tracking(1)
            .foregroundColor(.white)
            .shadow(color: Theme.accentBlue.opacity(0.6), radius: 8, x: 0, y: 2)
            .padding(.vertical, 12)
    }

    @ViewBuilder
    private var tabContent: some View {
        Group {
            switch selectedTab {
            case .brush:
                BrushView()
            case .history:
                HistoryView()
            case .rewards:
                RewardsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Tab order: History (left), Brush (center), Rewards (right).
    private static let tabOrder: [AppTab] = [.history, .brush, .rewards]

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Self.tabOrder, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .padding(.bottom, 24)
        .background(Color.white.opacity(0.05))
        .overlay(
            Rectangle()
                .fill(Theme.borderLight)
                .frame(height: 1),
            alignment: .top
        )
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 3) {
                Text(tabIcon(tab))
                    .font(.system(size: 22))
                Text(tab.label)
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(0.5)
                    .foregroundColor(isSelected ? Theme.accentBlue : Theme.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 20)
            .background(isSelected ? Theme.accentBlue.opacity(0.2) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Theme.accentBlue.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private func tabIcon(_ tab: AppTab) -> String {
        switch tab {
        case .brush: return "🪥"
        case .history: return "📋"
        case .rewards: return "🏆"
        }
    }
}

extension AppTab {
    var label: String {
        switch self {
        case .brush: return "Brush"
        case .history: return "History"
        case .rewards: return "Rewards"
        }
    }
}
