// created on 2/7/25 by robinsr

import Factory
import Foundation
import SwiftUI
import UniformTypeIdentifiers


struct FolderSelectMenu<Content: View>: View {
  typealias Items = [LocationGroup]
  
  var title: String? = nil
  var data: [LocationGroup]
  var onOther: (() -> Void)?
  var onURL: (URL) -> Void
  var label: (() -> (Content))? = nil
  
  init(_ title: String, data: Items, onOther: (() -> Void)? = nil, onURL: @escaping (URL) -> Void) {
    self.title = title
    self.data = data
    self.onOther = onOther
    self.onURL = onURL
  }
  
  init(data: Items, onOther: (() -> Void)? = nil, onURL: @escaping (URL) -> Void, label: @escaping () -> (Content)) {
    self.data = data
    self.onOther = onOther
    self.onURL = onURL
    self.label = label
  }
  
  var body: some View {
    Menu {
      DividedForEach(data, id: \.id) { group in
        Group {
          ButtonGroupTitle(group.name)
          
          ForEach(group.items, id: \.id) { item in
            Button("\(item.url.filepath)") {
              onURL(item.url)
            }
          }
        }
      }
      
      Button("Choose Folder") {
        onOther?()
      }
      .hidden(onOther == nil)
    } label: {
      if let labelContent = label {
        labelContent()
      } else {
        Text(title ?? "Select Folder")
          .styleClass(.controlLabel)
      }
    }
  }
  
  func ButtonGroupTitle(_ title: String) -> some View {
    Button {
      // no-op
    } label: {
      Text(verbatim: title.uppercased())
        .font(.caption)
    }
    .disabled(true)
  }
}


struct LocationGroup: Identifiable, Hashable {
  var id: UUID = UUID()
  var name: String
  var items: [IdentifiedURL]
  
  init(name: String, urls: [URL]) {
    self.name = name
    self.items = urls.map { IdentifiedURL(url: $0) }
  }
  
  struct IdentifiedURL: Identifiable, Hashable {
    var id: UUID = UUID()
    var url: URL
  }
  
  private static var fs = Container.shared.fileService()
  
  static func named(_ name: String, _ urls: [URL]) -> Self {
    LocationGroup(name: name, urls: urls)
  }
  
  static func named(_ name: String, _ url: URL) -> Self {
    LocationGroup(name: name, urls: [url])
  }
  
  static func parent(of url: URL) -> Self {
    LocationGroup(name: "Parent Folder", urls: [url.deletingLastPathComponent()])
  }
  
  static func contents(of url: URL) -> Self {
    LocationGroup(name: "Subfolders", urls: fs.subfolders(of: url))
  }
  
  static func adjacent(to url: URL) -> Self {
    LocationGroup(name: "Adjacent Folders", urls: fs.adjacent(to: url))
  }
}
