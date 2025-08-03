// created on 10/17/24 by robinsr

import SwiftUI
import Defaults


struct ColorDetailsToolbarItem: View {
  @Environment(\.colorModel) var bgColor
  
  @State var isPresented: Bool = false
  
  var body: some View {
    ColorRect(color: bgColor.color)
      .popover(isPresented: $isPresented, arrowEdge: .bottom) {
        ImageColorDetails()
          .padding()
          .frame(width: 360)
      }
      .onTapGesture {
        isPresented.toggle()
      }
  }
}


struct ImageColorDetails: View {

  @Environment(\.colorScheme) var systemScheme
  @Environment(\.colorModel) var bgColor
  @Environment(\.enabledFlags) var devFlags
  
  @Default(.backgroundColor) var userBGColor
  

  var body: some View {
    VStack(alignment: .leading) {
      SectionView("Dominant Color") {
        ColorRect(color: bgColor.dominantColor, showDetails: true)
      }
      
      SectionView("Component Colors") {
        ForEach(bgColor.colors, id: \.self) { item in
          ColorRect(color: item, showDetails: true)
        }
        
        if bgColor.colors.isEmpty {
          Text("No colors detected")
            .foregroundColor(.secondary)
        }
      }
      
      SectionView("Applied BG Color") {
        ColorRect(color: bgColor.color, showDetails: true)
      }
      
      SectionView("User's BG Color") {
        ColorRect(color: userBGColor, showDetails: true)
      }
      
      SectionView("Color Scheme") {
        LabeledContent {
          ColorSchemeRect(systemScheme)
        } label: {
          Text("System Scheme")
        }
        
        LabeledContent {
          ColorSchemeRect(bgColor.colorScheme)
        } label: {
          Text("Dynamic Scheme")
        }
      }
    }
  }
}



#Preview("ImageColorDetails", traits: .defaultViewModel) {
  ImageColorDetails()
    .frame(preset: .panel)
}
