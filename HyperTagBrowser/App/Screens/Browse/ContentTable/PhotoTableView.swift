// created on 10/21/24 by robinsr

import SwiftUI


struct PhotoTableView: View {
  @Environment(\.dispatcher) var dispatch
  @Environment(\.pushState) var navigate
  
  @Environment(\.dbContentItemsVisible) var items: [IndexInfoRecord]
  
  var contentItems: [ContentItem] {
    items.filter { $0.index.type.conforms(to: .content) }
  }
  
  var body: some View {
    Table(of: ContentItem.self) {
      TableColumn("") { (item: ContentItem) in
        Button {
          navigate(item.link)
        } label: {
          Image(.linkTo)
            .frame(width: 30, height: 30)
        }
        .buttonStyle(.weblink)
      }
      .width(30)
      
      TableColumn("Filename") { item in
        Text(item.name)
      }
      .width(min: 100, ideal: 400)
      
      TableColumn("Folder") { item in
        Button {
          navigate(.folder(item.location))
        } label: {
          Text(item.location.baseName)
        }
        .buttonStyle(.weblink)
      }
      .width(min: 50, ideal: 150)
      
      TableColumn("Created") { item in
        DateView(date: item.index.created)
      }
      .width(min: 100, ideal: 150)
      
      TableColumn("Tags") { item in
        HorizontalFlowView {
          ForEach(item.tags.uniqued(by: \.id), id: \.self) { tag in
            Button {
              dispatch(.addFilter(tag, .inclusive))
            } label: {
              Text(tag.value)
            }
            .buttonStyle(.weblink)
            .id(tag.id)
          }
        }
        .truncationMode(.tail)
      }
      .width(min: 300, ideal: 400)
    } rows: {
      ForEach(contentItems, id: \.id) { item in
        TableRow(item)
          .contextMenu {
            ContentItemContextMenu(contentItem: item, onSelection: dispatch)
          }
      }
    }
    .colorScheme(.dark)
  }
}
