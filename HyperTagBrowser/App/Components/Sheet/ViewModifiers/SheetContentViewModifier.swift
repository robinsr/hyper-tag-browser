// created on 6/6/25 by robinsr

import SwiftUI




struct SheetContentViewModifier<InnerContent: View>: ViewModifier {
  @Environment(\.windowSize) var windowSize
  
  @Binding var isPresented: Bool
  var presentation: SheetPresentation
  @ViewBuilder var innerContent: () -> InnerContent
  
  func body(content: Content) -> some View {
    content
      .sheet(isPresented: $isPresented) {
        SheetView(style: presentation, isPresented: $isPresented) {
          innerContent()
        }
      }
  }
}

extension View {
  
  /**
   * A convenience method for presenting a sheet view with a given style.
   *
   * Usage:
   *
   * ```swift
   * var body: some View {
   *   ContentView()
   *     .sheetView(
   *       isPresented: $isSheetPresented,
   *       style: .modalSticky(controls: .close)) {
   *         Text("This is inside a modal-sized sticky sheet!")
   *       }
 *       )
   * }
   * ```
   */
  func sheetView<InnerContent: View>(
    isPresented: Binding<Bool>,
    style: SheetPresentation,
    @ViewBuilder content: @escaping () -> InnerContent
  ) -> some View {
    modifier(SheetContentViewModifier(
      isPresented: isPresented,
      presentation: style,
      innerContent: content
    ))
  }
}
