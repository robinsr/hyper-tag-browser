// created on 10/19/24 by robinsr

import SwiftUI


enum DisclosureState {
  case open, closed
}


struct ClickableLabelDisclosure<Content: View, LabelContent: View>: View {
  @Binding var isPresented: Bool
  @ViewBuilder var content: () -> (Content)
  @ViewBuilder var label: () -> (LabelContent)
  
  var body: some View {
    DisclosureGroup(isExpanded: $isPresented) {
      content()
    } label: {
      label()
        .onTapGesture {
          isPresented.toggle()
        }
    }
  }
}


struct HoveredSectionHeaderModifier: ViewModifier {
  @State private var isHovering: Bool = false
  
  func body(content: Content) -> some View {
    content
      .background {
        RoundedRectangle(cornerRadius: 2)
          .fill(Color.secondary.opacity(isHovering ? 0.03 : 0.0))
          .animation(.easeInOut(duration: 0.2), value: isHovering)
          .pointerStyle(.link)
      }
      .onHover { hovering in
        isHovering = hovering
      }
  }
}


struct SectionView<Content: View, LabelContent: View>: View {
  var title: String? = nil
  var label: (() -> (LabelContent))? = nil
  let content: () -> (Content)
  var divider: Bool = false
  var initial: DisclosureState = .open
  
  private var isPresented: Binding<Bool>? = nil
  
  
  /**
   Usage:
   
   ```swift
   SectionView(isPresented: $showing, title: "Content Title") {
    ContentView()
   }
   ```
   */
  @available(*, deprecated, renamed: "init(isPresented:title:divider:content:)", message: "Use `SectionView(_:isPresented:divider:content:)` instead.")
  init(
    isPresented: Binding<Bool>,
    title: String,
    divider: Bool = false,
    @ViewBuilder content: @escaping () -> (Content)
  ) where LabelContent == Text {
    self.title = title
    self.content = content
    self.divider = divider
    self.isPresented = isPresented
  }
  
  /**
   Usage:
   
   ```swift
   SectionView("Content Title", isPresented: $showing) {
    ContentView()
   }
   ```
   */
  init(
    _ title: String,
    isPresented: Binding<Bool>,
    divider: Bool = false,
    @ViewBuilder content: @escaping () -> (Content)
  ) where LabelContent == Text {
    self.title = title
    self.content = content
    self.divider = divider
    self.isPresented = isPresented
  }
  
  
  /**
   Usage:
   
   ```swift
   SectionView(isPresented: $showing) {
    ContentView()
   } label: {
    Text("Content Title")
   }
   ```
   */
  init(
    isPresented: Binding<Bool>,
    @ViewBuilder content: @escaping () -> (Content),
    @ViewBuilder label: @escaping () -> (LabelContent)
  ) {
    self.content = content
    self.label = label
    self.isPresented = isPresented
  }
  
  
  /**
   Usage:
   
   ```swift
   SectionView("Replace Image", initial: .closed) {
    ContentView()
   }
   ```
   */
  init(
    _ title: String,
    initial: DisclosureState = .open,
    divider: Bool = true,
    @ViewBuilder content: @escaping () -> (Content)
  ) where LabelContent == Text {
    self.title = title
    self.content = content
    self.divider = divider
    
    self._defaultIsPresented = State(initialValue: initial == .open)
  }
  
  
  /**
   Usage:
   
   ```swift
   SectionView(.open) {
    ContentView()
   } label: {
    Text("Content Title")
   }
   ```
   */
  init(
    _ initial: DisclosureState = .open,
    divider: Bool = false,
    @ViewBuilder content: @escaping () -> (Content),
    @ViewBuilder label: @escaping () -> (LabelContent)
  ) {
    self.content = content
    self.label = label
    self.divider = divider
    
    self._defaultIsPresented = State(initialValue: initial == .open)
  }
  
  
  var labelContent: some View {
    Group {
      if let label = label {
        label()
      } else {
        Text(title ?? "")
      }
    }
    .styleClass(.sectionLabel)
  }
  
  @State private var defaultIsPresented: Bool = true
  
  var body: some View {
    if isPresented != nil {
      ClickableLabelDisclosure(isPresented: isPresented!) {
        DisclosureContent
      } label: {
        DisclosureLabel
      }
    } else {
      ClickableLabelDisclosure(isPresented: $defaultIsPresented) {
        DisclosureContent
      } label: {
        DisclosureLabel
      }
    }
  }
  
  var DisclosureContent: some View {
    VStack {
      content()
    }
    .fillFrame(.horizontal, alignment: .leading)
    .padding(.vertical, 8)
    .transition(.slide)
  }
  
  var DisclosureLabel: some View {
    labelContent
      .padding(4)
      .fillFrame(.horizontal, alignment: .topLeading)
//      .modifier(HoveredSectionHeaderModifier())
  }
}
