// created on 3/31/25 by robinsr

import SwiftUI

struct SidebarButton<LabelContent: View>: View {

  var isActive: Binding<Bool> = .constant(false)
  var isHovered: Binding<Bool>? = nil
  var hoverEffectOn: SelectionItem.ActiveState = .all
  var onTapAction: (() -> Void)? = nil
  let label: () -> LabelContent

  @State private var isHovering = false

  var currentStates: [ButtonState] {
    let states: [ButtonState?] = [
      isActive.wrappedValue ? .active : nil,
      isHovered != nil
        ? (isHovered!.wrappedValue ? .hover : nil)
        : (isHovering ? .hover : nil),
    ]

    return states.compactMap({ $0 })          // Filter out nil values
  }

  var borderColor: Color {
    let isHovering = currentStates.contains(.hover)

    if !isHovering || hoverEffectOn.isEmpty { return Color.clear }

    let isActive = currentStates.contains(.active)
    let effectOnActive = hoverEffectOn.contains(.active)
    let effectOnInactive = hoverEffectOn.contains(.inactive)
    let effectColor = Color.accentColor.opacity(0.55)

    if isActive && effectOnActive { return effectColor }
    if !isActive && effectOnInactive { return effectColor }

    return Color.clear
  }

  var borderWidth: CGFloat {
    currentStates.contains(.hover) ? 1.15 : 0.0
  }

  var backgroundColor: Color {
    currentStates.contains(.active) ? Color.quaternaryLabelColor.opacity(0.80) : .clear
  }

  let hoverDuration: Double = 0.15

  var hoverAnimation: Animation {
    .timingCurve(.circularEaseOut, duration: hoverDuration)
  }

  var body: some View {
    label()
      .padding(.top, 4.75)
      .padding(.bottom, 5.25)
      .padding(.horizontal, 3.25)
      .frame(maxWidth: .infinity, alignment: .topLeading)
      .padding(.vertical, 1.25)
      .padding(.horizontal, 2)
      .background {
        RoundedRectangle(cornerRadius: 6.0)
          .fill(backgroundColor)
          .strokeBorder(borderColor, lineWidth: borderWidth)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .animation(hoverAnimation, value: currentStates)
      }
      .onHover { isOver in
        if let hoverBinding = isHovered {
          hoverBinding.wrappedValue = isOver
        } else {
          isHovering = isOver
        }
      }
      .contentShape(Rectangle())
      .ifLet(onTapAction) { view, action in
        view.onTapGesture {
          guard !currentStates.contains(.active) else {
            // If already active, do not trigger onTapAction again
            return
          }
          action()
        }
      }
      .pointerStyle(.link)
  }

  enum ButtonState: String {
    case hover, active
  }
}


#Preview("SidebarButton", traits: .fixedLayout(width: 300, height: 100), .testBordersOn) {
  @Previewable @State var fontSize = NSFont.systemFontSize(for: .regular)
  @Previewable @State var browseURL: URL = .homeDirectory
  @Previewable @State var bookmarkURLS: [URL] = [
    .homeDirectory, .applicationDirectory, .desktopDirectory,
  ]

  VStack(alignment: .leading, spacing: 2) {
    ForEach(bookmarkURLS, id: \.self) { url in
      SidebarButton(isActive: .constant(browseURL == url)) {
        browseURL = url
      } label: {
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
