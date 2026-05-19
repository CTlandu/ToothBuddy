import SwiftUI
import CoreText

@main
struct MyApp: App {
    init() {
        registerNunito()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.font, NunitoFont.body)
        }
    }

    /// Registers all bundled Nunito font files so Font.custom() can find them.
    private func registerNunito() {
        let files = [
            "Nunito-Regular",
            "Nunito-SemiBold",
            "Nunito-Bold",
            "Nunito-ExtraBold",
        ]
        for name in files {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf"),
                  let provider = CGDataProvider(url: url as CFURL),
                  let font = CGFont(provider)
            else { continue }
            CTFontManagerRegisterGraphicsFont(font, nil)
        }
    }
}

// MARK: - Root view

/// Shows onboarding only until it has been completed once (Spec 01 §4.8).
/// Returning users go straight to the main app. Reschedules reminders whenever
/// the app becomes active.
private struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var profiles = ProfileStore.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        hasCompletedOnboarding = true
                    }
                }
            } else if profiles.activeProfile == nil {
                // First-run gate: must create or pick a profile (Spec 02 §6.2).
                ProfilePickerView(store: profiles, isGate: true)
                    .transition(.opacity)
            } else {
                ContentView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: profiles.activeProfile == nil)
        .task {
            // Spec 05 §6.5 — clear any Live Activity left over from a killed session.
            BrushingLiveActivity.endStaleOnLaunch()
            WidgetBridge.refresh()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                NotificationScheduler.shared.reschedule(
                    records: BrushingStore.shared.records,
                    streak: BrushingStore.shared.streak)
                NotificationScheduler.shared.rescheduleCare(
                    inputs: CareStore.shared.careInputs())
            } else if phase == .background {
                WidgetBridge.refresh()   // Spec 05 §6.4
            }
        }
    }
}
