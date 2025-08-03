// created on 5/9/25 by robinsr

import GRDBQuery
import SwiftUI


struct DatabaseContextPreviewMod: PreviewModifier {
  typealias Context = DatabaseContext
  
  static func makeSharedContext() async throws -> Context {
    let logger = EnvContainer.shared.logger("DatabaseContextPreviewMod")
    let indexer = IndexerContainer.shared.indexService()
    
    do {
      try indexer.runMigrations()
    } catch {
      print("Error in DatabaseContextPreviewMod: \(error)")
    }
    
    return .readOnly { indexer.dbReader }
  }

  func body(content: Content, context: Context) -> some View {
    content
      .databaseContext(context)
  }
}

extension PreviewTrait where T == Preview.ViewTraits {
  @MainActor static var databaseContext: Self = .modifier(DatabaseContextPreviewMod())
}
