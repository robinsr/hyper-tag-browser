// created on 10/18/24 by robinsr

import GRDBQuery
import SwiftUI

struct CurrentTagsView: View {
  
  typealias TagItem = IndexTagValueRecord

  @Environment(\.dispatcher) var dispatch

  @Binding var contentItem: ContentItem
  @Binding var domains: [FilteringTag.TagDomain]

  @Query(ListIndexTagsRequest()) var appliedTags: [TagItem]

  func onParametersChange() {
    $appliedTags.contentId.wrappedValue = $contentItem.wrappedValue.id
    $appliedTags.tagDomains.wrappedValue = $domains.wrappedValue
  }

  
  var body: some View {
    HorizontalFlowView(itemSpacing: 4, rowSpacing: 4) {
      ForEach(appliedTags, id: \.id) { tag in
        TagButton(
          for: tag.asFilter,
          config: tagButtonConfig
        )
          //.longPressTagAction(.renameAll, referencing: tag.asFilter)
      }
    }
    .onChange(of: contentItem) {
      onParametersChange()
    }
    .onChange(of: domains) {
      onParametersChange()
    }
    .onAppear {
      onParametersChange()
    }
  }

  var tagButtonConfig: TagButtonConfiguration {
    .init(
      size: .small,
      variant: .primary,
      contextMenuConfig: .whenAppliedAsContentTag(contentItem.pointer),
      contextMenuDispatch: { action in
        switch action {
          // By default, no tag context-menu actions really need to go back to
          // the browsescreen, except for the "Add Filter" action.
          case .addFilter:
            dispatch(action)
            dispatch(.popRoute)
          default:
            dispatch(action)
        }
      },
      longPressAction: .renameAll
    )
  }
}



#Preview(
  "CurrentTagsView", traits: .databaseContext, .defaultViewModel,
  .fixedLayout(width: 400, height: 600)
) {
  @Previewable @State var content = TestData.testContentItems
    .sorted(by: { $0.tagCount > $1.tagCount })
    .first!

  VStack {
    CurrentTagsView(
      contentItem: .constant(content),
      domains: .constant([.descriptive])
    )
  }
  .frame(width: 400, height: 600)
}
