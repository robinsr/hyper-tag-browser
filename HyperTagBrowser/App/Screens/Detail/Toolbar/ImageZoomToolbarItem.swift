// created on 2/18/25 by robinsr

import SwiftUI


struct ImageZoomToolbarItem: View {
  @Environment(\.detailEnv) var detailEnv
  
  @State var sliderValue: Double = 1.0
  
  var body: some View {
    ScrollWheelSlider(
      name: "Zoom Image",
      value: $sliderValue,
      minValue: detailEnv.minZoom,
      maxValue: detailEnv.maxZoom,
      minLabel: Label("Zoom Out", .zoomOut),
      maxLabel: Label("Zoom In", .zoomIn)
    )
    .buttonShortcut(binding: .increaseTileSize) {
      detailEnv.increaseZoom()
    }
    .buttonShortcut(binding: .decreaseTileSize) {
      detailEnv.decreaseZoom()
    }
    .onChange(of: sliderValue) {
      detailEnv.setZoom(to: sliderValue)
    }
    .onChange(of: detailEnv.totalZoom, initial: true) {
      let controlVal = $sliderValue.wrappedValue
      let modelVal = detailEnv.totalZoom
      
      if controlVal != modelVal {
        sliderValue = modelVal
      }
    }
    .help(detailEnv.helpSliderRange)
  }
}
