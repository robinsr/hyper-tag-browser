// created on 4/30/25 by robinsr

import Factory
import SwiftUI


/**
 * A view that fetches the `IndexInfoRecord` for the given `ContentId` and displays it using the provided content closure.
 *
 * Usage:
 *
 * ```swift
 * WithIndexInfoView(contentId: someContentId) { indexInfo in
 *   Text("Content name: \(indexInfo.index.name)")
 * } notFound: {
 *   Text("No record found for id \(someContentId)")
 * }
 * ```
 */
struct WithIndexInfoView<Content: View, NotFoundContent: View>: View {
  @Injected(\IndexerContainer.indexService) var indexer
  
  let contentId: ContentId
  let content: (IndexInfoRecord) -> Content
  let notFoundContent: () -> NotFoundContent
  
  init(
    contentId: ContentId,
    @ViewBuilder content: @escaping (IndexInfoRecord) -> Content,
    @ViewBuilder notFound: @escaping () -> NotFoundContent = { EmptyView() }
  ) {
    self.contentId = contentId
    self.content = content
    self.notFoundContent = notFound
  }
  
  var body: some View {
    if let indexInfo = try? indexer.getIndexInfo(withId: contentId) {
      content(indexInfo)
    } else {
      notFoundContent()
    }
  }
}
