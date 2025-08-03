// created on 4/30/25 by robinsr

import System


extension FilePath {
  var asCodable: CodableFilePath {
    CodableFilePath(wrappedValue: self)
  }
}


/**
 * A property wrapper that encodes and decodes a `FilePath` as a string, making it easier for debugging and serialization.
 *
 * Usage:
 *
 * ```swift
 * struct MyModel: Codable {
 *   @CodableFilePath var filePath: FilePath
 * }
 *
 * let model = MyModel(filePath: FilePath("/path/to/file"))
 *
 * print(model.filePath) // Outputs: /path/to/file
 */
@propertyWrapper
struct CodableFilePath: Codable {
  var wrappedValue: FilePath
  
  init(wrappedValue: FilePath) {
    self.wrappedValue = wrappedValue
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let string = try container.decode(String.self)
    self.wrappedValue = FilePath(string)
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(wrappedValue.string)
  }
  
  var filepath: FilePath {
    self.wrappedValue
  }
  
  var string: String {
    self.wrappedValue.string
  }
}


extension CodableFilePath: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
  init(stringLiteral value: String) {
    self.wrappedValue = FilePath(value)
  }
}


extension CodableFilePath: RawRepresentable {
  var rawValue: FilePath {
    self.wrappedValue
  }
  
  init?(rawValue: FilePath) {
    self.wrappedValue = rawValue
  }
}


extension CodableFilePath: Equatable {
  static func == (lhs: CodableFilePath, rhs: CodableFilePath) -> Bool {
    lhs.wrappedValue == rhs.wrappedValue
  }
}


extension CodableFilePath: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(self.wrappedValue)
  }
}
