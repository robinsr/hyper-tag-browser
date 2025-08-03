// created on 5/27/25 by robinsr

import Defaults
import SwiftUI


struct GridTileSizeSlider: View {
  @Default(.gridTileSize) var tileMinSize
  @State var sliderValue: Double = Defaults[.gridTileSize]
  @State var isInteracting: Bool = false
  @State var commitOnPause: DispatchWorkItem?
  
  private let logger = Self.newLogger("BaBaBooey")
  
  let pauseTime: DispatchTimeInterval = .milliseconds(40)
  
  func commitValue() {
    commitOnPause?.cancel()
    
    logger.emit(.debug, "Committing value to Defaults: \(sliderValue)")
    Defaults[.gridTileSize] = sliderValue
  }
  
  
  var body: some View {
    Slider(
      value: $sliderValue,
      in: Constants.minTileSize...Constants.maxTileSize,
      onEditingChanged: { interacting in
        if !interacting {
          // If the user stops interacting with the slider, commit the value
          commitValue()
        }
      },
      minimumValueLabel: Label("Smaller Tiles", .gridSmall),
      maximumValueLabel: Label("Larger Tiles", .gridLarge)
    ) {
     Text("Tile Size")
    }
    .frame(width: 125)
    .syncDefaultsValue(.gridTileSize, with: $sliderValue)
    .onInactivity(of: $sliderValue, after: pauseTime, using: $commitOnPause) {
      // Commit the value to Defaults after a delay
      commitValue()
    }
  }
}

