// created on 2/4/25 by robinsr

import Foundation

extension JSONEncoder {
  
  convenience init(
    dateEncodingStrategy: DateEncodingStrategy,
    keyEncodingStrategy: KeyEncodingStrategy = .useDefaultKeys,
    dataEncodingStrategy: DataEncodingStrategy = .base64,
    outputFormatting: OutputFormatting = []
  ) {
    self.init()
    self.dateEncodingStrategy = dateEncodingStrategy
    self.outputFormatting = outputFormatting
    self.keyEncodingStrategy = keyEncodingStrategy
    self.dataEncodingStrategy = dataEncodingStrategy
  }
  
  
  static var defaultPrinter: JSONEncoder {
    JSONEncoder(
      dateEncodingStrategy: .iso8601,
      outputFormatting: []
    )
  }
  
  static var prettyPrinter: JSONEncoder {
    JSONEncoder(
      dateEncodingStrategy: .iso8601,
      outputFormatting: [.prettyPrinted, .sortedKeys]
    )
  }
  
  static func prettyPrinter(omitData: Bool = true) -> JSONEncoder {
    JSONEncoder(
      dateEncodingStrategy: .iso8601,
      dataEncodingStrategy: omitData ? .omitData : .deferredToData,
      outputFormatting: [.prettyPrinted, .sortedKeys]
    )
  }
  
  static func compact(_ enc: Encodable) -> String {
    if let data = try? defaultPrinter.encode(enc) {
      return String(data: data, encoding: .utf8)!
    } else {
      return "{ \"error\": \"failed to encode\" }"
    }
  }
  
  static func pretty(_ enc: Encodable) -> String {
    if let data = try? Self.prettyPrinter(omitData: true).encode(enc) {
      return String(data: data, encoding: .utf8)!
    } else {
      return "{ \"error\": \"failed to encode\" }"
    }
  }
  
  static func pretty(_ anyObj: Any) -> String {
    let jsonOpts: JSONSerialization.WritingOptions = [.prettyPrinted, .sortedKeys]
    
    if let data = try? JSONSerialization.data(withJSONObject: anyObj, options: jsonOpts) {
      return String(data: data, encoding: .utf8)!
    } else {
      return "{ \"error\": \"failed to encode\" }"
    }
  }
}

extension JSONEncoder.DataEncodingStrategy {
  static var omitData: JSONEncoder.DataEncodingStrategy {
    .custom({ _, encoder in
      var container = encoder.singleValueContainer()
      try container.encode("data omitted")
    })
  }
}


extension Encodable {
  var asJSON: String {
    JSONEncoder.pretty(self)
  }
}


extension String.StringInterpolation {
  enum JsonEncodingOption {
    case pretty, compact
  }
  
  mutating func appendInterpolation(json: Encodable, _ format: JsonEncodingOption = .pretty) {
    switch format {
    case .pretty:
      appendLiteral(JSONEncoder.pretty(json))
    case .compact:
      appendLiteral(JSONEncoder.compact(json))
    }
  }
}
