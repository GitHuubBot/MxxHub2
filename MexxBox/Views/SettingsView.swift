import SwiftUI

struct SettingsView: View {
    @State private var runtimeStatus = RuntimeStatus(name: "Wine + Box64", version: "checking", installed: false, jitRequired: true)

    var body: some View {
        NavigationStack {
            Form {
                Section("Runtime") {
                    LabeledContent("Backend", value: runtimeStatus.name)
                    LabeledContent("Version", value: runtimeStatus.version)
                    LabeledContent("Installed", value: runtimeStatus.installed ? "Yes" : "No")
                    LabeledContent("JIT", value: runtimeStatus.jitRequired ? "Required for fast x86/x64" : "Not required")
                }

                Section("Milestone") {
                    Label("Game library", systemImage: "checkmark.circle.fill")
                    Label("Folder import", systemImage: "checkmark.circle.fill")
                    Label(".exe scanner", systemImage: "checkmark.circle.fill")
                    Label("Persistent folder bookmarks", systemImage: "checkmark.circle.fill")
                    Label("Wine/Box64 execution", systemImage: "circle.dashed")
                    Label("DirectX → Metal", systemImage: "circle.dashed")
                    Label("Controller/touch runtime input", systemImage: "circle.dashed")
                }

                Section("Version") {
                    LabeledContent("MexxBox", value: "0.1 Launcher Prototype")
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                runtimeStatus = StubWindowsRuntime.shared.status()
            }
        }
    }
}
