// created on 5/15/25 by robinsr

import Factory
import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk
import ResourceExtension
import SignPostIntegration
import StdoutExporter
import SwiftMetricsShim


/**
 * A no-op metrics recorder that does nothing.
 */
struct NothingMetricsRecorder : MetricsRecorder {
  
  init() {
    
    let traceProvider = TracerProviderBuilder()
      .add(spanProcessor: SignPostIntegration())
      .with(resource: DefaultResources().get())
      .build()

    OpenTelemetry.registerTracerProvider(tracerProvider: traceProvider)
  }
  
  func startAction(named: String, attributes: AttributeValueMap) -> any StoppableMeasurement {
    return NothingMeasurement()
  }

  func startTimer(named: String, attributes: AttributeValueMap) -> any StoppableMeasurement {
    return NothingMeasurement()
  }
  
  func createHistogram(named: String) -> any AggregatingMeasurement {
    return NothingHistogram()
  }
  
  struct NothingMeasurement : StoppableMeasurement {
    func stop() {}
  }
  
  struct NothingHistogram : AggregatingMeasurement {
    var histogram: (any DoubleHistogram)? { nil }
    mutating func record(_ value: Double, attributes: AttributeValueMap) {}
  }
}
