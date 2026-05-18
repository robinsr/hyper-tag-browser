// created on 5/30/25 by robinsr

import Defaults
import Foundation
import Foundation
import GRDB
import JavaScriptCore
import OSLog


//@MainActor
actor SQLQueryFormatter {
  let namespace: String
  let logger: CustomLogger
  let jsFormatter = SQLJavascriptFormatter()

  init(namespace: String) {
    self.namespace = namespace
    self.logger = EnvContainer.shared.logger(namespace)
  }

  private var queryableFlags: Set<QueryableDevFlags> {
    return Defaults[.debugQueryables]
  }
  
  func formatSQL(_ sql: String) async -> String {
    await Task {
      await MainActor.run {
        var out = sql
        
        if let formatter = jsFormatter {
          Task {
            out = await formatter.format(sql: sql) ?? sql
          }
        }
        
        return out
      }
    }.value
  }

  func dumpRequest<T>(
    _ db: Database,
    _ request: QueryInterfaceRequest<T>,
    file: String = #file,
    function: String = #function
  ) {
    let location = CodeLocation(file, function, separator: "#")

    guard let queryTable = QueryableDevFlags(rawValue: location.module) else {
      logger.emit(.warning, "Unrecognized debug module \(location.module.quoted)")
      return
    }
    
    guard queryableFlags.contains(queryTable) else { return }

    do {
      var output = try request.toSQL(using: db)
      
      Task {
        output = await self.formatSQL(output)
        self.logger.emit(.debug, ["\(location.label) Request:", output].joined(separator: "\n"))
      }
    } catch {
      logger.emit(.error, "\(location.label) Failed to dump request: \(error)")
    }
  }
}


//@MainActor
actor SQLJavascriptFormatter {
  private let context: JSContext

  init?() {
    guard let context = JSContext() else { return nil }
    self.context = context

    // Log JS exceptions to help debug
    context.exceptionHandler = { _, exception in
      print("JS Error:", exception?.toString() ?? "unknown error")
    }

    // Load the bundled JS file
    guard let path = Bundle.main.path(forResource: "sql-formatter.bundle", ofType: "js"),
          let source = try? String(contentsOfFile: path, encoding: .utf8) else {
        return nil
    }

    context.evaluateScript(source)
  }

  func format(sql: String) -> String? {
    // Get the global function
    guard let fn = context.objectForKeyedSubscript("formatSQL") else {
      print("formatSQL is not defined in JS context")
      return nil
    }

    let result = fn.call(withArguments: [sql])
    return result?.toString()
  }
}
