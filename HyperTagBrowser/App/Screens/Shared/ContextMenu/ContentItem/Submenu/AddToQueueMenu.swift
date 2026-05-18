// created on 11/21/24 by robinsr

import SwiftUI

struct AddToQueueMenu: View {
  @Environment(\.dbQueues) var queues
  
  let items: [ContentItem]
  let onSelection: DispatchFn
  
  var body: some View {
    Menu("Add to Queue") {
      ForEach(queues, id: \.id) { item in
        Button(item.queue.name) {
          onSelection(.enqueueItems(items.pointers, into: item.asFilter))
        }
      }
    }
  }
}
