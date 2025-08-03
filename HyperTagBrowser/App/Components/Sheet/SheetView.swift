// created on 2/21/25 by robinsr

import SwiftUI


struct SheetView<Content: View> : View {
  @Environment(\.windowSize) var windowSize
  @Environment(\.dispatcher) var dispatch

  let style: SheetPresentation
  var isPresented: Binding<Bool>? = nil
  let content: () -> (Content)
  
  init(
    style: SheetPresentation, @ViewBuilder content: @escaping () -> Content
  ) {
    self.style = style
    self.content = content
    // Default to expanded if the style is not set to condensed
    _isExpanded = State(initialValue: style.behavior == .expanded)
    _useStyle = State(initialValue: style)
  }
  
  init(
    style: SheetPresentation,
    isPresented: Binding<Bool>,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.style = style
    self.content = content
    self.isPresented = isPresented
    
    // Default to expanded if the style is not set to condensed
    _isExpanded = State(initialValue: style.behavior == .expanded)
    _useStyle = State(initialValue: style)
  }
  
  @State var isExpanded: Bool
  @State var useStyle: SheetPresentation
  
 func onDismiss() {
    isPresented?.wrappedValue = false
    
    if isPresented == nil {
      dispatch(.showSheet(.none))
    }
  }
  
  var body: some View {
    ZStack {
      content()
        .preferredColorScheme(.dark)
        .padding(.vertical, style.paddingVt)
        .padding(.horizontal, style.paddingHz)
        .environment(\.sheetPresentation, useStyle)
        .environment(\.sheetControls, style.controls)
        .environment(\.sheetPadding, style.padding)
    }
    .overlay(alignment: .topTrailing) {
      SheetViewControls
        .withTestBorder(.yellow)
    }
    .modifier(SheetPresentationViewModifier(
      style: $useStyle
    ))
    .onChange(of: isExpanded) {
      withAnimation(style.resizeAnimation) {
        // Sets the style to one of the sub-variants (expanded or contracted)
        useStyle = isExpanded ? style.expanded : style.condensed
      } completion: {
        // Resets the style back to the original after the animation completes
        useStyle = style
      }
    }
  }
  
  var SheetViewControls: some View {
    HStack {
      Group {
        if style.controls.contains(.expand) {
          ExpandSheetButton
        }
        
        if style.controls.contains(.close) {
          CloseSheetButton
        }
      }
      .buttonStyle(.closePanel)
      .font(.system(size: 8))
    }
    .padding(.top, 8)
    .padding(.trailing, 8)
  }
  
  var CloseSheetButton: some View {
    Button(.close, action: onDismiss)
      .symbolVariant(.circle.fill)
  }
  
  var ExpandSheetButton: some View {
    Button(isExpanded ? SymbolIcon.shrink : SymbolIcon.expand) {
      isExpanded.toggle()
    }
    .symbolVariant(.circle.fill)
  }
}
