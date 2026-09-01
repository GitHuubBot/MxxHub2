import SwiftUI

struct SettingsView: View {
    private let runtime = WindowsRuntime.status

    var body: some View {
        NavigationStack {
            Form {
                Section("MxxHub") {
                    LabeledContent("Version", value: "0.3")
                    LabeledContent("Runtime", value: runtime.name)
                    LabeledContent("Runtime build", value: runtime.version)
                }

                Section("Windows compatibility") {
                    Label("PE32 / PE32+ loader", systemImage: "checkmark.circle.fill")
                    Label("x86 / x86-64 translation", systemImage: "checkmark.circle.fill")
                    Label("Win32 API layer", systemImage: "wrench.and.screwdriver.fill")
                    Label("Metal Win32 compositor", systemImage: "display")
                    Label("Direct3D game rendering: future milestone", systemImage: "exclamationmark.triangle")
                }

                Section("Current target") {
                    Text("First prove that normal 32-bit and 64-bit Windows programs execute from the MxxHub library. After that the graphics work moves to DirectX/Unity/Source-engine compatibility for games such as Hollow Knight, Portal and Half-Life 2.")
                }

                Section("Important") {
                    Text("This is an experimental sideload build. A recognized .exe does not mean the game is compatible yet. Hollow Knight is 64-bit and MxxHub can now hand it to the x64 runtime, but the game still needs graphics and Windows APIs that are not complete.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
