// created on 9/15/24 by robinsr

import AppKit


struct ClipboardService {
  static let shared = ClipboardService()
  
  public func write(text: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
  }
  
  public func write(data: Data) {
    let text = JSONEncoder.pretty(data, omitData: false)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
  }
  
  public func readString() -> String? {
    return NSPasteboard.general.string(forType: .string)
  }
}
