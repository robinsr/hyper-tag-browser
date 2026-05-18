// created on 11/30/25 by robinsr

import Foundation
import System


/**
 * Provides a code location context for log messages, including caller's file path,
 * function name, and line number. Handles some formatting for display purposes.
 */
struct CodeLocation: Hashable, Encodable, CustomStringConvertible {
  private let fileString: String
  private let fnString: String
  private let fnLine: Int?
  private let separator: String
  
  init(_ file: String = #file, _ function: String = #function, _ line: Int? = nil, separator: String = ":") {
    self.fileString = file
    self.fnString = function
    self.fnLine = line
    self.separator = separator
  }
  
  var filepath: FilePath {
    FilePath(fileString)
  }
  
  var filename: String {
    filepath.baseName
  }
  
  var module: String {
    filepath.stem ?? String(filepath.baseName.prefix(while: { $0 != "." }))
  }
  
  var function: String {
    fnString.replacingOccurrences(of: Self.fnNamePattern, with: "")
  }
  
  var description: String {
    if let lineNumber = self.fnLine {
      return "\(module)\(separator)\(function):\(lineNumber)"
    } else {
      return "\(module)\(separator)\(function)"
    }
  }
  
  var label: String {
    self.description
  }
  
  /// Matches on just the name portion of the `#function` special literal
  private static var fnNamePattern: NSRegularExpression {
    try! NSRegularExpression(pattern: "\\(.*\\)", options: [])
  }
}


extension CodeLocation: CustomDebugStringConvertible {
  var debugDescription: String {
    """
    CodeLocation(
      fileString: \(fileString.quoted),
      fnString: \(fnString.quoted),
      fnLine: \(describing: fnLine ?? "nil"),
      filename: \(filename.quoted),
      module: \(module.quoted),
      function: \(function.quoted),
      label: \(label.quoted),
    )
    """
  }
}
