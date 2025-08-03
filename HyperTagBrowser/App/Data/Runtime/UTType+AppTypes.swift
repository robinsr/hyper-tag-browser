// created on 3/19/25 by robinsr

import UniformTypeIdentifiers

extension UTType {
  
  static var contentItem: UTType {
    UTType(exportedAs: "com.taggedfilebrowser.content-item", conformingTo: .json)
  }
  
  static var filteringTag: UTType {
    UTType(exportedAs: "com.taggedfilebrowser.filteringtag", conformingTo: .json)
  }
  
  static var contentPointer: UTType {
    UTType(exportedAs: "com.taggedfilebrowser.contentpointer", conformingTo: .json)
  }
  
  static var sqlite: UTType {
    UTType(exportedAs: "public.sqlite")
  }
  
  public static var sqlite3: UTType {
    UTType(mimeType: "application/vnd.sqlite3")!
  }
  
  public var isAnimated: Bool {
    self.oneOf(.gif, .webP)
  }
}

