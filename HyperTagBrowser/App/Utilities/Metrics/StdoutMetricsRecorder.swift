// created on 5/15/25 by robinsr

import Factory
import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk
import ResourceExtension
import SignPostIntegration
import StdoutExporter

//import Logging
import os


/**
 * A metrics recorder that records measurements to the console.
 */
struct StdoutMetricsRecorder: MetricsRecorder {
  static let shared = StdoutMetricsRecorder()
  
  let tracerProvider: TracerSdk
  let meter: StableMeter
  
  init() {
    let spanExporter = StdoutSpanExporter(format: .text)
    let spanProcessor = SimpleSpanProcessor(spanExporter: spanExporter)
    let resources = DefaultResources().get()

    let traceProvider = TracerProviderBuilder()
      .add(spanProcessor: spanProcessor)
      .add(spanProcessor: SignPostIntegration())
      .with(resource: resources)
      .build()

    OpenTelemetry.registerTracerProvider(tracerProvider: traceProvider)
    
    self.tracerProvider = OpenTelemetry.instance.tracerProvider.get(
      instrumentationName: Constants.appname,
      instrumentationVersion: "semver:0.1.0") as! TracerSdk
    
    let periodicExporter = StablePeriodicMetricReaderBuilder(exporter: StdoutMetricExporter(isDebug: false))
      .setInterval(timeInterval: 5.0)
      .build()
    
    let metricsProvider = StableMeterProviderBuilder()
      .registerMetricReader(reader: periodicExporter)
      // .registerView(
      //   selector: InstrumentSelectorBuilder().setInstrument(type: .histogram).build(),
      //   view: OpenTelemetrySdk.StableView.builder().build()
      // )
      .setResource(resource: resources)
      .build()
    
    
    OpenTelemetry.registerStableMeterProvider(meterProvider: metricsProvider)
    
    guard let sMeterProvider = OpenTelemetry.instance.stableMeterProvider?.get(name: Constants.appname) else {
      fatalError("Failed to get stable meter provider")
    }
    
    self.meter = sMeterProvider
    
  }
  
  func startAction(named name: String, attributes: AttributeValueMap) -> any StoppableMeasurement {
    let span = tracerProvider.spanBuilder(spanName: name)
      .setActive(true)
      .startSpan()
    
    for (key, value) in attributes {
      span.setAttribute(key: key, value: value)
    }
    
    return SpanMeasurement(span: span)
  }
  
  func startTimer(named name: String, attributes: AttributeValueMap) -> any StoppableMeasurement {
    let span = tracerProvider.spanBuilder(spanName: name)
      .startSpan()
    
    for (key, value) in attributes {
      span.setAttribute(key: key, value: value)
    }
    
    return SpanMeasurement(span: span)
  }
  
  func createHistogram(named name: String) -> any AggregatingMeasurement {
    HistogramMeasurement(histogram: meter.histogramBuilder(name: name).build())
  }
}


class StdoutSpanExporter: SpanExporter {
  //private let logger = EnvContainer.shared.logger("Metrics")
  private let logger = os.Logger(subsystem: Constants.appname, category: "StdoutSpanExporter")
  
  enum Format: String {
    case json, text
  }
  
  private let format: Format
  
  init(format: Format = .json) {
    self.format = format
  }
  
  func export(spans: [SpanData], explicitTimeout: TimeInterval?) -> SpanExporterResultCode {
    for span in spans {
      let data = StdoutSpanData(span: span)
      
      
      if case .json = format {
        let json = JSONEncoder.pretty(data)
        logger.info("Span.\(data.name) - \(json)")
      } else {
        let name = data.name
        let ms = data.timing.millis
        
        logger.info("Span.\(name, align: .left(columns: 40)) \(ms, align: .right(columns: 20)) ms")
      }
    }
    
    return .success
  }
  
  public func flush(explicitTimeout: TimeInterval?) -> SpanExporterResultCode { return .success }
  public func shutdown(explicitTimeout: TimeInterval?) {}
}


struct StdoutSpanData: Encodable, CustomDebugStringConvertible {
  let name: String
  let timing: SpanDataTiming
  let attributes: [String: AttributeValue]
  
  init(span: SpanData) {
    name = span.name
    attributes = span.attributes
    timing = SpanDataTiming(span.endTime.timeIntervalSince(span.startTime))
  }
  
  var debugDescription: String {
    let attrString = attributes.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
    
    return """
    SpanData(name: \(name), timing: \(timing.nanos) ns, attributes: {\(attrString)})
    """
  }
  
  struct SpanDataTiming: Encodable {
    let nanos: UInt64
    let millis: Float
    
    var intMillis: UInt64 {
      return UInt64(nanos / 1_000_000)
    }
    
    init(_ time: TimeInterval) {
      self.nanos = UInt64(time.toNanoseconds)
      self.millis = Float(time.toNanoseconds) / Float(1_000_000)
    }
  }
}
