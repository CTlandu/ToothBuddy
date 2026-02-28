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

/// Shows onboarding on every launch so judges/reviewers see the full flow,
/// then transitions to the main app when the user taps "Start Brushing!".
private struct RootView: View {
    @State private var showOnboarding = true

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        showOnboarding = false
                    }
                }
            } else {
                ContentView()
                    .transition(.opacity)
            }
        }
    }
}
