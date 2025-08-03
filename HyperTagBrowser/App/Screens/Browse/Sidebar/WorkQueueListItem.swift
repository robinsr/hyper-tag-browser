// created on 4/23/25 by robinsr

import SwiftUI


struct WorkQueueListItem: View {
  @Environment(\.dispatcher) var dispatch
  @Environment(\.pushState) var navigate
  
  let record: QueueIndexesRecord
  
  init(_ record: QueueIndexesRecord) {
    self.record = record
  }
  
  var body: some View {
    SectionView(.closed) {
      ForEach(record.indexes, id: \.id) { index in
        QueueListItem(index)
      }
    } label: {
      FullWidthSplit {
        VStack(alignment: .leading) {
          Text(record.queue.name)
            .styleClass(.sectionLabel)
          
          DateView(date: record.queue.created)
            .styleClass(.listItemSubtitle)
        }
      } trailing: {
        Button("Show items", .linkTo) {
          dispatch(.addFilter(.queue(record.queue.name), .inclusive))
        }
        .buttonStyle(.accessoryBarAction)
      }
    }
    .id(record.queue.id)
  }
  
  func QueueListItem(_ index: IndexRecord) -> some View {
    HStack {
      Button {
        navigate(.content(index.pointer))
      } label: {
        Text(index.name)
          .lineLimit(1)
          .truncationMode(.middle)
          .styleClass(.listItem)
      }
      .buttonStyle(.weblink)
    }
    .fillFrame(.horizontal, alignment: .leading)
  }
}
