// created on 10/23/24 by robinsr

import SwiftUI
import GRDBQuery


struct WorkQueueSidebarMenu: View {
  @Environment(AppViewModel.self) var appVM
  
  @Environment(\.dispatcher) var dispatch
  @Environment(\.pushState) var navigate
  
  @Query(ListQueueIndexesRequest()) var dbQueues
  
  var body: some View {
    SectionView(isPresented: appVM.bindToPanel(.workqueues)) {
      ForEach(dbQueues, id: \.queue.id) { record in
        WorkQueueListItem(record)
      }
      .overlay {
        NoQueues
          .visible(dbQueues.isEmpty)
      }
    } label: {
     SectionLabel
    }
  }
  
  var SectionLabel: some View {
    FullWidthSplit {
      Text("Work Queues")
    } trailing: {
      CreateQueueButton
        .buttonStyle(.toolbarIcon)
    }
  }
  
  var NoQueues: some View {
    ContentUnavailableView {
      Label("No Queues", .queueAlt)
        .scaleEffect(0.7)
    } description: {
      Text(verbatim: "Queues you create will appear here.")
    }
  }
  
  var CreateQueueButton: some View {
    Button("Create a Queue", .newDoc) {
      dispatch(.showSheet(.createQueueSheet))
    }
  }
}
