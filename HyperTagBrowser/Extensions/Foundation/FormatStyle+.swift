// created on 3/16/25 by robinsr

import Foundation


/**
 * A ``Foundation/FormatStyle`` appropriate for displaying a human-readable quantity of something.
 */
@available(*, deprecated, message: "Unused as of 2025-12-24")
struct QuantityOfNumberFormat: FormatStyle {
  var zeroDeterminer: String = "no"
  var singularDeterminer: String = "one"
  
  func format(_ value: Int) -> String {
    if value == 0 { return zeroDeterminer }
    if value == 1 { return singularDeterminer }
    
    return value.formatted(.number.notation(.automatic).grouping(.automatic))
  }
}

@available(*, deprecated, message: "Unused as of 2025-12-24; see QuantityOfNumberFormat")
extension FormatStyle where Self == QuantityOfNumberFormat {
  static func quantityOf(zeroIs: String = "no", oneIs: String = "one") -> QuantityOfNumberFormat {
    .init(zeroDeterminer: zeroIs, singularDeterminer: oneIs)
  }
}
