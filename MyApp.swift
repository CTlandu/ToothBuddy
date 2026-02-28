import SwiftUI
import CoreText

@main
struct MyApp: App {
    init() {
        registerNunito()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
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
