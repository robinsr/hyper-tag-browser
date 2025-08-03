// created on 2/8/25 by robinsr

import Foundation
import Factory



/*
 A simple struct to measure the time taken to execute a block of code.
 */
struct SelfTimer {
  
  @Injected(\Container.metricsRecorder) private var metricsRecorder
  
  private func getName(file: String = #file, function: String = #function) -> String {
    let funcNameRegex = try! NSRegularExpression(pattern: "\\(.*\\)", options: [])
    let basename = URL(fileURLWithPath: file).deletingPathExtension().lastPathComponent
    let funcName = function.replacingOccurrences(of: funcNameRegex, with: "")
    
    return "\(basename)#\(funcName)"
  }
  
  /**
   Returns a timer to measure the time it took to fetch the value.
   */
  func startTimer(file: String = #file, function: String = #function) -> StoppableMeasurement {
    metricsRecorder.startTimer(
      named: getName(file: file, function: function),
      attributes: [
        "thread": .string(Thread.current.name ?? "unknown")
      ]
    )
  }
  
  
  /**
   Measures the time taken to execute the fetch block
   */
  func timeExecution<T>(file: String = #file, function: String = #function, block: () throws -> T) rethrows -> T {
    let timer = startTimer(file: file, function: function)
    defer { timer.stop() }
    return try block()
  }
  
  func timeExecution<T>(file: String = #file, function: String = #function, block: () async throws -> T) async rethrows -> T {
    let timing = startTimer(file: file, function: function)
    defer { timing.stop() }
    return try await block()
  }
  
  
  
  /**
   WIP - not working yet
   */
  func timeExecution<T>(aggregatedTo aggregator: AggregatingMeasurement, file: String = #file, function: String = #function, block: () throws -> T) rethrows -> T {
    let startTime = Date.now
    var histogram = metricsRecorder.createHistogram(named: getName(file: file, function: function))
    
    defer {
      let nanoseconds = Date.now.timeIntervalSince(startTime).toNanoseconds.toDouble
      print("recording \(nanoseconds)")
      
      histogram.record(nanoseconds, attributes: ["thread": .string(Thread.current.name ?? "unknown")])
    }
    
    return try block()
  }
  
  func timeExecution<T>(aggregatedTo aggregator: AggregatingMeasurement, file: String = #file, function: String = #function, block: () async throws -> T) async rethrows -> T {
    let startTime = Date.now
    var histogram = metricsRecorder.createHistogram(named: getName(file: file, function: function))
    
    defer {
      let nanoseconds = Date.now.timeIntervalSince(startTime).toNanoseconds.toDouble
      print("recording \(nanoseconds)")
      histogram.record(nanoseconds, attributes: ["thread": .string("unknown")])
    }
    
    return try await block()
  }
}
