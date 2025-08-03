// created on 4/23/25 by robinsr

import Factory
import SwiftUI


struct PathSegmentButton: View {
  @Injected(\Container.fileService) var fs
  
  var step: URLPathSegment
  var collapsible: Bool = false
  var onItemTap: (URL) -> Void = { _ in }
  
  @State var isHovering = false
  
  let fileIconWidth: CGFloat = 24
  let descendentsHandleWidth: CGFloat = 24
  
  var isHome: Bool {
    step.url == UserLocation.home
  }
  
  var fullWidth: CGFloat {
    String(step.name).widthGuestimate(fontSize: 12) + fileIconWidth + descendentsHandleWidth
  }
  
  var body: some View {
    ButtonContent
      .onHover { hovering in
        isHovering = hovering
      }
      .modify(when: collapsible) { view in
        view
          .frame(maxWidth: isHovering ? fullWidth : 74)
          .animation(.easeInOut(duration: 0.2), value: isHovering)
          .clipped()
      }
  }
  
  var ButtonContent: some View {
    HStack(spacing: 0) {
      Image(.home)
        .dynamicTypeSize(.xLarge)
        .visible(isHome)
      
      Button {
        onItemTap(step.url)
      } label: {
        Text(step.name)
          .prefixWithFileIcon(.folder, visibility: isHome ? .hidden : .visible)
      }
      .buttonStyle(.weblink)
      
      PathSegmentDescendants(step)
        .visible(step.hasDescendants)
    }
  }
  
  func PathSegmentDescendants(_ step: URLPathSegment) -> some View {
    Menu {
      ForEach(fs.listURLs(at: step.url), id: \.filepath) { dir in
        Button {
          onItemTap(dir)
        } label: {
          Text(dir.filename)
            .prefixWithFileIcon(.folder)
        }
      }
    } label: {
      Image(.triangleRight)
        .font(.system(size: 10, weight: .ultraLight))
    }
    .menuStyle(ToolbarMenuStyle(hoverEffect: false))
  }
}
