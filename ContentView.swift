import SwiftUI

enum AppTab: String, CaseIterable {
    case brush
    case history
    case family
    case tips
}

struct ContentView: View {
    @StateObject private var store = BrushingStore.shared
    @StateObject private var profiles = ProfileStore.shared
    @StateObject private var intentBridge = BrushingIntentBridge.shared
    @State private var selectedTab: AppTab = .brush
    @State private var previousTab: AppTab = .brush
    @State private var showProfileSwitcher = false
    @State private var showSettings = false

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
        .sheet(isPresented: $showSettings) { SettingsView() }
        // Spec 05 §6.3 — StartBrushingIntent: jump to the Brush tab; BrushView
        // consumes the request and begins the session.
        .onChange(of: intentBridge.startRequested) { _, requested in
            if requested { selectedTab = .brush }
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
        HStack(spacing: 8) {
            settingsButton
            Spacer()
            BuddyView()
                .frame(width: 32, height: 36)
            DuoWordmark(text: "ToothBuddy", size: 24, face: .white, tracking: 0.5)
            Spacer()
            profileButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var settingsButton: some View {
        Button { showSettings = true } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
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
            case .family:
                GroupDashboardView()
                    .id("family")
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
    private static let tabOrder: [AppTab] = [.history, .brush, .family, .tips]

    private var customTabBar: some View {
        HStack(spacing: 6) {
            ForEach(Self.tabOrder, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .padding(.bottom, 24)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Duo.ink)
                .frame(height: 2),
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
                        BuddyView()
                            .frame(width: 26, height: 28)
                            .opacity(isSelected ? 1.0 : 0.5)
                    } else {
                        Image(systemName: tab.symbolName)
                            .font(.system(size: 22, weight: isSelected ? .bold : .regular))
                            .foregroundColor(isSelected ? .white : Duo.muted)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                .scaleEffect(isSelected ? 1.06 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)
                Text(tab.label)
                    .font(Duo.Fnt.ebd(11))
                    .tracking(0.4)
                    .foregroundColor(isSelected ? (tab == .brush ? Duo.ink : .white) : Duo.muted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(
                Group {
                    if isSelected {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Duo.greenShadow)
                                .offset(y: 3)
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Duo.green)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Duo.ink, lineWidth: 2)
                                )
                        }
                    }
                }
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(BounceButtonStyle())
    }
}

extension AppTab {
    // Plan U6: tab labels run through String(localized:) so Localizable.xcstrings
    // entries pick them up (Text(String) is verbatim; Text(LocalizedStringKey)
    // localizes, but switch-return Strings don't satisfy LocalizedStringKey
    // at the call site).
    var label: String {
        switch self {
        case .brush:   return String(localized: "Brush")
        case .history: return String(localized: "History")
        case .family:  return String(localized: "Family")
        case .tips:    return String(localized: "Tips")
        }
    }

    var symbolName: String {
        switch self {
        case .brush:   return "mouth.fill"
        case .history: return "chart.bar.fill"
        case .family:  return "person.3.fill"
        case .tips:    return "lightbulb.fill"
        }
    }
}
