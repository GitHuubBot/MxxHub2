import Foundation

struct RuntimeStatus {
    let name: String
    let version: String
    let installed: Bool
    let jitRequired: Bool
}

protocol WindowsRuntimeProtocol {
    func status() -> RuntimeStatus
    func launch(game: GameEntry, folder: URL, executable: URL) throws
}

/// V0.1 runtime placeholder.
/// The launcher and importer are real; Wine/Box64 will be connected here next.
struct StubWindowsRuntime: WindowsRuntimeProtocol {
    static let shared = StubWindowsRuntime()

    func status() -> RuntimeStatus {
        RuntimeStatus(
            name: "Wine + Box64",
            version: "not bundled",
            installed: false,
            jitRequired: true
        )
    }

    func launch(game: GameEntry, folder: URL, executable: URL) throws {
        throw RuntimeError.notInstalled(executable.lastPathComponent)
    }

    enum RuntimeError: LocalizedError {
        case notInstalled(String)

        var errorDescription: String? {
            switch self {
            case .notInstalled(let exe):
                return "The iOS launcher is working and selected \(exe), but the Windows runtime is not bundled in v0.1 yet. The next milestone is Wine/Box64 + graphics/JIT."
            }
        }
    }
}
