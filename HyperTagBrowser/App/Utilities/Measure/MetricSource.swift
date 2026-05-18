// created on 11/24/25 by robinsr

import Foundation

struct MetricSource: Hashable, Encodable {
  let location: CodeLocation
  var tags: [String] = []
  
  init(_ file: String = #file, _ function: String = #function) {
    self.location = CodeLocation(file, function, separator: "_")
  }
  
  private init(_ file: String, _ function: String, _ tags: [String]) {
    self.location = CodeLocation(file, function, separator: "_")
    self.tags = tags
  }
  
  private var tagString: String {
    tags.joined(separator: ".")
  }
  
  private var metricBase: String {
    location.label
  }
  
  var name: String {
    if tagString.isEmpty { return metricBase }
    return "\(metricBase).\(tagString)"
  }
  
  /**
   * Returns a refined ``MetricSource`` with the tag value appended. Eg:
   *
   * ```swift
   * let metric = MetricSource("File", "exec").tagged("debug")
   * let case1 = metric.tagged("case1").name // produces `File_exec.debug.case1`
   * let case2 = metric.tagged("case2").name // produces `File_exec.debug.case2`
   * ```
   */
  func tagged(_ tagname: String) -> Self {
    MetricSource(location.filename, location.function, self.tags.appending(tagname))
  }
}


extension MetricSource: CustomStringConvertible {
  var description: String {
    JSONEncoder.compact(self)
  }
}
