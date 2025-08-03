// created on 11/22/24 by robinsr

import SwiftUI

struct PillButtonStyle: ButtonStyle {
  @Environment(\.isEnabled) private var isEnabled: Bool

  var size: PillButtonSize = .small
  var variant: PillButtonVariant = .primary

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .labelStyle(PillLabelStyle(
        size: size,
        variant: variant,
        isPressed: configuration.isPressed
      ))
  }
}

extension ButtonStyle where Self == PillButtonStyle {

  /// Applies the `.small` variant of the ``PillButtonStyle`` to a `Button`
  static var smallpill: Self { PillButtonStyle(size: .small) }

  /// Applies the `.large` variant of the ``PillButtonStyle`` to a `Button`
  static var largepill: Self { PillButtonStyle(size: .large) }
}
