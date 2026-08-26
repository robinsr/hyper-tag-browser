// created on 2/6/25 by robinsr

import CustomDump
import Factory
import Foundation


/**
 * Defines the runtime args recognized by the app
 */
struct RunFlags: Encodable {
  
  enum CodingKeys: String, CodingKey, CaseIterable {
    case profileId = "--profile"
    case profileName = "--profile-name"
    case emitMetrics = "--emit-metrics"
    case uiTestMode = "--UITestMode"
    case liveIndex = "--LiveIndex"
    case launchFolderPath = "--LaunchFolderPath"
    case loadSavedQuery = "--LoadSavedQuery"
  }

  var args: [String] {
    ProcessInfo.processInfo.arguments
  }
  
  var string: String {
    let codingkeys = CodingKeys.allCases.map { $0.rawValue }
    
    return args
      .filter { codingkeys.contains($0) }
      .joined(separator: " ")
  }
  
  var profileId: String? {
    getRuntimeValue(forKey: CodingKeys.profileId.rawValue)
  }

  var profileName: String? {
    getRuntimeValue(forKey: CodingKeys.profileName.rawValue)
  }
  
  var emitMetrics: Bool {
    getRuntimeValue(forKey: CodingKeys.emitMetrics.rawValue) != nil
  }

  var uiTestMode: Bool {
    hasRuntimeArgument(CodingKeys.uiTestMode.rawValue)
  }

  var liveIndex: Bool {
    hasRuntimeArgument(CodingKeys.liveIndex.rawValue)
  }

  var launchFolderPath: String? {
    getRuntimeValue(forKey: CodingKeys.launchFolderPath.rawValue)
  }

  var loadSavedQuery: String? {
    getRuntimeValue(forKey: CodingKeys.loadSavedQuery.rawValue)
  }

    /// Find the argument that starts with the specified key/
  func getRuntimeValue(forKey key: String) -> String? {
    args
      .first(where: { $0.hasPrefix(key) })
      .flatMap { $0.split(separator: "=").last.map(String.init) }
  }
  
    /// Check if the argument exists in the command line arguments/
  func hasRuntimeArgument(_ key: String) -> Bool {
    args.contains(where: { $0.hasPrefix(key) })
  }

  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encodeIfPresent(profileId, forKey: .profileId)
    try container.encodeIfPresent(profileName, forKey: .profileName)
    try container.encodeIfPresent(emitMetrics, forKey: .emitMetrics)
    try container.encodeIfPresent(uiTestMode, forKey: .uiTestMode)
    try container.encodeIfPresent(liveIndex, forKey: .liveIndex)
    try container.encodeIfPresent(launchFolderPath, forKey: .launchFolderPath)
    try container.encodeIfPresent(loadSavedQuery, forKey: .loadSavedQuery)
  }
}
