import Foundation

struct RuntimeStatus {
    let name: String
    let version: String
    let installed: Bool
    let jitRequired: Bool
}

struct RuntimeLaunchResult {
    let title: String
    let message: String
}

protocol WindowsRuntimeProtocol {
    func status() -> RuntimeStatus
    func launch(game: GameEntry, folder: URL, executable: URL) throws -> RuntimeLaunchResult
}

/// MexxBox v0.2 bring-up runtime.
/// This is a real PE loader + tiny x86 interpreter used to validate Windows
/// executable loading on iOS. It is NOT a replacement for Wine/Box64.
struct BringUpWindowsRuntime: WindowsRuntimeProtocol {
    static let shared = BringUpWindowsRuntime()

    func status() -> RuntimeStatus {
        RuntimeStatus(
            name: "PE32 + Mini x86",
            version: "0.2 bring-up",
            installed: true,
            jitRequired: false
        )
    }

    func launch(game: GameEntry, folder: URL, executable: URL) throws -> RuntimeLaunchResult {
        guard folder.startAccessingSecurityScopedResource() else {
            throw RuntimeError.permissionDenied
        }
        defer { folder.stopAccessingSecurityScopedResource() }

        let data = try Data(contentsOf: executable, options: [.mappedIfSafe])
        let info = try PEInspector.inspect(data: data)

        guard info.architecture == .x86 else {
            throw RuntimeError.backendNeeded(info)
        }

        do {
            let result = try MiniX86Interpreter.executePE32(data: data, info: info)
            return RuntimeLaunchResult(
                title: "x86 executable ran",
                message: "MexxBox loaded the Windows PE entry point and executed \(result.instructionCount) x86 instructions on iOS. EAX returned \(result.eax).\n\nIf you used MexxRuntimeTest.exe, EAX = 42 is the expected result."
            )
        } catch let error as MiniX86Interpreter.X86Error {
            throw RuntimeError.interpreterStopped(info, error.localizedDescription)
        }
    }

    enum RuntimeError: LocalizedError {
        case permissionDenied
        case backendNeeded(PEInfo)
        case interpreterStopped(PEInfo, String)

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "MexxBox lost access to the selected game folder. Remove it and add the folder again."
            case .backendNeeded(let info):
                return "MexxBox recognized this as \(info.summary). The v0.2 bring-up interpreter only executes 32-bit x86 test code. x64 games need the WineGlass/Box64 backend."
            case .interpreterStopped(let info, let detail):
                return "MexxBox recognized and loaded \(info.summary). \(detail)"
            }
        }
    }
}
