// created on 6/6/25 by robinsr

import Regex
import SwiftUI
import System


struct SearchKnownFoldersView: View {
  
  @Environment(\.dbLocations) var knownFilePaths
  @Environment(\.directoryTree) var dirTree
  
  var maxSuggestionsCount = 5
  var suggestionSortKey: KeyPath<FilePath, String> = \.baseName
  
  private let fillBackgroundAnimation: Animation = .easeInOut(duration: 0.2)
  private let itemAppearTransition: AnyTransition = .fade(duration: 0.2)
  
  @State var searchText = TextFieldModel(validate: [.presence], updateInterval: .milliseconds(300))
  
  @State var suggestions: [FileTreeNode] = []
  
  var body: some View {
    VStack(alignment: .center, spacing: 12) {
      DirectorySearchTextField
        .frame(minWidth: 150, maxWidth: 280, alignment: .center)
      
      if suggestions.notEmpty {
        FolderSuggestions
          .transition(itemAppearTransition)
      }
    }
    .fillFrame(.horizontal)
    .padding(.vertical, 8)
    .padding(.horizontal, 12)
    .background {
      RoundedRectangle(cornerRadius: 8)
        .fill(suggestions.isEmpty ? .clear : .black.opacity(0.4))
        .animation(fillBackgroundAnimation, value: suggestions.isEmpty)
    }
    .onChange(of: searchText.value) {
      withAnimation {
        suggestions = getSuggestions()
      }
    }
  }
  
  var DirectorySearchTextField: some View {
    SearchField(value: $searchText.rawValue, placeholder: "Search")
      .textFieldStyle(.form(err: $searchText.error))
      .fillFrame(.horizontal)
      .controlSize(.extraLarge)
  }
  
  var FolderSuggestions: some View {
    VStack(alignment: .leading, spacing: 8) {
      
      Text("Folder Suggestions")
        .font(.caption)
        .padding(.leading, 8)
      
      VStack(alignment: .leading, spacing: 4) {
        ForEach(suggestions, id: \.id) { node in
          SidebarButton(
            isActive: .constant(dirTree.selection.contains(node.id)),
            onTapAction: {
              dirTree.toggleSuggestion(node)
            }) {
              FolderIndicator(name: node.displayName)
            }
        }
      }
      .padding(.bottom, 2)
    }
    .hidden(suggestions.isEmpty)
  }
  
  func getSuggestions() -> [FileTreeNode] {
    guard
      searchText.count >= 3,
      let pattern = try? Regex(string: searchText.value, options: .ignoreCase)
    else {
      return []
    }
    
    let matches = knownFilePaths
      .filter { pattern.matches($0.baseName) }
      .collect()
      .sorted(by: suggestionSortKey)
      .prefix(maxSuggestionsCount)
      .map { FileTreeNode(path: $0) }
    
    return matches
  }
}


#Preview("SearchKnownFoldersView", traits: .sizeThatFitsLayout, .testBordersOn) {
  @Previewable @State var dirTree = DirTreeModel(cwd: TestData.testImageDir)
  
  SearchKnownFoldersView()
    .withTestBorder(.orange.opacity(0.5))
    .environment(\.dbLocations, TestData.LOREM_WORDS.uniqued().map {
      TestData.projectDir.filepath.appending($0)
    })
    .environment(\.directoryTree, dirTree)
    .frame(width: 400, height: 600, alignment: .top)
    .padding()
    .preferredColorScheme(.dark)
}
