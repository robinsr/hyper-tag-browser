// created on 10/15/24 by robinsr

import SwiftUI
import Defaults


struct SidebarView<OuterContent: View, InnerContent: View>: View {
  @Environment(\.windowSize) var windowSize
  
  @Binding var isPresented: Bool
  @Binding var position: SidebarChirality
  
  @ViewBuilder let content: () -> (OuterContent)
  @ViewBuilder let sidebar: () -> (InnerContent)
  
  @State var sidebarWidth: Double = SidebarChirality.idealWidth
  
  var topInset: CGFloat {
    windowSize.safeArea.top
  }
  
  var windowHeight: CGFloat {
    windowSize.size.height
  }
  
  func offsetAmountToHide(_ width: CGFloat) -> CGFloat {
    switch position {
    case .left: return -width
    case .right: return width
    }
  }
  
  var animationConfig: Animation {
    Constants.panelAnimationTransition
  }
  
  var body: some View {
    ZStack(alignment: position.relativeAlignment) {
      content()
          /// Moves the content over to right/left to make space for the open sidebar
        .padding(position.relativeEdge, isPresented ? sidebarWidth : 0)
        .animation(animationConfig, value: isPresented)
      
      ZStack(alignment: .topTrailing) {
        SidebarContent
        SidebarCloseButton
      }
      .frame(width: sidebarWidth)
      .shadow(radius: 8)
      .offset(x: isPresented ? 0 : offsetAmountToHide(sidebarWidth))
      .animation(animationConfig, value: isPresented)
      .colorScheme(.dark)
    }
  }
  
  var SidebarContent: some View {
    ZStack(alignment: position.contentAlignment) {
      VisualEffectView(blendingMode: .behindWindow)
      sidebar()
      SidebarEdgeHandle
    }
    .fillFrame(.vertical, alignment: .top)
  }
  
  var SidebarCloseButton: some View {
    CloseButton {
      withAnimation {
        isPresented.toggle()
      }
    }
    .scaleEffect(0.8)
  }
  
  @State var isEdgeHovered = false
  
  var SidebarEdgeHandle: some View {
    Rectangle()
      .fill(.clear)
      .frame(width: 6, alignment: position.contentAlignment)
      .contentShape(Rectangle())
      .pointerStyle(.columnResize)
      .horizontalResizeGesture(isEnabled: isPresented) { delta in
        let newSize = sidebarWidth + (position == .left ? delta : -delta)
        
        if newSize < SidebarChirality.minimumWidth {
          // close the sidebar if dragged too far
          isPresented.toggle()
          sidebarWidth = SidebarChirality.idealWidth
        } else {
          sidebarWidth = newSize.minMax(SidebarChirality.minimumWidth, SidebarChirality.maximumWidth)
        }
      }
  }
}


struct SidebarViewModifier<OuterContent: View>: ViewModifier {
  @Binding var isPresented: Bool
  @Binding var position: SidebarChirality
  @ViewBuilder let content: () -> OuterContent
  
  func body(content attachedContent: Content) -> some View {
    SidebarView(
      isPresented: $isPresented,
      position: $position,
      content: { attachedContent },
      sidebar: content)
  }
}


extension View {

  func sidebar<S: View>(
    isPresented: Binding<Bool>,
    position: Binding<SidebarChirality> = .constant(.left),
    @ViewBuilder content: @escaping () -> S
  ) -> some View {
    modifier(SidebarViewModifier(isPresented: isPresented, position: position, content: content))
  }
}
