// created on 4/30/25 by robinsr

import SwiftUI


struct LinkButtonStyle: ButtonStyle {
  let weight: Font.Weight
  
  init(_ weight: Font.Weight = .regular) {
    self.weight = weight
  }
  
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .modifier(UnderlineOnHoverModifier())
      .pointerStyle(.link)
      .styleClass(.link(weight))
  }
}


extension ButtonStyle where Self == LinkButtonStyle {
  
    /// Applies the style ``LinkButtonStyle`` to a `Button`
  static var weblink: Self { LinkButtonStyle() }
}


#Preview("LinkButtonStyle") {
  Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
    GridRow {
      Text("Button.buttonStyle(LinkButtonStyle()):")
        .styleClass(.label)
      
      Button("Its a button but you wouldn't know it") {}
        .buttonStyle(LinkButtonStyle())
    }
    
    GridRow {
      Text("LinkButton {}:")
        .styleClass(.label)
      
      Button("LinkButton") {}
        .buttonStyle(.weblink)
    }
  }
  .scenePadding()
}
