// created on 9/2/24 by robinsr

import Defaults
import Factory
import GRDBQuery
import SwiftUI
import SwiftUIIntrospect


struct PhotoGridView: View {
  private let logger = EnvContainer.shared.logger("PhotoGridView")
  
  @Injected(\Container.executor) var exec
  
  @Environment(\.dispatcher) var dispatch
  @Environment(\.pushState) var navigate
  @Environment(\.cursorState) var cursorState
  @Environment(\.modifierKeys) var modState
  @Environment(\.route) var currentRoute
  @Environment(\.dbContentItemsVisible) var items: [IndexInfoRecord]
  
  @Query(ListIndexTagCountRequest(contentIds: [])) var dbTagCounts
  
  
  /// Defines the smallest square size a grid item can be. This value is the only one intended to be user-adjustable
  /// This view uses `adaptive` columns, which "prefers to insert as many items of the minimum size", so this value
  /// really determines how many items will be displayed per row. A variable maximum doesn't work because the grid
  /// will always just use the minimum size regardless of the maximum.
  @Default(.gridTileSize) var gridItemMinSize
  
  /// Defines additional *horizontal* space between items in a row. This value is Zero by default meaning a grid items'
  /// container is directly touching it's neighbors. When the grid item is `active` or `dimmed`, the resulting border
  /// drawn will also have no space between itself and it's neighbors border, which looks a bit awkward.
  @Default(.photoGridHSpace) var photoGridHSpace
  
  /// Defines the same as `gridItemSpacing` but for the vertical space between rows. These can be different, but doing
  /// so will make the grid appear to have non-square items. Ideally these will be refactored to be one value.
  @Default(.photoGridVSpace) var photoGridVSpace
  
  @Default(.seamlessGrid) var seamlessGrid
  
  @State var showGridSheet = false
  @State var gridState = PhotoGridState()
  @State var gridRect: CGRect = .zero
  @State var itemRects: [CGRect]
  
  var gridItemSpacing: CGFloat {
    seamlessGrid ? 0.0 : photoGridHSpace
  }
  
  var gridRowSpacing: CGFloat {
    seamlessGrid ? 0.0 : photoGridVSpace
  }
  
  
  /// While `CursorState` manages the more advanced cursor interactions, this state
  /// is necessary for the keyboard events to work. Without giving the grid tiles
  /// a focus state, the keyevents have no view to originate from.
  // @FocusState var focusedItem: ContentIdFocusable?
  
  
  init() {
    let maxItems: Int = UserSelectPrefs<Int>.photoGridItemLimit.options.max() ?? 1000
    
    self.itemRects = Array<CGRect>(repeating: CGRect(), count: maxItems)
  }
  
  func onItemFirstTap(_ item: ContentItem) {
    cursorState.dispatch(.tap(item, mods: modState.modifiers), from: .folder)
  }
  
  func onItemSecondTap(_ item: ContentItem) {
    if modState.modifiers.isEmpty {
      navigate(item.link)
    } else {
      cursorState.dispatch(.tap(item, mods: modState.modifiers), from: .folder)
    }
  }
  
  func onItemAltTap(_ item: ContentItem) {
    cursorState.dispatch(.tap(item, mods: .control), from: .folder)
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
    cursorState.verticalDistance = Int(gridState.gridWidth/gridState.itemWidth)
  }
  
  func onGridItemGeometryChange(_ prefs: GridItemGeometryPreferenceKey.Value) {
    for pref in prefs {
      // Prevents out-of-range error when the number of grid items configured to
      // show changes (eg on user preference chagne)
      if self.itemRects.count > pref.viewIdx {
        self.itemRects[pref.viewIdx] = pref.rect
      }
    }
  }
  
  var body: some View {
    ScrollViewReader { proxy in
      ZStack(alignment: .topTrailing) {
        OverlayVerticalScrollView {
          VStack(spacing: 0) {
            LazyGridContent
              .padding(.horizontal, gridItemSpacing)
              .frame(maxWidth: .infinity)
              .onPreferenceChange(GridItemGeometryPreferenceKey.self, perform: onGridItemGeometryChange)
              .contextMenu {
                GridContextMenu
              }
            
            ErrorCallouts()
          }
          .coordinateSpace(name: "photoGridZstack")
          .background(GridGeometrySetter)
        }
        
        ShowAdjustmentsBtn
          .debugVisible(flag: .views_debug)
      }
      .onChange(of: cursorState.position) {
        proxy.scrollTo(cursorState.cursorItem?.id.value)
      }
    }
    .onChange(of: items, initial: true) {
      cursorState.items = items
      $dbTagCounts.contentIds.wrappedValue = items.ids
    }
    .onChange(
      of: currentRoute,
      debounceTime: .milliseconds(200)
    ) { prevRoute, nextRoute in
      if prevRoute.page == .folder && nextRoute.page == .folder {
        cursorState.clearAndReset()
      }
    }
    .onChange(of: gridRect, debounceTime: .milliseconds(50)) {
      onGridGeometryChange()
    }
    .onChange(of: itemRects, debounceTime: .milliseconds(50)) {
      onGridGeometryChange()
    }
    .buttonShortcut(binding: .onEnter) {
      if let item = cursorState.anyOneSelected {
        navigate(item.link)
      }
    }
    .buttonShortcut(binding: .info) {
      if let item = cursorState.anyOneSelected {
        dispatch(.showSheet(.contentDetailSheet(item: item)))
      }
    }
    .buttonShortcut(binding: .editTags, action: exec.edit_EditTagsButton)
    .environment(\.photoGridState, gridState)
    .environment(\.dbContentItemTagMap, dbTagCounts)
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
    .accessibilityIdentifier("photo-grid")
  }
  
  
  func PhotoGridItem(item: ContentItem, index: Int) -> some View {
    SelectableItemView(
      itemState: cursorState.focusState(of: item.pointer),
      insetAmount: 0,
      onTap: { interaction, mods in
        switch interaction {
        case .willSelect:
          onItemFirstTap(item)
        case .willDeselect:
          onItemSecondTap(item)
        default:
          break;
        }
      }
    ) { state in
      GridItemView(item: item, index: index)
        .padding(9)
        .background(state.colors.fill)
        .border(state.colors.stroke, width: 8, cornerRadius: gridState.itemWidth / 24)
    }
    /// Enable dragging of content items into folders
    .draggable(contentItem: item)
  
    /// For non-folder types, enable Tag drops
    .modify(when: item.diverges(from: .folder)) { $0
      .acceptsTagDrops(addTo: item)
    }
  
    /// For folder types, enable content item drops
    .modify(when: item.conforms(to: .folder)) { $0
      .acceptsContentDrops(moveItemTo: item.index)
    }
  }
  
  @ViewBuilder
  var GridContextMenu: some View {
    if cursorState.manySelected {
      MultiSelectContextMenu(onSelection: dispatch)
    } else {
      if let item = items[safe: cursorState.position] {
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

  static let defaultValue: Value = []
    
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
