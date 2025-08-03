// created on 3/16/25 by robinsr

import Foundation


/**
 A FormatStyle appropriate for displaying a human-readable quantity of something.
 
  This is a more general version of ``ShortNumberFormat`` that can be used to display
  quantities of anything, not just numbers. It formats the quantity as a string with
  a compact notation, and can handle special cases for zero values.
  
 */
struct QuantityOfNumberFormat: FormatStyle {
  var zeroDeterminer: String = "no"
  var singularDeterminer: String = "one"
  
  func format(_ value: Int) -> String {
    if value == 0 { return zeroDeterminer }
    if value == 1 { return singularDeterminer }
    
    return value.formatted(.number.notation(.automatic).grouping(.automatic))
  }
}

extension FormatStyle where Self == QuantityOfNumberFormat {
  static func quantityOf(zeroIs: String = "no", oneIs: String = "one") -> QuantityOfNumberFormat {
    .init(zeroDeterminer: zeroIs, singularDeterminer: oneIs)
  }
}
