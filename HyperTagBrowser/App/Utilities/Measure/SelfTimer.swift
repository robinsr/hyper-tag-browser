// created on 2/8/25 by robinsr

import Foundation
import Factory



/*
 * A simple struct to measure the time taken to execute a block of code.
 */
struct SelfTimer {
  
  @Injected(\Container.metricsRecorder) private var metricsRecorder
  
  /**
   Returns a timer to measure the time it took to fetch the value.
   */
  func startTimer(metric: MetricSource) -> StoppableMeasurement {
    metricsRecorder.startTimer(
      named: metric.name,
      attributes: [
        "thread": .string(Thread.current.name ?? "unknown")
      ]
    )
  }
  
  
  /**
   * Measures the time taken to execute the supplied code block and emits the time result into metrics
   */
  func timeExecution<T>(file: String = #file, function: String = #function, block: () throws -> T) rethrows -> T {
    let timer = startTimer(metric: MetricSource(file, function))
    defer { timer.stop() }
    return try block()
  }
  
  /**
   * Measures the time taken to execute the supplied code block and emits
   * the time result into metrics using the supplied `MetricSource`
   */
  func timeExecution<T>(using metric: MetricSource, block: () throws -> T) rethrows -> T {
    let timing = startTimer(metric: metric)
    defer { timing.stop() }
    return try block()
  }
  
  /**
   * Async variant of ``timeExecution(file:function:block:)-3vur6``
   */
  func timeExecution<T>(file: String = #file, function: String = #function, block: () async throws -> T) async rethrows -> T {
    let timing = startTimer(metric: MetricSource(file, function))
    defer { timing.stop() }
    return try await block()
  }
  
  
  /**
   WIP - not working yet
   */
//  func timeExecution<T>(aggregatedTo aggregator: AggregatingMeasurement, file: String = #file, function: String = #function, block: () throws -> T) rethrows -> T {
//    let startTime = Date.now
//    let metric = MetricSource(file, function)
//    var histogram = metricsRecorder.createHistogram(named: metric.name)
//    
//    defer {
//      let nanoseconds = Date.now.timeIntervalSince(startTime).toNanoseconds.toDouble
//      print("recording \(nanoseconds)")
//      
//      histogram.record(nanoseconds, attributes: ["thread": .string(Thread.current.name ?? "unknown")])
//    }
//    
//    return try block()
//  }
  
//  func timeExecution<T>(aggregatedTo aggregator: AggregatingMeasurement, file: String = #file, function: String = #function, block: () async throws -> T) async rethrows -> T {
//    let startTime = Date.now
//    let metric = MetricSource(file, function)
//    var histogram = metricsRecorder.createHistogram(named: metric.name)
//    
//    defer {
//      let nanoseconds = Date.now.timeIntervalSince(startTime).toNanoseconds.toDouble
//      print("recording \(nanoseconds)")
//      histogram.record(nanoseconds, attributes: ["thread": .string("unknown")])
//    }
//    
//    return try await block()
//  }
}
