import SwiftUI

enum AppTab: String, CaseIterable {
    case brush
    case history
    case tips
}

struct ContentView: View {
    @StateObject private var store = BrushingStore.shared
    @StateObject private var profiles = ProfileStore.shared
    @State private var selectedTab: AppTab = .brush
    @State private var previousTab: AppTab = .brush
    @State private var showProfileSwitcher = false

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
            if !store.isBrushing {
                customTabBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.lastDeletedRecord != nil)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: store.isBrushing)
        .background(Theme.appBackground.ignoresSafeArea())
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showProfileSwitcher) {
            ProfilePickerView(store: profiles, isGate: false) {
                showProfileSwitcher = false
            }
        }
    }

    private var deletedRecordBanner: some View {
        HStack(spacing: 12) {
            Text("Record deleted.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
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
            .foregroundColor(Theme.textMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.surfaceFrost)
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
        HStack(spacing: 7) {
            Spacer().frame(width: 44)
            Spacer()
            ToothImageView(size: 26)
            Text("ToothBuddy")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .tracking(1)
                .foregroundColor(Theme.textPrimary)
            Spacer()
            profileButton
        }
        .shadow(color: Theme.accentBlue.opacity(0.3), radius: 6, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var profileButton: some View {
        Button { showProfileSwitcher = true } label: {
            Image(systemName: profiles.activeProfile?.symbol.systemImage ?? "person.crop.circle")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background((profiles.activeProfile?.colorTag.color) ?? Theme.accentBlue)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
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
            case .tips:
                TipsView()
                    .id("tips")
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

    /// Tab order: History (left), Brush (center), Tips (right).
    private static let tabOrder: [AppTab] = [.history, .brush, .tips]

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Self.tabOrder, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .padding(.bottom, 24)
        .background(Color.white.opacity(0.7))
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
            SoundManager.tabTapped()
            previousTab = selectedTab
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Group {
                    if tab == .brush {
                        ToothImageView(size: 24)
                            .opacity(isSelected ? 1.0 : 0.38)
                    } else {
                        Image(systemName: tab.symbolName)
                            .font(.system(size: 22, weight: isSelected ? .bold : .regular))
                            .foregroundColor(isSelected ? Theme.startButtonEnd : Theme.textMuted)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                .scaleEffect(isSelected ? 1.08 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)
                Text(tab.label)
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(0.5)
                    .foregroundColor(isSelected ? Theme.startButtonEnd : Theme.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 20)
            .background(isSelected ? Theme.startButtonEnd.opacity(0.12) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Theme.startButtonEnd.opacity(0.25) : Color.clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(BounceButtonStyle())
    }
}

extension AppTab {
    var label: String {
        switch self {
        case .brush:   return "Brush"
        case .history: return "History"
        case .tips:    return "Tips"
        }
    }

    var symbolName: String {
        switch self {
        case .brush:   return "mouth.fill"
        case .history: return "chart.bar.fill"
        case .tips:    return "lightbulb.fill"
        }
    }
}
