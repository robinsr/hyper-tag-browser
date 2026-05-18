// created on 4/23/25 by robinsr

import Factory
import SwiftUI
import UniformTypeIdentifiers


struct PathSegmentButton: View {
  @Injected(\Container.fileService) var fs
  
  var step: URLPathSegment
  var collapsible: Bool = false
  var onItemTap: (URL) -> Void = { _ in }
  
  @State var isHovering = false
  
  let fileIconWidth: CGFloat = 24
  let descendentsHandleWidth: CGFloat = 24
  
  var isHomeFolder: Bool {
    step.url == UserLocation.home
  }
  
  var fullWidth: CGFloat {
    String(step.name).widthGuestimate(fontSize: 12) + fileIconWidth + descendentsHandleWidth
  }
  
  var itemType: UTType {
    step.url.contentType
  }
  
  var hoverAnimation: Animation {
    .easeInOut(duration: 0.2).delay(0.5)
  }
  
  var body: some View {
    ButtonContent
      .onHover { hovering in
        isHovering = hovering
      }
      .modify(when: collapsible) { view in
        view
          .frame(maxWidth: isHovering ? fullWidth : 74)
          .animation(hoverAnimation, value: isHovering)
          .clipped()
      }
  }
  
  var ButtonContent: some View {
    HStack(spacing: 0) {
      
      if isHomeFolder {
        Image(.home)
          .dynamicTypeSize(.xLarge)
      }
      
      Button {
        onItemTap(step.url)
      } label: {
        Text(step.name)
          .modify(unless: isHomeFolder) {
            $0.prefixWithFileIcon(itemType)
          }
      }
      .buttonStyle(.plain)
      
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
