import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modifier(RoundedFontModifier())
        }
    }
}

/// Applies SF Pro Rounded globally on iOS 16.1+; no-op on iOS 16.0.
private struct RoundedFontModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.1, *) {
            content.fontDesign(.rounded)
        } else {
            content
        }
    }
}
