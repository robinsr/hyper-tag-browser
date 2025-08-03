// created on 11/22/24 by robinsr

import Factory
import SwiftUI

/**
 * Defines the different variants of the `PillButton` (effectively the `TagButton`)
 *
 * Currently just two: `.primary` and `.secondary`
 *
 */
enum PillButtonVariant {
  case primary(_ pole: FilteringTag.FilterEffect = .inclusive)
  case secondary(_ pole: FilteringTag.FilterEffect = .inclusive)

  static let primary = Self.primary(.inclusive)
  static let secondary = Self.secondary(.inclusive)

  var symbolVariant: SymbolVariants {
    switch self {
      case .primary: .fill
      case .secondary: .none
    }
  }

  /**
   * Returns the inverse of the variant's polarity.
   */
  var negated: Self {
    switch self {
      case .primary(let pole): .primary(pole.inverted)
      case .secondary(let pole): .secondary(pole.inverted)
    }
  }

  var style: PillButtonVariantStyleConfiguration {
    switch self {
      case .primary(let pole):
        switch pole {
          case .inclusive: return .primaryInclusive
          case .exclusive: return .primaryExclusive
        }
      case .secondary(let pole):
        switch pole {
          case .inclusive: return .secondaryInclusive
          case .exclusive: return .secondaryExclusive
        }
    }
  }
}


struct PillButtonVariantStyleConfiguration {
  typealias Values = ColorSchemeSwitch
  
  private static let theme = Container.shared.themeProvider().current

  var foreground: Values<Color>
  var background: Values<Color>
  var borderColor: Values<Color> = .init(.clear)
  var borderWidth: Values<Double> = .init(0)
  
  
  private static let exBase = theme.danger

  private static func mixRed(_ color: Color, _ amount: Double = 0.5) -> Color {
    exBase.mix(with: color, by: amount)
  }

  private static let bgLight = Color.lightModeBackgroundColor
  private static let bgDark = Color.darkModeBackgroundColor
  private static let fgAlt = Color.secondary.lighten(by: 0.2)
  private static let fgLightPrim = bgLight.lighten(by: 0.2)
  private static let fgDarkPrim = fgAlt.lighten(by: 0.4)
  private static let bgLightSec = bgDark.lighten(by: 0.2)


  static let primaryInclusive: Self = .init(
    foreground: [
      fgLightPrim, fgDarkPrim,
    ],
    background: [
      bgDark
    ]
  )

  static let primaryExclusive: Self = .init(
    foreground: [
      fgLightPrim, fgDarkPrim,
    ],
    background: [
      //mixRed(bgLight, 0.15), mixRed(bgDark, 0.5)
      mixRed(bgDark, 0.2), mixRed(bgDark, 0.5)
    ],
    borderColor: [
      mixRed(bgLight, 0.6), mixRed(bgDark, 0.2)
    ],
    borderWidth: [0.25, 1.0]
  )
  
  
 

  static let secondaryInclusive: Self = .init(
    foreground: [
      bgLightSec, fgAlt,
    ],
    background: [
      fgLightPrim, bgDark.opacity(0.2),
    ],
    borderColor: [
      bgLightSec, fgAlt,
    ],
    borderWidth: [
      0.25, 1.0,
    ]
  )
  

  static let secondaryExclusive: Self = .init(
    foreground: [
      bgLightSec, fgAlt
    ],
    background: [
      mixRed(bgLight), mixRed(bgDark)
    ],
    borderColor: [
      mixRed(bgLightSec, 0.5), mixRed(fgAlt, 0.5),
    ],
    borderWidth: [0.25, 1.0]
  )
}
