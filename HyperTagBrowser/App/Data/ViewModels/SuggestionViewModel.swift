// created on 11/29/25 by robinsr

import DebouncedOnChange
import Factory
import SwiftUI

@MainActor
@Observable
final class SuggestionViewModel {
  
  typealias Suggestion = CountedTagRecord
  
  private var logger = EnvContainer.shared.logger("SuggestionViewModel")
  private let dbReader = IndexerContainer.shared.dbReader()
  
  private(set) var results: [Suggestion] = []
  
  var searchText: String = ""
  var tagDomains: [FilteringTag.TagDomain] = [.attribution, .descriptive]
  var excludedTags: [FilteringTag] = []
  var excludedContentIds: [ContentId] = []
  var itemLimit: Int = 10
  
  var tagQueryParmaters: TagQueryParameters {
    .init(
      query: searchText,
      domains: tagDomains,
      excludingTags: excludedTags,
      excludingContent: excludedContentIds,
      itemLimit: itemLimit
    )
  }
  
  var items: [Suggestion] {
    self.results
  }
  
  var isEmpty: Bool {
    self.results.isEmpty
  }
  
  var indexed: [(Int, Suggestion)] {
    self.results.enumerated().map { ($0, $1) }
  }
  
  private var searchTask: Task<Void, Never>?
  
  /// This is your "heavy" work. It should NOT touch UI.
  private func queryCountedTagRecord(for query: TagQueryParameters) async -> [CountedTagRecord] {
    do {
      let results = try await dbReader.read { db in
        try CountedTagRecord.query(matching: query).fetchAll(db)
      }
      
      logger.emit(.info, "CountedTagRecord.query: \("result", qty: results.count) for query \(query.queryText.quoted)")
      
      return results
    } catch {
      logger.emit(.error, ErrorMsg("CountedTagRecord.query failed", error))
      return []
    }
  }

  func userDidChangeQuery() {
    // Cancel any in-flight search
    searchTask?.cancel()

    // Clear suggestions for empty query
    guard !tagQueryParmaters.isEmpty else {
      results = []
      return
    }

    // Kick off new search OFF the main actor
    searchTask = Task.detached(priority: .userInitiated) { [self, query = tagQueryParmaters] in
      // Debounce slightly so we don't search on every single keystroke
      try? await Task.sleep(nanoseconds: 200_000_000) // 200ms

      // Check for cancellation before doing work
      guard !Task.isCancelled else { return }

      // Do the expensive work in this detached task
      let results = await queryCountedTagRecord(for: query)

      // Hop back to the main actor to publish results
      await MainActor.run {
        // Double-check we haven't been cancelled while we were searching
        guard !Task.isCancelled else { return }
        // (Optional) Verify we're still showing results for the same query
        // before applying them.
        self.results = results
      }
    }
  }
}
