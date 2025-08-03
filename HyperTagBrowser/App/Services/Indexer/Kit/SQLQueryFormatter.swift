// created on 5/30/25 by robinsr

import Defaults
import Foundation
import GRDB
import OSLog


struct SQLQueryFormatter {
  
  let namespace: String
  let logger: os.Logger
  
  init(namespace: String) {
    self.namespace = namespace
    self.logger = EnvContainer.shared.logger(namespace)
  }
  
  func dumpRequest<T>(
    _ db: Database,
    _ request: QueryInterfaceRequest<T>,
    file: String = #file,
    function: String = #function
  ) {
    let (basename, funcName) = getFileInfo(file: file, function: function)
    let enabledOnTables = Defaults[.debugQueryables]
    guard let queryTable = QueryableDevFlags(rawValue: basename) else { return }
    guard enabledOnTables.contains(queryTable) else { return }

    do {
      let sql = try request.toSQL(using: db, format: true)
      logger.emit(.debug, ["\(basename)#\(funcName) Request:", sql].joined(separator: "\n"))
    } catch {
      logger.emit(.debug, "Failed to dump request: \(error)")
    }
  }

  private func getFileInfo(file: String, function: String) -> (String, String) {
    let funcNameRegex = try! NSRegularExpression(pattern: "\\(.*\\)", options: [])
    let basename = URL(fileURLWithPath: file).deletingPathExtension().lastPathComponent
    let funcName = function.replacingOccurrences(of: funcNameRegex, with: "")

    return (basename, funcName)
  }
}
