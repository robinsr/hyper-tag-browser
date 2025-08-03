// created on 4/2/25 by robinsr

import Defaults
import SwiftUI


@Observable
final class PhotoGridState {
  var gridWidth: CGFloat
  var itemWidth: CGFloat
  
  init(gridWidth: CGFloat = 1000.0, itemWidth: CGFloat = CGFloat(Defaults[.gridTileSize])) {
    self.gridWidth = gridWidth
    self.itemWidth = itemWidth
  }
  
  var iconSize: CGFloat {
    CGFloat(itemWidth / 9)
      .clamped(to: Constants.minIconSize...Constants.maxIconSize)
  }
  
  var iconFont: Font {
    .system(size: iconSize)
  }
  
  var itemsPerRow: Int {
    Int(gridWidth/itemWidth)
  }
  
  var itemSquare: CGSize {
    CGSize(width: itemWidth, height: itemWidth)
  }
  
  func rowCount(for itemCount: Int) -> Int {
    (itemCount + itemsPerRow - 1) / itemsPerRow
  }
  
  func rowNumber(of index: Int) -> Int {
    index / itemsPerRow
  }
}
