import OSLog
import AppKit

final class ClipboardService {
  static let shared = ClipboardService()
  
  public func write(text: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
  }
  
  public func readString() -> String? {
    return NSPasteboard.general.string(forType: .string)
  }
}
