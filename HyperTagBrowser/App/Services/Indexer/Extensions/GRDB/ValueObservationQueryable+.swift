// created on 2/3/25 by robinsr

import CustomDump
import Defaults
import Factory
import Foundation
import GRDBQuery
import GRDB


extension ValueObservationQueryable {
  
  private func getFileInfo(file: String, function: String) -> (String, String) {
    let funcNameRegex = try! NSRegularExpression(pattern: "\\(.*\\)", options: [])
    let basename = URL(fileURLWithPath: file).deletingPathExtension().lastPathComponent
    let funcName = function.replacingOccurrences(of: funcNameRegex, with: "")

    return (basename, funcName)
  }
  
  /**
   * Returns a timer to measure the time it took to fetch the value.
   */
  func startTimer(
    file: String = #file,
    function: String = #function
  ) -> StoppableMeasurement {
    let (basename, funcName) = getFileInfo(file: file, function: function)
    
    let metricName = "\(basename)_\(funcName)"
    
    return Container.shared.metricsRecorder().startTimer(
      named: metricName,
      attributes: [
        "thread": .string(Thread.current.name ?? "unknown"),
      ]
    
    )
  }
  
  
  /**
   * Measures the time taken to execute the fetch block
   */
  func timeRequest(
    file: String = #file,
    function: String = #function,
    block: () throws -> Value
  ) rethrows -> Value {
    let timer = startTimer(file: file, function: function)
    
    defer { timer.stop() }
    
    return try block()
  }
  
  
  func prepare<T, Q>(
    _ db: Database,
    _ request: QueryInterfaceRequest<Q>,
    fetch: ((QueryInterfaceRequest<Q>) throws -> T),
    file: String = #file,
    function: String = #function
  ) throws -> T {
    
    if Defaults[.devFlags].contains(.indexer_debugSqlStatements) {
      dumpRequest(db, request, file: file, function: function)
    }
    
    let response = try fetch(request)
    
    if Defaults[.devFlags].contains(.indexer_debugSqlResponses) {
      dumpResponse(response, file: file, function: function)
    }
    
    return response
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
    
    let log = EnvContainer.shared.logger("ValueObservationQueryable")
    
    do {
      let sql = try request.toSQL(using: db, format: true)
      
      log.emit(.debug, ["\(basename)#\(funcName) Request:", sql].joined(separator: "\n"))
    } catch {
      log.emit(.debug, "Failed to dump request: \(error)")
    }
  }
  
  func dumpResponse<T>(
    _ response: [T],
    file: String = #file,
    function: String = #function
  ) {
    let (basename, funcName) = getFileInfo(file: file, function: function)
    
    let enabledOnTables = Defaults[.debugQueryables]
    
    guard let queryTable = QueryableDevFlags(rawValue: basename) else { return }
    
    guard enabledOnTables.contains(queryTable) else { return }
    
    let log = EnvContainer.shared.logger("ValueObservationQueryable")

    log.dump(response, label: "\(basename)#\(funcName) Response:")
  }
  
  func dumpResponse<T>(
    _ response: T,
    file: String = #file,
    function: String = #function
  ) {
    let (basename, funcName) = getFileInfo(file: file, function: function)
    
    let enabledOnTables = Defaults[.debugQueryables]
    
    guard let queryTable = QueryableDevFlags(rawValue: basename) else { return }
    
    guard enabledOnTables.contains(queryTable) else { return }
    
    let log = EnvContainer.shared.logger("ValueObservationQueryable")

    log.dump(response, label: "\(basename)#\(funcName) Response:")
  }
}
