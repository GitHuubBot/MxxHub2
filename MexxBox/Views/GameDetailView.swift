import SwiftUI

struct GameDetailView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    @State var game: GameEntry
    @State private var launchError: String?
    @State private var launchSuccess: RuntimeLaunchResult?
    @State private var launching = false
    @State private var peInfo: PEInfo?

    var body: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 54))
                    Text(game.name)
                        .font(.title2.bold())
                    Text(game.executableRelativePath)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)

                    Button {
                        launch()
                    } label: {
                        HStack {
                            if launching { ProgressView() }
                            Image(systemName: "play.fill")
                            Text(launching ? "Starting…" : "Play / Runtime Test")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(launching)
                }
                .frame(maxWidth: .infinity)
            }

            Section("Windows executable") {
                LabeledContent("Architecture", value: peInfo?.architecture.rawValue ?? "Checking…")
                LabeledContent("Subsystem", value: peInfo?.subsystem.rawValue ?? "—")
                if let peInfo {
                    LabeledContent("Entry point", value: String(format: "RVA 0x%08X", peInfo.entryPointRVA))
                    LabeledContent("Sections", value: "\(peInfo.sections.count)")
                }
            }

            Section("Game") {
                TextField("Name", text: $game.name)
                LabeledContent("Executable", value: game.executableRelativePath)
            }

            Section("Compatibility") {
                Picker("Renderer", selection: $game.settings.renderer) {
                    ForEach(GameSettings.Renderer.allCases) { renderer in
                        Text(renderer.rawValue).tag(renderer)
                    }
                }
                TextField("Resolution", text: $game.settings.resolution)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Stepper("Memory target: \(game.settings.memoryLimitMB) MB", value: $game.settings.memoryLimitMB, in: 512...8192, step: 256)
            }

            Section("Input") {
                Toggle("Controller", isOn: $game.settings.useController)
                Toggle("Touch controls", isOn: $game.settings.showTouchControls)
            }

            Section("Launch") {
                TextField("Arguments", text: $game.settings.launchArguments, axis: .vertical)
                    .font(.body.monospaced())
            }

            Section {
                Button("Save Settings") { store.update(game) }
                Button("Remove from Library", role: .destructive) {
                    store.remove(game)
                    dismiss()
                }
            } footer: {
                Text("v0.2 can execute the included tiny x86 Windows PE test. Real games will intentionally stop on unsupported instructions until the full Win32/WineGlass backend is integrated.")
            }
        }
        .navigationTitle(game.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { inspectExecutable() }
        .alert("Windows runtime", isPresented: Binding(
            get: { launchError != nil },
            set: { if !$0 { launchError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(launchError ?? "")
        }
        .alert(launchSuccess?.title ?? "Runtime test", isPresented: Binding(
            get: { launchSuccess != nil },
            set: { if !$0 { launchSuccess = nil } }
        )) {
            Button("Great", role: .cancel) {}
        } message: {
            Text(launchSuccess?.message ?? "")
        }
    }

    private func inspectExecutable() {
        do {
            let folder = try store.resolvedFolder(for: game)
            guard folder.startAccessingSecurityScopedResource() else { return }
            defer { folder.stopAccessingSecurityScopedResource() }
            let executable = folder.appendingPathComponent(game.executableRelativePath)
            peInfo = try PEInspector.inspect(url: executable)
        } catch {
            peInfo = nil
        }
    }

    private func launch() {
        launching = true
        defer { launching = false }
        do {
            let folder = try store.resolvedFolder(for: game)
            let executable = folder.appendingPathComponent(game.executableRelativePath)
            launchSuccess = try BringUpWindowsRuntime.shared.launch(game: game, folder: folder, executable: executable)
        } catch {
            launchError = error.localizedDescription
        }
    }
}
