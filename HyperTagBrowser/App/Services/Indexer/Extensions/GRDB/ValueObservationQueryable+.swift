// created on 2/3/25 by robinsr

import CustomDump
import Defaults
import Factory
import Foundation
import GRDBQuery
import GRDB


extension ValueObservationQueryable {
  
  /**
   * Returns a timer to measure the time it took to fetch the value.
   */
  func startTimer(file: String = #file, function: String = #function) -> StoppableMeasurement {
    return Container.shared.metricsRecorder().startTimer(
      named: MetricSource(file, function).name,
      attributes: [
        "thread": .string(Thread.current.name ?? "unknown"),
      ]
    )
  }
  
  private var debugFlag: QueryableDevFlags? {
    QueryableDevFlags(rawValue: CodeLocation(#file, #function).filename)
  }
  
  private var queryLogEnabled: Bool {
    if let flag = self.debugFlag {
      return Defaults[.debugQueryables].contains(flag)
    } else {
      return false
    }
  }
  
  
  /**
   * Measures the time taken to execute the fetch block
   */
  func timeRequest(
    file: String = #file, function: String = #function, block: () throws -> Value
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
    guard queryLogEnabled else { return }
    let metric = MetricSource(file, function)
    let log = EnvContainer.shared.logger("ValueObservationQueryable")
    
    do {
      let sql = try request.toSQL(using: db)
      
      log.emit(.debug, "\(metric.name) Request: \n \(sql)")
    } catch {
      log.emit(.debug, "Failed to dump request: \(error)")
    }
  }
  
  func dumpResponse<T>(
    _ response: [T],
    file: String = #file,
    function: String = #function
  ) {
    guard queryLogEnabled else { return }
    let metric = MetricSource(file, function)
    let log = EnvContainer.shared.logger("ValueObservationQueryable")

    log.dump(response, label: "\(metric.name) Response:")
  }
  
  func dumpResponse<T>(
    _ response: T,
    file: String = #file,
    function: String = #function
  ) {
    guard queryLogEnabled else { return }
    let metric = MetricSource(file, function)
    let log = EnvContainer.shared.logger("ValueObservationQueryable")

    log.dump(response, label: "\(metric.name) Response:")
  }
}
