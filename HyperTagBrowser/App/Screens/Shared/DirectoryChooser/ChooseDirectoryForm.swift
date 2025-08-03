// created on 11/22/24 by robinsr

import Factory
import SwiftUI
import System


struct ChooseDirectoryForm: View, SheetPresentable {
  static let presentation: SheetPresentation = .modalTall(controls: .all)
  
  @Environment(\.notify) var notify
  @Environment(\.directoryTree) var dirTree
  @Environment(\.location) var location
  
  let title: String
  let confirmLabel: String
  let onSelection: (FilePath) -> ()
  let onCancel: () -> ()
  
  @State var showFileDialog = false
  @State var loading = false
  
  
  
  init(
    _ title: String? = nil,
    confirm: String? = nil,
    onSelection: @escaping (FilePath) -> Void,
    onCancel: @escaping () -> Void
  ) {
    self.confirmLabel = confirm ?? "Choose"
    self.onSelection = onSelection
    self.onCancel = onCancel
    
    self.title = title ?? "Choose Directory"
  }
  
  func onFileDialogResult(result: Result<[URL], Error>) {
    do {
      let folder = try result.get().first!
      onSelection(folder.filepath)
    } catch {
      notify(.error("Could not get folder", error))
    }
  }
  
  func onConfirm() {
    if let chosenURL = dirTree.selected?.url {
      onSelection(chosenURL.filepath)
    }
  }
  
  func moveUpDirectory(distance: Int = 1) {
    loading = true
    
    let dirToReopen = dirTree.cwd
    
    dirTree.upDir(distance: distance)
    dirTree.select(id: dirToReopen.string)
    dirTree.open(id: dirToReopen.string)
    
    loading = false
  }
  
  @State var navPath = NavigationPath()
  
  var body: some View {
    VStack {
      Text(title)
        .modalContentTitle()
      
      VStack(spacing: 12) {
        SearchKnownFoldersView()
          .withTestBorder(.yellow, "SearchKnownFolders")
        
        ParentPathMenu
          .padding(.horizontal, 24)
        
        TreeContents
          .fillFrame(.vertical, alignment: .top)
      }
      .modalContentMain()
      
      FooterControls
        .modalContentFooter()
    }
    .modalContentBody()
    .fileImporter(
      isPresented: $showFileDialog,
      allowedContentTypes: [.folder],
      allowsMultipleSelection: false,
      onCompletion: onFileDialogResult
    )
    .onAppear {
      dirTree.resetTo(cwd: location)
    }
  }
  
  var TreeContents: some View {
    ScrollView {
      DirectoryTreeOutlineView()
        .focusEffectDisabled()
    }
    .scrollIndicators(.hidden)
    .fillFrame(.vertical, alignment: .top)
    .padding(0)
  }
  
  var ParentPathMenu: some View {
    Menu {
      ForEach(dirTree.ancestorPath, id: \.1.url) { index, node in
        Button {
          moveUpDirectory(distance: index + 1)
        } label: {
          FolderIndicator(name: node.displayName)
        }
      }
    } label: {
      FolderIndicator(name: dirTree.baseName)
    }
    .menuStyle(.button)
    .buttonStyle(.bordered)
  }
  
  var FooterControls: some View {
    FullWidthSplit(alignment: .center, spacing: 8) {
      FormButton(.tertiary, "Choose Other") {
        showFileDialog = true
      }
    } trailing: {
      FormCancelButton(action: onCancel)
      FormConfirmButton(confirmLabel, action: onConfirm)
        .disabled(dirTree.selected == nil)
    }
  }
}


#Preview("ChooseDirectoryForm", traits: .fixedLayout(width: 400, height: 550), .testBordersOn) {
  VStack {
    ChooseDirectoryForm(
      onSelection: {
        print("Selected: \($0)")
      },
      onCancel: {
        print("Cancelled")
      }
    )
    .withTestBorder(.red, "ChooseDirectoryForm")
    .padding()
  }
  .environment(\.directoryTree, DirTreeModel(cwd: TestData.appDir))
  .environment(\.location, TestData.appDir)
}
