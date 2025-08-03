// created on 1/25/25 by robinsr

import SwiftUI
import Defaults


struct GridSpacingControls: View, SheetPresentable {
  static let presentation: SheetPresentation = .infoSticky(controls: .close)
  
  @Default(.gridTileSize) var gridTileMinSize
  @Default(.photoGridItemInset) var gridTileInset
  @Default(.photoGridHSpace) var gridItemSpacing
  @Default(.photoGridVSpace) var gridRowSpacing
  
  var body: some View {
    VStack {
      Text("Grid Spacing Controls")
        .modalContentTitle()
      
      Grid {
        GridRow {
          Text("Grid Tile Min Size")
          Slider(value: $gridTileMinSize, in: Constants.minTileSize...Constants.maxTileSize)
          Text("\(gridTileMinSize, specifier: "%.1f")")
            .monospaced()
        }
        GridRow {
          Text("Grid Tile Inset")
          Slider(value: $gridTileInset, in: 0...30)
          Text("\(gridTileInset, specifier: "%.1f")")
            .monospaced()
        }
        GridRow {
          Text("Grid Item Spacing")
          Slider(value: $gridItemSpacing, in: 0...30)
          Text("\(gridItemSpacing, specifier: "%.1f")")
            .monospaced()
        }
        GridRow {
          Text("Grid Row Spacing")
          Slider(value: $gridRowSpacing, in: 0...30)
          Text("\(gridRowSpacing, specifier: "%.1f")")
            .monospaced()
        }
        GridRow {
          Toggle("Show Test Borders", isOn: .flag(.views_showTestBorders))
            .toggleStyle(.switch)
            .gridCellColumns(3)
        }
        
      }
      .frame(width: 450)
    }
    .modalContentBody()
  }
}
