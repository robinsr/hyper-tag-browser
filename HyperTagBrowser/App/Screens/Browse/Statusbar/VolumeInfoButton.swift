// created on 1/3/25 by robinsr

import SwiftUI
import Factory


struct VolumeInfoButton: View {
  
  @Injected(\Container.themeProvider) var theme
  
  var url: URL
  
  @State var showLocationSheet = false
  
  var body: some View {
    Button {
      showLocationSheet.toggle()
    } label: {
      Label {
        Text(url.volumeName)
      } icon: {
        Image(url.volumeIsBrowsable ? .volume : .volumeErr)
          .symbolRenderingMode(.hierarchical)
          .foregroundStyle(url.volumeIsBrowsable ? theme.success : theme.error)
      }
    }
    .buttonStyle(.plain)
    .sheetView(isPresented: $showLocationSheet, style: JSONView.presentation) {
      VolumeSheetContent
    }
  }
  
  var VolumeSheetContent: some View {
    ZStack {
      if let volumeInfo = url.volumeInfo {
        JSONView(object: .constant(volumeInfo))
      } else {
        Text("No volume info")
      }
    }
  }
}

