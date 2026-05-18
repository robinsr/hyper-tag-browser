// created on 12/25/24 by robinsr

import Combine
import CoreSpotlight
import CustomDump
import Factory
import CoreFoundation
import CoreServices
import Foundation
import UniformTypeIdentifiers


actor SpotlightSearchService {
  
  public enum SearchError: Error, Sendable {
    case failed(underlying: Error)
    case unsupportedMethod(message: String)
  }
  
  private let logger = CustomLogger("SpotlightService", level: .off)
  
  private let indexName: String
  private let domainId: String
  private let profileId: ActiveUserProfile.ID
  
  /**
   * STATE!!!
   *
   * Stateful `CSSearchQuery` is necessary for two reasons:
   *
   * 1. Cancellation: when a new search starts, need to cancel the old one.
   * 2. Managing Lifetime: CSSearchQuery uses callbacks; must keep a reference and be able to stop it.
   */
  // private var currentQuery: CSSearchQuery?
  
  // Store only a cancellation hook inside the actor.
  nonisolated(unsafe) private var cancelCurrentQuery: (() -> Void)?
  
  init(indexName: String, domainId: String, profileId: ActiveUserProfile.ID) {
    self.indexName = indexName
    self.domainId = domainId
    self.profileId = profileId
  }
  
  nonisolated private func getSecureIndex() -> CSSearchableIndex {
    if self.indexName == "defaullt" {
      return CSSearchableIndex.default()
    } else {
      return CSSearchableIndex(name: self.indexName, protectionClass: FileProtectionType.none)
    }
  }
  
  public func cancel() {
    cancelCurrentQuery?()
    cancelCurrentQuery = nil
  }
  
  nonisolated public func search(method: SearchMethod, query: SearchQuery) async throws -> [SpotlightResult] {
    // Cancel any in-flight search
    await self.cancel()
    
    let csQuery = switch method {
    case .searchQuery:
      query.csSearchQuery
    case .userSearch:
      query.csUserQuery
    case .userQuery:
      query.csUserQuery
    case .databaseQuery:
      throw SearchError.unsupportedMethod(message: "Search method \(method) not compatible with spotlight search")
    }

    cancelCurrentQuery = { csQuery.cancel() }

    var results: [SpotlightResult] = []
    results.reserveCapacity(min(query.maxResults, 64))

    // Bridge callback API to async/await
    return try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { cont in
        csQuery.foundItemsHandler = { items in
          // Called repeatedly
          for item in items {
            results.append(SpotlightResult(item))
            if results.count >= query.maxResults {
              csQuery.cancel()
              break
            }
          }
        }

        csQuery.completionHandler = { error in
          // Ensure we're completing for the active query
          Task { await self.cancel() }

          if let error {
            cont.resume(throwing: SearchError.failed(underlying: error))
          } else {
            cont.resume(returning: results)
          }
        }

        csQuery.start()
      }
    } onCancel: {
      Task { await self.cancel() }
    }
  }

  
  nonisolated func indexItems(_ items: [ContentItem]) async throws {
    let itemsToIndex = items.map { $0.asSearchableItem(in: self.domainId) }
    let itemIds = items.identifiers
    
    // Used for resuming from a crash; not currently used
    let clientData = Data()
    
    guard CSSearchableIndex.isIndexingAvailable() else {
      logger.emit(.error, "Indexing not available")
      return
    }
    
    let secureIndex = getSecureIndex()
    
    do {
      secureIndex.beginBatch()
      try await secureIndex.indexSearchableItems(itemsToIndex)
      try await secureIndex.endBatch(withClientState: clientData)
      
      logger.emit(
        .info,
        """
        Updated index '\(self.indexName)' with items:
        
        \(itemIds.map(\.value).joined(separator: "\n"))
        """)
    } catch {
      let clientDataString = String(data: clientData, encoding: .utf8) ?? "nil"
      
      self.logger.emit(.error, ErrorMsg("Error indexing items", error))
      self.logger.emit(.debug, "Client data: \(clientDataString)")
    }
  }
  
  nonisolated func deleteItem(_ identifier: String) async throws {
    try await getSecureIndex().deleteSearchableItems(withIdentifiers: [identifier])
  }
  
  func deleteItems(_ contentIds: [ContentId]) async throws {
    try await getSecureIndex().deleteSearchableItems(withIdentifiers: contentIds.map(\.value))
  }
  
  func deleteAllItems() async throws {
    try await getSecureIndex().deleteAllSearchableItems()
  }

  func deleteAllitems(inDomain domainIdentifier: String) async throws {
    try await getSecureIndex().deleteSearchableItems(withDomainIdentifiers: [domainIdentifier])
  }
}
