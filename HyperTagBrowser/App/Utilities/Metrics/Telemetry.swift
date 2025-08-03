// created on 2/2/25 by robinsr

import Factory
import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk
import StdoutExporter
import ResourceExtension


typealias AttributeValueMap = [String: AttributeValue]


/**
 * Defines the basic functionality for recording metrics.
 */
protocol MetricsRecorder {
  var tracerProvider: TracerSdk { get }
  // var meter: StableMeter { get }
  
  
  func startAction(named: String, attributes: AttributeValueMap) -> any StoppableMeasurement
  func startTimer(named: String, attributes: AttributeValueMap) -> any StoppableMeasurement
  func createHistogram(named: String) -> any AggregatingMeasurement
}


/**
 * Defines methods for span measurements
 */
protocol StoppableMeasurement {
  func stop()
}

/**
 * Defines methods for histograms measurements
 */
protocol AggregatingMeasurement {
  var histogram: (any DoubleHistogram)? { get }
  
  mutating func record(_ value: Double, attributes: AttributeValueMap)
}


struct SpanMeasurement : StoppableMeasurement {
  let span: Span
  
  func stop() {
    span.end()
  }
}


struct HistogramMeasurement: AggregatingMeasurement {
  var histogram: (any DoubleHistogram)?
  
  mutating func record(_ value: Double, attributes: AttributeValueMap = [:]) {
    histogram?.record(value: value, attributes: attributes)
  }
}



