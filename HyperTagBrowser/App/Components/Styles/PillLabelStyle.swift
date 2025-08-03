// created on 11/22/24, by robinsr

import Factory
import SwiftUI

/**
 * Defines a `LabelStyle` that displays as a capsule shape, icon and label horizontally inline,
 * responsive to presses and active states
 */
struct PillLabelStyle: LabelStyle {
  
  @Environment(\.activeTagButton) var isActiveTag
  @Environment(\.activeTagHighlightColor) var highlightColor
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.isEnabled) var isEnabled
  @Environment(\.isFocusEffectEnabled) var canFocus

  var size: PillButtonSize
  var variant: PillButtonVariant = .primary
  var isPressed: Bool = false

  var showAsPressed: Bool {
    isPressed || isActiveTag
  }

  var config: PillButtonVariantStyleConfiguration {
    variant.style
  }

  var disabled: Bool {
    !isEnabled
  }

  var foregroundColor: Color {
    config.foreground[colorScheme].opacity(disabled ? 0.999 : 1.0)
  }

  var backgroundColor: Color {
    config.background[colorScheme].opacity(disabled ? 0.6 : 1.0)
  }

  var borderColor: Color {
    config.borderColor[colorScheme].opacity(disabled ? 0.999 : 1.0)
  }

  var borderWidth: Double {
    config.borderWidth[colorScheme]
  }

  var CapsuleBackground: some View {
    Capsule(style: .circular)
      .fill(backgroundColor)
      .strokeBorder(borderColor, lineWidth: borderWidth)
      .shadow(color: .darkModeBackgroundColor, radius: 1)
  }

  var CapsuleOverlay: some View {
    Capsule()
      .stroke(showAsPressed ? highlightColor : .clear, lineWidth: 2)
  }

  func makeBody(configuration: LabelStyleConfiguration) -> some View {
    HStack(spacing: 2) {
      configuration.icon
      configuration.title
    }
    .foregroundStyle(foregroundColor)
    .padding(size.insets)
    .background {
      CapsuleBackground
    }
    .overlay {
      CapsuleOverlay
    }
    .font(size.font)
    .modify(when: canFocus) {
      $0
        .scaleEffect(showAsPressed ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: showAsPressed)
    }
  }
}

extension LabelStyle where Self == PillLabelStyle {

  /// Applies the `.small` variant of ``PillLabelStyle`` to a `Label`
  static var smallpill: Self { PillLabelStyle(size: .small) }

  /// Applies the `.large` variant of ``PillLabelStyle`` to a `Label`
  static var largepill: Self { PillLabelStyle(size: .large) }
}

extension EnvironmentValues {
  @Entry var activeTagButton: Bool = false
  @Entry var activeTagHighlightColor = Container.shared.colorTheme().success
}

extension View {

  /**
   * Sets `.activeTagButton` environment value depdending on bool value of `condition`
   */
  func activateTag(when condition: @autoclosure () -> Bool, color: Color? = nil) -> some View {
    let defaultColor = Container.shared.themeProvider().success
    
    return self
      .environment(\.activeTagButton, condition())
      .environment(\.activeTagHighlightColor, color ?? defaultColor)
  }
}

#Preview("PillLabelStyle", traits: .sizeThatFitsLayout) {
  
  @Previewable @Environment(\.colorScheme) var colorScheme
  @Previewable @State var buttonSize: PillButtonSize = .large

  VStack {
    Picker("Button Size", selection: $buttonSize) {
      ForEach(PillButtonSize.allCases, id: \.id) { size in
        Text(size.rawValue)
          .tag(size)
      }
    }
    .pickerStyle(.segmented)
    
    Grid {
      GridRow {
        Text("")
        Text("Primary")
        Text("Secondary")
      }
      .fillFrame()
      GridRow {
        Text("default")
        Label("Edit tags", .tag)
          .labelStyle(PillLabelStyle(size: buttonSize, variant: .primary))
        Label("Edit tags", .tag)
          .labelStyle(PillLabelStyle(size: buttonSize, variant: .secondary))
      }
      GridRow {
        Text("disabled")
        Label("Edit tags", .tag)
          .labelStyle(PillLabelStyle(size: buttonSize, variant: .primary)).disabled(true)
        Label("Edit tags", .tag)
          .labelStyle(PillLabelStyle(size: buttonSize, variant: .secondary)).disabled(true)
      }
      GridRow {
        Text("exclusive")
        Label("Edit tags", .tag)
          .labelStyle(PillLabelStyle(size: buttonSize, variant: .primary(.exclusive)))
        Label("Edit tags", .tag)
          .labelStyle(PillLabelStyle(size: buttonSize, variant: .secondary(.exclusive)))
      }
    }
    .fillFrame()
  }
  .frame(width: 400, height: 200)
  .scaleEffect(2.0)
  .frame(width: 800, height: 400)
  .scenePadding()
  
  .background(.background)
}
