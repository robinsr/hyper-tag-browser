import Foundation
import ServiceManagement

/// Manages the HyperTagBrowserServer Login Item agent via SMAppService.
///
/// Usage: call `enable(databasePath:)` to register the agent with launchd and write
/// the server config. Call `disable(databasePath:)` to unregister and mark the server
/// as disabled. Wire `writeConfig(enabled:)` into the app lifecycle (launch / quit).
@MainActor
final class ServerManager: ObservableObject {
    static let shared = ServerManager()

    private let service = SMAppService.agent(
        plistName: "com.robinsr.taggedfilebrowser.server.plist"
    )

    @Published private(set) var isEnabled: Bool = false

    init() {
        isEnabled = service.status == .enabled
    }

    var status: SMAppService.Status {
        service.status
    }

    /// Registers the agent and writes the server config with `enabled: true`.
    func enable(databasePath: String, port: Int = 8765) throws {
        try ServerConfigWriter.write(databasePath: databasePath, port: port, enabled: true)
        try service.register()
        isEnabled = true
    }

    /// Unregisters the agent and writes the server config with `enabled: false`.
    func disable(databasePath: String, port: Int = 8765) throws {
        try ServerConfigWriter.write(databasePath: databasePath, port: port, enabled: false)
        try service.unregister()
        isEnabled = false
    }

    /// Updates the config file without changing the agent registration status.
    /// Call on app launch/quit to keep `enabled` in sync with the running app.
    func writeConfig(databasePath: String, port: Int = 8765, enabled: Bool) {
        try? ServerConfigWriter.write(databasePath: databasePath, port: port, enabled: enabled)
    }
}
