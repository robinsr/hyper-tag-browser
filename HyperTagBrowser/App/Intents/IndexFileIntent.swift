// created on 1/20/25 by robinsr

import Foundation
import AppIntents
import Factory


struct IndexFileIntent: AppIntent {
  static var title: LocalizedStringResource = "Add file to index"
  static var description = IntentDescription("Adds a file to the file-tracking index using the default profile")
  
  @Parameter(title: "File")
  var fileURL: URL
  
  static var parameterSummary: some ParameterSummary {
    Summary("Add \(\.$fileURL) to the index")
  }
  
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
    let indexer = IndexerContainer.shared.indexService()
    let newIndex = try indexer.createIndex(for: fileURL.filepath)
    
    return .result(
      value: newIndex.id.value,
      dialog: "Success! \(fileURL.lastPathComponent) has been added to the index."
    )
  }
}
