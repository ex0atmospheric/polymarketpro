import SwiftUI

@main
struct PolymarketProApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1100, height: 700)

        Settings {
            SettingsView()
                .frame(width: 500, height: 500)
        }
    }
}
