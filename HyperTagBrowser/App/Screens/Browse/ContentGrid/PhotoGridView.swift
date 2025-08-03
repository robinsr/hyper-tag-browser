// created on 9/2/24 by robinsr

import Defaults
import Factory
import SwiftUI
import SwiftUIIntrospect


struct PhotoGridView: View {
  private let logger = EnvContainer.shared.logger("PhotoGridView")
  
  typealias ContentItem = IndexInfoRecord
  
  @Injected(\Container.executor) var exec
  
  @Environment(\.dispatcher) var dispatch
  @Environment(\.pushState) var navigate
  @Environment(\.cursorState) var cursor
  @Environment(\.modifierKeys) var modState
  @Environment(\.route) var route
  
  @Environment(\.dbContentItemsVisible) var items: [IndexInfoRecord]
  
  
  /// Defines the smallest square size a grid item can be. This value is the only one intended to be user-adjustable
  /// This view uses `adaptive` columns, which "prefers to insert as many items of the minimum size", so this value
  /// really determines how many items will be displayed per row. A variable maximum doesn't work because the grid
  /// will always just use the minimum size regardless of the maximum.
  @Default(.gridTileSize) var gridItemMinSize
  
  /// Defines additional *horizontal* space between items in a row. This value is Zero by default meaning a grid items'
  /// container is directly touching it's neighbors. When the grid item is `active` or `dimmed`, the resulting border
  /// drawn will also have no space between itself and it's neighbors border, which looks a bit awkward.
  @Default(.photoGridHSpace) var gridItemSpacing
  
  /// Defines the same as `gridItemSpacing` but for the vertical space between rows. These can be different, but doing
  /// so will make the grid appear to have non-square items. Ideally these will be refactored to be one value.
  @Default(.photoGridVSpace) var gridRowSpacing
  
  @Default(.showTagCountOnTiles) var showTagCount
  
  //@State var gridItemHovered: ContentIdFocusable = .unset
  
  @State var showGridSheet = false
  
  @State var gridState = PhotoGridState()
  
  @State var gridRect: CGRect = .zero
  @State var itemRects: [CGRect]
  
  
  /// While `CursorState` manages the more advanced cursor interactions, this state
  /// is necessary for the keyboard events to work. Without giving the grid tiles
  /// a focus state, the keyevents have no view to originate from.
  // @FocusState var focusedItem: ContentIdFocusable?
  
  
  init() {
    let maxItems: Int = UserSelectPrefs<Int>.photoGridItemLimit.options.max() ?? 1000
    
    self.itemRects = Array<CGRect>(repeating: CGRect(), count: maxItems)
  }
  
  func onItemFirstTap(_ item: ContentItem) {
    cursor.dispatch(.tap(item, mods: modState.eventModifiers), from: .folder)
  }
  
  func onItemSecondTap(_ item: ContentItem) {
    if modState.eventModifiers.none {
      navigate(item.link)
    } else {
      cursor.dispatch(.tap(item, mods: modState.eventModifiers), from: .folder)
    }
  }
  
  func onItemAltTap(_ item: ContentItem) {
    cursor.dispatch(.tap(item, mods: .control), from: .folder)
  }
  
  func onGridGeometryChange()  {
    guard let itemWidth = itemRects.first?.width else {
      logger.emit(.warning, "No measurable rects found in grid")
      return
    }
    
    guard itemWidth > 0 else {
      logger.emit(.warning, "Grid item width computed as zero, cannot update grid state")
      return
    }

    gridState.gridWidth = gridRect.width
    gridState.itemWidth = itemWidth
    cursor.verticalDistance = Int(gridState.gridWidth/gridState.itemWidth)
  }
  
  
  
  var body: some View {
    ScrollViewReader { proxy in
      ZStack(alignment: .topTrailing) {
        OverlayVerticalScrollView {
          VStack(spacing: 0) {
            LazyGridContent
              .padding(.horizontal, gridItemSpacing)
              .frame(maxWidth: .infinity)
              .contextMenu {
                GridContextMenu
              }
              .onPreferenceChange(GridItemGeometryPreferenceKey.self) { prefs in
                for pref in prefs {
                  
                  // Prevents out-of-range error when the number of grid items configured to
                  // show changes (eg on user preference chagne)
                  if self.itemRects.count > pref.viewIdx {
                    self.itemRects[pref.viewIdx] = pref.rect
                  }
                }
              }
            
            ErrorCallouts()
          }
          .coordinateSpace(name: "photoGridZstack")
          .background(GridGeometrySetter)
        }
        
        ShowAdjustmentsBtn
          .debugVisible(flag: .views_debug)
      }
      .onChange(of: cursor.position) {
        proxy.scrollTo(cursor.cursorItem?.id.value)
      }
    }
    .onChange(of: items, initial: true) {
      cursor.items = items
    }
    .onChange(of: route) { prevRoute, nextRoute in
      if prevRoute.page == .folder && nextRoute.page == .folder {
        cursor.clearAndReset()
      }
    }
    .onChange(of: gridRect, debounceTime: .milliseconds(50)) {
      onGridGeometryChange()
    }
    .onChange(of: itemRects, debounceTime: .milliseconds(50)) {
      onGridGeometryChange()
    }
    .buttonShortcut(binding: .onEnter) {
      if let item = cursor.anyOneSelected {
        navigate(item.link)
      }
    }
    .buttonShortcut(binding: .info) {
      if let item = cursor.anyOneSelected {
        dispatch(.showSheet(.contentDetailSheet(item: item)))
      }
    }
    .buttonShortcut(binding: .editTags, action: exec.edit_EditTagsButton)
    .environment(\.photoGridState, gridState)
  }
  
  var adaptiveCols: [GridItem] {
    let size: GridItem.Size = .adaptive(minimum: CGFloat(gridItemMinSize), maximum: Constants.maxTileSize)
    let align: Alignment = .center
    
    return Array(repeating: .init(size, spacing: gridItemSpacing, alignment: align), count: 1)
  }

  var LazyGridContent: some View {
    LazyVGrid(columns: adaptiveCols, alignment: .center, spacing: gridRowSpacing) {
      ForEach(items.indexed, id: \.1.id) { index, item in
        PhotoGridItem(item: item, index: index)
          .background(GridItemGeometryPreferenceViewSetter(idx: index))
          .id(item.id.value)
      }
    }
  }
  
  
  func PhotoGridItem(item: ContentItem, index: Int) -> some View {
    SelectableItemView(
      itemState: cursor.focusState(of: item.pointer),
      insetAmount: 0,
      onTap: { interaction, mods in
        switch interaction {
        case .select:
          onItemFirstTap(item)
        case .isSelected:
          onItemSecondTap(item)
        default:
          break;
        }
      }) { state in
        GridItemView(item: item, index: index, state: state)
          .padding(9)
          .background(state.colors.fill)
          .border(state.colors.stroke, width: 8, cornerRadius: gridState.itemWidth / 24)
      }
  }

  func GridItemView(item: ContentItem, index: Int, state: SelectionItem.State) -> some View {
    ThumbnailView(content: item, tileSize: CGSize(gridItemMinSize))
      .overlay {
        
        if showTagCount && item.conforms(to: .content) {
          TagCountOverlay(item.tags.count)
        }
        
        if cursor.manySelected && cursor.contains(item) {
          SelectedOverlay
        }
        
        if item.index.visibility == .hidden {
          ItemVisibilityOverlay
        }
      }
    
        /// For non-folder types, enable Tag drops
      .modify(when: item.diverges(from: .folder)) {
        $0.acceptsTagDrops(addTo: item)
      }
    
        /// For folder types, enable content item drops
      .modify(when: item.conforms(to: .folder)) {
        $0.acceptsContentDrops(moveItemTo: item)
      }
    
        /// For content items, enable single-file, file-to-folder transfers
      .modify(when: item.conforms(to: .content) && cursor.noneSelected) {
        $0.draggable(ContentPointers([item.pointer])) {
          ContentDragPreview(items: [item])
        }
      }
    
        /// When dragging an item not in the selection, allow dragging it as a single item
      .modify(when: item.conforms(to: .content) && cursor.anySelected && !cursor.contains(item)) {
        $0.draggable(ContentPointers([item.pointer])) {
          ContentDragPreview(items: [item])
        }
      }
    
        /// For content items, enable cursor-based file-to-folder transfers
      .modify(when: item.conforms(to: .content) && cursor.anySelected && cursor.contains(item)) {
        $0.draggable(cursor.transferable) {
          ContentDragPreview(items: cursor.selection)
            
        }
      }
  }
  
  func TagCountOverlay(_ count: Int) -> some View {
    GridItemThumbnailOverlayView(icon: .tag, label: "\(count)", alignment: .bottomLeading)
      .fontWeight(.medium)
  }
  
  var SelectedOverlay: some View {
    GridItemThumbnailOverlayView(icon: .itemChecked, alignment: .bottomTrailing)
      .fontWeight(.bold)
      .foregroundStyle(.blue)
  }
  
  var ItemVisibilityOverlay: some View {
    GridItemThumbnailOverlayView(icon: .eyeslash, alignment: .topTrailing)
      .foregroundStyle(.red)
  }
  
  var ThumbnailIndicatorOverlay: some View {
    GridItemThumbnailOverlayView(icon: .camera, alignment: .topLeading)
      .fontWeight(.medium)
  }
  
  
  
  @ViewBuilder
  var GridContextMenu: some View {
    if cursor.manySelected {
      MultiSelectContextMenu(onSelection: dispatch)
    }
    
    if cursor.oneSelected {
      if let item = items[safe: cursor.position] {
        ContentItemContextMenu(contentItem: item, onSelection: dispatch)
      }
    }
  }
  
  var GridGeometrySetter: some View {
    GeometryReader { geometry in
      Rectangle()
        .fill(Color.clear)
        .onChange(of: geometry.size) {
          gridRect = geometry.frame(in: .named("photoGridZstack"))
        }
    }
  }
  
  var ShowAdjustmentsBtn: some View {
    Button("Show Grid Sheet", .gear) {
      showGridSheet.toggle()
    }
    .sheetView(isPresented: $showGridSheet, style: GridSpacingControls.presentation) {
      GridSpacingControls()
    }
  }
}



struct GridItemGeometryPreferenceKey: PreferenceKey {
  struct Data: Equatable {
    let viewIdx: Int
    let rect: CGRect
  }
  
  typealias Value = [Data]

  static var defaultValue: Value = []
    
  static func reduce(value: inout Value, nextValue: () -> Value) {
    value.append(contentsOf: nextValue())
  }
}


struct GridItemGeometryPreferenceViewSetter: View {
  let idx: Int
    
  var body: some View {
    GeometryReader { geometry in
      Rectangle()
        .fill(Color.clear)
        .preference(key: GridItemGeometryPreferenceKey.self, value: [
          .init(viewIdx: self.idx, rect: geometry.frame(in: .named("photoGridZstack")))
        ])
    }
  }
}
