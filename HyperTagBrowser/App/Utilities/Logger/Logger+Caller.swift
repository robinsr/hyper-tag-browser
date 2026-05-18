// created on 11/24/25 by robinsr

import OSLog
import System


extension Logger {
  func callerInfo(_ file: String, _ line: Int, _ function: String) -> CodeLocation {
    CodeLocation(file, function, line, separator: "#")
  }
}
