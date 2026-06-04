import SwiftUI
import CoreText

@main
struct MyApp: App {
    init() {
        registerNunito()
        // Quality audit 2026-05-28 / Plan U3 — subscribe to MetricKit once at launch.
        // Apple delivers a daily payload on TestFlight / App Store builds (debug
        // builds never deliver). See MetricsSubscriber.swift for the never-remove
        // safety rule.
        MetricsSubscriber.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.font, NunitoFont.body)
        }
    }

    /// Registers all bundled Nunito font files so Font.custom() can find them.
    private func registerNunito() {
        sp("ColdLaunch.registerFonts") {
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
}

// MARK: - Root view

/// Shows onboarding only until it has been completed once (Spec 01 §4.8).
/// Returning users go straight to the main app. Reschedules reminders whenever
/// the app becomes active.
private struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    // U9 — referenced so ProfileStore.shared inits at launch and auto-creates the owner.
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
            } else {
                ContentView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
        .task {
            // Spec 05 §6.5 — clear any Live Activity left over from a killed session.
            BrushingLiveActivity.endStaleOnLaunch()
            // U3 (D-2) — if a session was in progress when the app was killed, commit its
            // (non-inflated) active time now instead of silently losing the brush.
            BrushingStore.shared.recoverPendingSession()
            WidgetBridge.refresh()
        }
        .onChange(of: scenePhase) { _, phase in
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
