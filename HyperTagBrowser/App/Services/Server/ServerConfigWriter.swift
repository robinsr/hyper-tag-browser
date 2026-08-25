import Foundation

/// Writes server-config.json to Application Support so the Go server knows which database to open.
/// The JSON format matches the Go `ServerConfig` struct: databasePath, port, enabled.
enum ServerConfigWriter {
    private struct Config: Encodable {
        var databasePath: String
        var port: Int
        var enabled: Bool
    }

    static func write(databasePath: String, port: Int = 8765, enabled: Bool) throws {
        let configDir = try configDirectory()
        let config = Config(databasePath: databasePath, port: port, enabled: enabled)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(config)
        try data.write(to: configDir.appendingPathComponent("server-config.json"))
    }

    private static func configDirectory() throws -> URL {
        let support = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = support.appendingPathComponent("com.robinsr.taggedfilebrowser")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
