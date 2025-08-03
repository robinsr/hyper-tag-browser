// created on 12/17/24 by robinsr

import Defaults
import Factory
import SwiftUI


struct DetailScreenToolbarItems: View {
  @Environment(\.dispatcher) var dispatch
  @Environment(\.detailEnv) var detailEnv
  @Environment(\.enabledFlags) var devFlags
  
  @Default(.inspectorPanels) var panelState
  
  @Injected(\PreferencesContainer.userPreferences) var userPrefs
  
  let content: ContentItem
  
  var debugViews: Bool { devFlags.contains(.views_debug) }
  
  var body: some View {
    Group {
      HStack {
          // Displays color information extracted from the image
        ColorDetailsToolbarItem()
          .debugVisible(flag: .views_debugDominantColor)
          .debugVisible(flag: .views_debugColorScheme)
        
          // Show pan/zoom controls when enabled
        ImageZoomToolbarItem()
          .debugVisible(flag: .enable_panAndZoom)
        
        ZoomToActualSizeButton
        ResetZoomLevelButton

        ToggleFillModeButton
        
        Divider()
      }
      .when(content, conformsTo: .image)
        
      ToggleDetailInspectorButton
      
      Divider()
      
      Button(.close) {
        dispatch(.popRoute)
      }
    }
    .buttonStyle(.toolbarIcon)
    .toggleStyle(.toolbar)
  }
  
    // Zoom to image actual size
  var ZoomToActualSizeButton: some View {
    Button(.zoomActual) {
      detailEnv.setActualSizeZoomFactor()
    }
    .keyboardShortcut(.zoomActual)
    .help(detailEnv.helpActualSize)
  }
  
    // Reset zoom level
  var ResetZoomLevelButton: some View {
    Button(.zoomFitted) {
      detailEnv.setFittedZoomFactor()
    }
    .keyboardShortcut(.zoomFitted)
    .help(detailEnv.helpFitSize)
  }
  
    // Toggle Fill Mode
  var ToggleFillModeButton: some View {
    Button(detailEnv.fillMode.icon) {
      detailEnv.toggleFillMode()
    }
    .keyboardShortcut(.toggleFillMode)
  }
  
    // Toggles the Detail Screen inspector
  var ToggleDetailInspectorButton: some View {
    Toggle(isOn: $panelState.contains(.container)) {
      Image(.info).symbolVariant(.circle.fill)
    }
    .keyboardShortcut(.info)
  }
}
