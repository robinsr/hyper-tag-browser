// created on 1/3/25 by robinsr

import SwiftUI
import Factory


struct VolumeInfoButton: View {
  
  @Injected(\Container.themeProvider) var theme
  @Environment(\.dispatcher) var dispatch
  @Environment(\.enabledFlags) var devFlags
  
  var url: URL
  
  @State var showLocationSheet = false
  
  var isRootVolume: Bool {
    url.volumeInfo?.isRoot ?? true
  }
  
  var debugEnabled: Bool {
    devFlags.contains(.views_debug)
  }
  
  var body: some View {
    Button(action: handleClick) {
      VolumeButtonLabel
    }
    .buttonStyle(.plain)
    .sheetView(isPresented: $showLocationSheet, style: JsonSheetView.presentation) {
      VolumeSheetContent
    }
    .if(!isRootVolume) { $0
      .contextMenu {
        VolumeContextMenu
      }
    }
  }
  
  private func handleClick() {
    if debugEnabled {
      showLocationSheet.toggle()
    }
  }
  
  var VolumeButtonLabel: some View {
    Label {
      Text(url.volumeName)
    } icon: {
      Image(url.volumeIsBrowsable ? .volume : .volumeErr)
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(url.volumeIsBrowsable ? theme.success : theme.error)
    }
  }
  
  var VolumeSheetContent: some View {
    ZStack {
      if let volumeInfo = url.volumeInfo {
        JsonCodeView(object: .constant(volumeInfo))
      } else {
        Text("No volume info")
      }
    }
  }
  
  var VolumeContextMenu: some View {
    Button("Eject") {
      dispatch(.ejectVolume(at: url))
    }
  }
}

