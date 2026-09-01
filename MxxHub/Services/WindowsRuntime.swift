import Foundation

struct RuntimeStatus {
    let name: String
    let version: String
    let installed: Bool
    let jitRequired: Bool
}

/// Runtime metadata used by the MxxHub UI. Actual v0.3 execution is hosted by
/// MxxWineRuntimeViewController, which calls WineGlass' C engine directly.
enum WindowsRuntime {
    static var status: RuntimeStatus {
        RuntimeStatus(
            name: "WineGlass + Blink",
            version: "0.3 experimental",
            installed: true,
            jitRequired: false
        )
    }
}
