import SwiftUI

struct SettingsView: View {
    @State private var runtimeStatus = RuntimeStatus(name: "PE32 + Mini x86", version: "checking", installed: false, jitRequired: false)

    var body: some View {
        NavigationStack {
            Form {
                Section("Runtime") {
                    LabeledContent("Backend", value: runtimeStatus.name)
                    LabeledContent("Version", value: runtimeStatus.version)
                    LabeledContent("Installed", value: runtimeStatus.installed ? "Yes" : "No")
                    LabeledContent("Current JIT", value: runtimeStatus.jitRequired ? "Required" : "Not used in bring-up runtime")
                }

                Section("Milestones") {
                    Label("Game library + folder bookmarks", systemImage: "checkmark.circle.fill")
                    Label("Windows MZ/PE parser", systemImage: "checkmark.circle.fill")
                    Label("x86 PE entry-point execution", systemImage: "checkmark.circle.fill")
                    Label("Win32 API layer", systemImage: "circle.dashed")
                    Label("WineGlass / Box64 backend", systemImage: "circle.dashed")
                    Label("DirectX → Metal", systemImage: "circle.dashed")
                    Label("Portal / Source Engine", systemImage: "circle.dashed")
                }

                Section("What v0.2 proves") {
                    Text("The included MexxRuntimeTest.exe is a real PE32 Windows executable. MexxBox parses its Windows headers, maps its entry point and interprets its x86 instructions. A returned EAX value of 42 means the on-device Windows binary execution bring-up path worked.")
                }

                Section("Version") {
                    LabeledContent("MexxBox", value: "0.2 PE/x86 Bring-up")
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                runtimeStatus = BringUpWindowsRuntime.shared.status()
            }
        }
    }
}
