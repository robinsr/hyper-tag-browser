// created on 3/31/25 by robinsr

import SwiftUI


struct SidebarButton<ButtonContent: View>: View {

  @Binding var isActive: Bool
  @Binding var isHovered: Bool
  var activateOn: UIActivationState = .none
  var onTapAction: (() -> Void)? = nil
  let content: () -> ButtonContent

  var borderColor: Color {
    if isHovered && isActive && activateOn.active {
      return .sidebarButtonBorder
    }
    
    if isHovered && !isActive && activateOn.inactive {
      return .sidebarButtonBorder
    }

    return Color.clear
  }

  var borderWidth: CGFloat {
    isHovered ? 1.15 : 0.0
  }

  var backgroundColor: Color {
    isActive ? .sidebarButtonBackground : .clear
  }
  
  var innerPadding: EdgeInsets {
    .fromEdges(4.75, 3.25, 5.25, 3.25)
  }
  
  var outerPadding: EdgeInsets {
    .fromSides(horizontal: 2.0, vertical: 1.25)
  }
  
  var BtnContainer: some View {
    RoundedRectangle(cornerRadius: 6.0)
      .fill(backgroundColor)
      .strokeBorder(borderColor, lineWidth: 1.15)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .animation(.sidebarButtonHover, value: animateState)
  }
  
  var animateState: String {
    isActive.string + isHovered.string
  }

  var body: some View {
    content()
      .padding(innerPadding)
      .frame(maxWidth: .infinity, alignment: .topLeading)
      .padding(outerPadding)
      .background {
        BtnContainer
      }
      .onHover { isHov in
        isHovered = isHov
      }
      .contentShape(Rectangle())
      .onTapGesture {
        if !isActive {
          onTapAction?()
        }
      }
  }
}


extension Animation {
  static var sidebarButtonHover: Animation {
    .timingCurve(.circularEaseOut, duration: 0.15)
  }
}


extension Color {
  static var sidebarButtonBorder: Color {
    .accentColor.opacity(0.55)
  }
  
  static var sidebarButtonBackground: Color {
    .quaternaryLabelColor.opacity(0.80)
  }
}


#Preview("SidebarButton", traits: .fixed(300, 800), .testBordersOn) {
  @Previewable @State var fontSize = NSFont.systemFontSize(for: .regular)
  @Previewable @State var browseURL: URL = .homeDirectory
  @Previewable @State var bookmarkURLS: [URL] = TestData.testDirFolders

  VStack(alignment: .leading, spacing: 2) {
    ForEach(bookmarkURLS, id: \.self) { url in
      SidebarButton(
        isActive: .constant(browseURL == url),
        isHovered: .constant(false),
        activateOn: .all,
        onTapAction: {
          // browseURL = url
          print("Tapped \(url.filepath.string)")
        }
      ) {
        Text(url.filename)
          .prefixWithFileIcon(.folder, size: fontSize, presentation: .image)
          .font(.system(size: fontSize))
      }
    }
    // .frame(alignment: .leading)
  }
  .padding()
  .background(Color.clear)
  .environment(\.location, browseURL)
  .onChange(of: browseURL) {
    print("Set browserURL to \(browseURL.path)")
  }
}
