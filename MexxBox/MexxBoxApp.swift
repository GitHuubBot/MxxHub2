import SwiftUI

@main
struct MexxBoxApp: App {
    @StateObject private var store = GameStore()

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
