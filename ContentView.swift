import SwiftUI

enum AppTab: String, CaseIterable {
    case brush
    case history
    case rewards
}

struct ContentView: View {
    @StateObject private var store = BrushingStore.shared
    @State private var selectedTab: AppTab = .brush
    @State private var previousTab: AppTab = .brush

    var body: some View {
        VStack(spacing: 0) {
            appHeader
            if store.lastDeletedRecord != nil {
                deletedRecordBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task(id: store.lastDeletedRecord?.id) {
                        guard store.lastDeletedRecord != nil else { return }
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        guard !Task.isCancelled else { return }
                        store.clearLastDeleted()
                    }
            }
            tabContent
            customTabBar
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.lastDeletedRecord != nil)
        .background(Theme.appBackground.ignoresSafeArea())
        .ignoresSafeArea(edges: .bottom)
    }

    private var deletedRecordBanner: some View {
        HStack(spacing: 12) {
            Text("Record deleted.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            Button("Undo") {
                store.restoreLastDeleted()
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(Theme.accentBlue)
            Spacer()
            Button("Dismiss") {
                store.clearLastDeleted()
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.backgroundMid)
        .overlay(
            Rectangle()
                .fill(Theme.accentBlue.opacity(0.4))
                .frame(height: 2),
            alignment: .bottom
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var appHeader: some View {
        Text("🦷 ToothBuddy")
            .font(.system(size: 30, weight: .bold, design: .rounded))
            .tracking(1)
            .foregroundColor(.white)
            .shadow(color: Theme.accentBlue.opacity(0.6), radius: 8, x: 0, y: 2)
            .padding(.vertical, 12)
    }

    private var tabOrderIndex: Int { Self.tabOrder.firstIndex(of: selectedTab) ?? 0 }
    private var previousTabOrderIndex: Int { Self.tabOrder.firstIndex(of: previousTab) ?? 0 }

    @ViewBuilder
    private var tabContent: some View {
        ZStack {
            switch selectedTab {
            case .brush:
                BrushView()
                    .id("brush")
                    .transition(tabOrderIndex >= previousTabOrderIndex
                        ? .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                      removal: .move(edge: .leading).combined(with: .opacity))
                        : .asymmetric(insertion: .move(edge: .leading).combined(with: .opacity),
                                      removal: .move(edge: .trailing).combined(with: .opacity)))
            case .history:
                HistoryView()
                    .id("history")
                    .transition(tabOrderIndex >= previousTabOrderIndex
                        ? .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                      removal: .move(edge: .leading).combined(with: .opacity))
                        : .asymmetric(insertion: .move(edge: .leading).combined(with: .opacity),
                                      removal: .move(edge: .trailing).combined(with: .opacity)))
            case .rewards:
                RewardsView()
                    .id("rewards")
                    .transition(tabOrderIndex >= previousTabOrderIndex
                        ? .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                      removal: .move(edge: .leading).combined(with: .opacity))
                        : .asymmetric(insertion: .move(edge: .leading).combined(with: .opacity),
                                      removal: .move(edge: .trailing).combined(with: .opacity)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.28), value: selectedTab)
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
            previousTab = selectedTab
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
            .scaleEffect(isSelected ? 1.02 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(BounceButtonStyle())
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
