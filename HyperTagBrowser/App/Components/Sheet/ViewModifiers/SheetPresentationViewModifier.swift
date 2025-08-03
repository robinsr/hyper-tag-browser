// created on 2/21/25 by robinsr

import SwiftUI


/**
 * Modifies the View to with characteristics from the provided `SheetPresentation` style. This is to
 * be applied to the **inner content of a sheet**
 */
struct SheetPresentationViewModifier: ViewModifier {
  @Environment(\.enabledFlags) var devFlags
  
  @Binding var style: SheetPresentation
  var alignment: Alignment = .center
  
  func body(content: Content) -> some View {
    content
      .frame(
        minWidth: style.minWidth,
        maxWidth: style.maxWidth,
        minHeight: style.minHeight,
        maxHeight: style.maxHeight,
        alignment: alignment
      )
      .withTestBorder(.pink, "SheetViewModifier#.frameSpec")
      .modify(when: style.hasFixedEdge) { $0
        .fixedSize(horizontal: style.fixedHz, vertical: style.fixedVt)
      }
      .modify(when: style.isFitted) { $0
        .presentationSizing(
          .form.fitted(horizontal: style.fitHz, vertical: style.fitVt)
        )
      }
      .modify(when: style.isSticky) { $0
        .presentationSizing(
          .form
            .sticky(horizontal: style.stickyHz, vertical: style.stickyVt)
        )
      }
      .modify(when: devFlags.contains(.views_debug)) { $0
        .onTapGesture {
          print("DebugViews — \(style.debugDescription)")
        }
        .onChange(of: style) {
          print("DebugViews — \(style.debugDescription)")
        }
      }
      .presentationDragIndicator(.visible)
      .presentationBackground(Color.clear)
  }
}
