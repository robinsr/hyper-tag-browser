// created on 10/21/24 by robinsr

import SwiftUI


struct ReplaceContentDropArea: View {
  @Environment(AppViewModel.self) var appVM
  
  @Environment(\.dispatcher) var dispatch
  @Environment(\.detailEnv) var detailEnv
  @Environment(\.notify) var notify
  
  @State var showConfirmation = false
  @State var showFileImporter = false
  @State var isDropTargeted = false
  @State var droppedItemURL: URL?
  @State var targetImgURL: URL?
  
  var fileImporterConfig: FileImporterConfiguration {
    .init(folder: appVM.location, allow: [.image], onChoice: onURLsDropped)
  }
  
  func onURLsDropped(_ urls: [URL]) {
    guard let url = urls.first else { return }
    
    if url.contentType.conforms(to: .image) == false {
      notify(.error("File type \(url.contentType) not supported"))
      return
    }
    
    droppedItemURL = url
  }
  
  func onReplaceConfirmed() {
    guard let url = droppedItemURL else { return }
    guard let content = detailEnv.contentItem else { return }
    
    dispatch(.replaceContents(of: content.pointer, with: url))
    
    // TODO: probably need to refresh somewhow
    
    droppedItemURL = nil
  }
  
  
  func onCancel() {
    droppedItemURL = nil
  }
  
  var replaceURLPresented: Bool {
    droppedItemURL != nil
  }
  
  var body: some View {
    VStack {
      ImagePlaceholder(inset: 12) {
        DropAreaContent
      }
      .background(
        DropZoneView(isActive: $isDropTargeted)
      )
      .fillFrame(.horizontal)
      .aspectRatio(1, contentMode: .fit)
      .frame(maxWidth: 200)
      .acceptsURLDrops(action: onURLsDropped) { overTarget in
        isDropTargeted = overTarget
      }
    }
    .sheetView(
      isPresented: .notNil($droppedItemURL).onChange { _ in onCancel() },
      style: ImageDiffSheetView.presentation) {
        InnerSheetContent
    }
  }
  
  var InnerSheetContent: some View {
    ImageDiffSheetView(
      lhs: $targetImgURL.withDefault(Constants.emptyImageURL).wrappedValue,
      rhs: $droppedItemURL.withDefault(Constants.emptyImageURL).wrappedValue,
      onCancel: onCancel,
      onConfirm: onReplaceConfirmed
    )
    .scaledToFit()
  }
  
  var DropAreaContent: some View {
    VStack {
      Text("Drag an image here")
        .styleClass(.body)
        .padding(.horizontal, 20)
        .multilineTextAlignment(.center)
        
      Divider()
        .padding(.horizontal, 40)
      
      Button("Choose Image", .photos) {
        showFileImporter.toggle()
      }
      .fileImporter(
        configuration: fileImporterConfig,
        isPresented: $showFileImporter
      )
    }
    .opacity(0.7)
    .buttonStyle(.plain)
  }
}
