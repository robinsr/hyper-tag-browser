// created on 5/15/25 by robinsr

import Factory
import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk
import ResourceExtension
import SignPostIntegration

struct GraphiteMetricsRecorder: MetricsRecorder {
  var tracerProvider: OpenTelemetrySdk.TracerSdk

  private let client: GraphiteMetricsClient

  init() {
    self.client = GraphiteMetricsClient()

    let spanExporter = GraphiteMetricsSpanExporter(client: self.client)
    let spanProcessor = SimpleSpanProcessor(spanExporter: spanExporter)
    let resources = DefaultResources().get()

    let traceProvider = TracerProviderBuilder()
      .add(spanProcessor: spanProcessor)
      .with(resource: resources)
      .build()

    OpenTelemetry.registerTracerProvider(tracerProvider: traceProvider)

    self.tracerProvider =
      OpenTelemetry.instance.tracerProvider.get(
        instrumentationName: Constants.appname,
        instrumentationVersion: "semver:0.1.0") as! TracerSdk
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
    NothingMetricsRecorder.NothingHistogram()
  }
}

class GraphiteMetricsSpanExporter: OpenTelemetrySdk.SpanExporter {

  private var client: GraphiteMetricsClient

  init(client: GraphiteMetricsClient) {
    self.client = client
  }

  func export(spans: [SpanData], explicitTimeout: TimeInterval?) -> SpanExporterResultCode {
    for span in spans {
      let spandata = GraphiteMetricsData(spandata: span)
      self.client.send(spandata.metricsMessage)
    }

    return .success
  }

  public func flush(explicitTimeout: TimeInterval?) -> SpanExporterResultCode { return .success }
  public func shutdown(explicitTimeout: TimeInterval?) {}
}

struct GraphiteMetricsData: Encodable {
  let name: String
  let start: Date
  let duration: Duration
  let attributes: [String: AttributeValue]

  init(spandata span: SpanData) {
    name = span.name
    start = span.startTime
    duration = Duration(start: span.startTime, end: span.endTime)
    attributes = span.attributes
  }

  var metricsMessage: String {
    let dimensions = metricsDimensions.map { "\($0)=\($1)" }.joined(separator: ",")
    return "\(metricsLabel) \(duration.nanoseconds) \(dimensions)"
  }

  var metricsLabel: String {
    "span.\(name)"
  }

  /// Converts the span attributes into a format suitable for Graphite dimensions.
  var metricsDimensions: [(String, String)] {
    let dimensions = attributes.map { key, value in
      let formattedValue: String

      switch value {
        case .string(let stringValue):
          formattedValue = stringValue
        case .bool(let boolValue):
          formattedValue = boolValue ? "1" : "0"
        case .int(let intVal):
          formattedValue = "\(intVal)"
        case .double(let doubleVal):
          formattedValue = "\(doubleVal)"
        case .array(let valueArray):
          formattedValue = valueArray.values.map { "\($0)" }.joined(separator: ",")
        case .set(let valueSet):
          formattedValue = valueSet.labels.map { "\($0):\($1)" }.joined(separator: ",")
        default:
          formattedValue = "\(value)"
      }

      return (key, formattedValue)
    }

    return dimensions.map { (key, value) in
      // Ensure the key is a valid Graphite dimension name
      let sanitizedKey = key.replacingOccurrences(of: " ", with: "_").lowercased()
      return (sanitizedKey, value)
    }
  }

  struct Duration: Encodable {
    let nanoseconds: UInt64
    let milliseconds: UInt64

    init(start: Date, end: Date) {
      self.nanoseconds = UInt64(end.timeIntervalSince(start).toNanoseconds)
      self.milliseconds = UInt64(end.timeIntervalSince(start).toMilliseconds)
    }
  }
}

struct GraphiteMetricsClient {
  private let statsdClient: StatsdClient

  init() {
    self.statsdClient = StatsdClient(host: "0.0.0.0", port: 2003)
  }

  func send(_ message: String) {
    Task {
      do {
        try await statsdClient.send(message)
      } catch {
        print("Failed to send Graphite message: \(error)")
      }
    }
  }

  struct StatsdClient {
    let host: String
    let port: UInt16

    enum SendResult {
      case success
      case failure(String)
    }

    func send(_ message: String) async throws {

      let result = await Task.detached(priority: .background) {
        let socketFD = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        guard socketFD >= 0 else {
          perror("socket creation failed")
          return SendResult.failure("socket creation failed")
        }

        var serverAddr = sockaddr_in()
        serverAddr.sin_family = sa_family_t(AF_INET)
        serverAddr.sin_port = port.bigEndian
        inet_pton(AF_INET, host, &serverAddr.sin_addr)

        let messageData = message.data(using: .utf8)!
        let result = messageData.withUnsafeBytes { buffer in
          buffer.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: buffer.count) { basePtr in
            withUnsafePointer(to: serverAddr) { addrPtr in
              addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockAddrPtr in
                sendto(
                  socketFD, basePtr, buffer.count, 0, sockAddrPtr,
                  socklen_t(MemoryLayout<sockaddr_in>.size))
              }
            }
          }
        }

        if result < 0 {
          perror("sendto failed")
          return SendResult.failure("sendto failed")
        }

        close(socketFD)

        return SendResult.success
      }.value

      if case .failure(let msg) = result {
        throw GraphiteClientError.clientMsgSendFailed(msg)
      }
    }
  }
}

enum GraphiteClientError: Error {
  case clientNotInitialized
  case clientMsgSendFailed(String)
}
