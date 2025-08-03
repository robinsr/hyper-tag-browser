// created on 11/21/24 by robinsr

import SwiftUI


struct AddToQueueMenu: View {
  @Environment(AppViewModel.self) var appVM
  
  let queues: [QueueRecord]
  let items: [ContentItem]
  let onSelection: DispatchFn
  
  var body: some View {
    Menu("Add to Queue") {
      ForEach(queues, id: \.id) { queue in
        Button(queue.name) {
          onSelection(.enqueueItems(items.pointers, into: queue.asFilter))
        }
      }
    }
  }
}
