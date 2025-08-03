// created on 6/7/25 by robinsr

import SwiftUI

private struct HelpPopoverView: View {

  @Environment(\.helpPopover) var helpState

  var preferenceTip: AnyPreferenceTip

  var popoverBinding: Binding<Bool> {
    .constant(helpState.showing == preferenceTip.id)
      .onChange { val in
        if val {
          helpState.showHelp(for: preferenceTip)
        } else {
          helpState.dismissHelp(for: preferenceTip)
        }
      }
  }

  var body: some View {
    Button(.info) {
      helpState.showHelp(for: preferenceTip)
    }
    .buttonBorderShape(.circle)
    .controlSize(.small)
    .labelStyle(.iconOnly)
    .popover(isPresented: popoverBinding, arrowEdge: .trailing) {
      VStack(alignment: .leading, spacing: 6) {
        Text(verbatim: preferenceTip.label)
          .font(.headline)
          .padding(.bottom, 8)

        Text(.init(preferenceTip.helpText))

        Text("\(preferenceTip.id)")
          .font(.caption)
          .monospacedDigit()
      }
      .padding(.vertical, 8)
      .padding(.horizontal, 12)
      .frame(width: 300)
    }
  }
}

struct WithHelpPopoverViewModifier: ViewModifier {
  var pref: AnyPreferenceTip

  func body(content: Content) -> some View {
    HStack(spacing: 8) {
      HelpPopoverView(preferenceTip: pref)
      content
    }
  }
}

extension View {
  func withHelpPopover(_ pref: any PreferenceTip) -> some View {
    modifier(WithHelpPopoverViewModifier(pref: pref))
  }
}
