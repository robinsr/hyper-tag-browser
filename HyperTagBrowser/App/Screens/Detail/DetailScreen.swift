// created on 9/7/24 by robinsr

import CustomDump
import Defaults
import Factory
import GRDBQuery
import OSLog
import SwiftUI
import UniformTypeIdentifiers


struct DetailScreen: View {
  let logger = EnvContainer.shared.logger("DetailScreen")
  
  @Injected(\Container.executor) var exec
  
  @Environment(\.enabledFlags) var devFlags
  @Environment(\.dispatcher) var dispatch
  @Environment(\.replaceState) var replace
  @Environment(\.windowSize) var windowSize
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.cursorState) var cursor
  @Environment(\.detailEnv) var detailEnv
  @Environment(\.colorModel) var bgColor
  
  @Default(.backgroundOpacity) var bgOpacity
  @Default(.inspectorPanels) var panelState
  
  @State var showOriginal: Bool = false
  @State var debugDomColorPopover = false
  @State var fetchColorTask: Task<Void, Never>? = nil
  
  let contentItem: IndexInfoRecord
  
  init(contentItem: IndexInfoRecord) {
    self.contentItem = contentItem
  }
  
  func onNewImage() {
    detailEnv.resetZoom()
    detailEnv.setViewSize(to: windowSize.size)
    detailEnv.setContentItem(to: contentItem)
    
    guard devFlags.contains(.enable_dominantColor) else { return }
    
    guard detailEnv.image != .empty else { return }
    
    fetchColorTask?.cancel()
    
    fetchColorTask = Task {
      if contentItem.conforms(to: .image) {
        bgColor.update(detailEnv.imagePrimarColors)
      } else {
        bgColor.update(.defaults)
      }
    }
  }
  
  var body: some View {
    ContentView
      .contextMenu {
        ContentItemContextMenu(contentItem: contentItem) { action in
          switch action {
          case .removeFilter(_):
            dispatch(action)
          default:
            dispatch(action)
            dispatch(.popRoute)
          }
        }
      }
      .inspector(isPresented: $panelState.contains(.container)) {
        ImageInspector()
          .fillFrame(.vertical, alignment: .top)
          .background(.regularMaterial)
          .inspectorColumnWidth(min: 300, ideal: 400, max: 600)
      }
      .toolbar {
        ToolbarItemGroup(placement: .navigation) {
          ViewThatFits {
            NavigationToolbarView(with: [.navigateBack, .text(contentItem.name)])
            NavigationToolbarView(with: [.navigateBack])
          }
        }
        
        ToolbarItemGroup(placement: .primaryAction) {
          Spacer()
          DetailScreenToolbarItems(content: contentItem)
        }
      }
      .withToolbarBackground(useTransparent: .readOnly(detailEnv.fillMode.usesTransparentToolbar))
      .onChange(of: contentItem, initial: true) {
        onNewImage()
      }
      .onChange(of: cursor.cursorItem) { oldItem, newItem in
        if let item = newItem {
          replace(item.link)
        }
      }
      .buttonShortcut(binding: .editTags, action: exec.edit_EditTagsButton)
      .buttonShortcut(binding: .relocateSelection, action: exec.edit_MoveItemButton)
      .buttonShortcut(binding: .renameItem, action: exec.edit_RenameItemButton)
      .buttonShortcut(binding: .selectAll, action: exec.edit_SelectAllItemsButton)
  }
  
  @ViewBuilder var ContentView: some View {
    VStack {
      if contentItem.conforms(to: .movie) {
        DetailScreenVideo(fileURL: .constant(contentItem.url))
      }
      
      else if contentItem.conforms(to: .image) {
        PanAndZoomView()
      }
      
      else {
        NonImageContent
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .modify(when: detailEnv.fillMode == .fill) { $0
      .ignoresSafeArea(.all, edges: .all)
    }
    .overlay {
      CarouselButton(direction: .backward) {
        cursor.dispatch(.leftArrow(mods: []), from: .content)
      }
      .fillFrame(alignment: .leading)
      .padding(.vertical, 200)
      
      ItemTitleOverlay
        .fillFrame([.horizontal, .vertical], alignment: .bottom)
      
      CarouselButton(direction: .forward) {
        cursor.dispatch(.rightArrow(mods: []), from: .content)
      }
      .fillFrame([.horizontal, .vertical], alignment: .trailing)
      .padding(.vertical, 200)
    }
  }
  
  var ItemTitleOverlay: some View {
    VStack {
      Text(contentItem.name)
        .styleClass(.contentTitle)
        .foregroundStyle(bgColor.color.foreground)
        .selectable()
    }
    .scenePadding(.all)
  }
  
  var NonImageContent: some View {
    Image(nsImage: NSWorkspace.shared.icon(for: contentItem.url.contentType))
      .resizable()
      .aspectRatio(1, contentMode: .fit)
      .scaleEffect(0.5)
      .onAppear {
        bgColor.reset()
      }
  }
}


#Preview("Wide Image Detail", traits: .defaultViewModel) {
  DetailScreen(
    contentItem: TestData.testContentItems[2]
  )
  .frame(preset: .wide.wider(by: 1.5))
  .environment(\.cursorState, CursorState())
  
}

#Preview("Tall Image Detail", traits: .defaultViewModel) {
  DetailScreen(
    contentItem: TestData.testContentItems[7]
  )
  .frame(preset: .sq200.taller(by: 2.0).scaled(by: 2.0))
  .environment(\.cursorState, CursorState())
}

#Preview("Icon File Detail", traits: .defaultViewModel) {
  DetailScreen(
    contentItem: TestData.testContentItems[1]
  )
  .frame(preset: .sq340.scaled(by: 2.0))
  .environment(\.cursorState, CursorState())
}
