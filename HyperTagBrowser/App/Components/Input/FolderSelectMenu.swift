// created on 2/7/25 by robinsr

import Factory
import Foundation
import SwiftUI
import UniformTypeIdentifiers


struct FolderSelectMenu<Content: View>: View {
  typealias SelectionItems = [LocationGroup]
  
  var title: String? = nil
  var data: SelectionItems
  var onOther: (() -> Void)?
  var onURL: (URL) -> Void
  var label: (() -> (Content))? = nil
  
  init(
    _ title: String,
    data: SelectionItems,
    onOther: (() -> Void)? = nil,
    onURL: @escaping (URL) -> Void
  ) {
    self.title = title
    self.data = data
    self.onOther = onOther
    self.onURL = onURL
  }
  
  init(
    data: SelectionItems,
    onOther: (() -> Void)? = nil,
    onURL: @escaping (URL) -> Void,
    label: @escaping () -> (Content)
  ) {
    self.data = data
    self.onOther = onOther
    self.onURL = onURL
    self.label = label
  }
  
  var body: some View {
    Menu {
      DividedForEach(data, id: \.id) { group in
        Group {
          ContextMenuTextItem(group.name)
          
          ForEach(group.items, id: \.id) { item in
            ContextMenuButton("\(homeURL: item.url)") {
              onURL(item.url)
            }
          }
        }
      }
      
      Group {
        Divider()
        ContextMenuButton("Choose Folder") {
          onOther?()
        }
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
}
