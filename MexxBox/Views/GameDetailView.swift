import SwiftUI

struct GameDetailView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    @State var game: GameEntry
    @State private var launchError: String?
    @State private var launching = false

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
                            Text(launching ? "Starting…" : "Play")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(launching)
                }
                .frame(maxWidth: .infinity)
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
                Text("Removing a game from MexxBox does not delete the game folder from Files.")
            }
        }
        .navigationTitle(game.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Windows runtime", isPresented: Binding(
            get: { launchError != nil },
            set: { if !$0 { launchError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(launchError ?? "")
        }
    }

    private func launch() {
        launching = true
        defer { launching = false }
        do {
            let folder = try store.resolvedFolder(for: game)
            let executable = folder.appendingPathComponent(game.executableRelativePath)
            try StubWindowsRuntime.shared.launch(game: game, folder: folder, executable: executable)
        } catch {
            launchError = error.localizedDescription
        }
    }
}
