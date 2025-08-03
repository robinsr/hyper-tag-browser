// created on 9/26/24 by robinsr

import SwiftUI


/**
 Just a series of `Text` views created from a string array
 */
struct Headers: View {
  let names: [String]
  
  var body: some View {
    ForEach(names, id: \.self) { name in
      Text(name)
        .font(.headline)
        .monospaced()
    }
  }
}



/**
 Intended to be used as a two-column `Grid`, with the left column listing attribute names with their
 associated values in the right side column. Text is aligned to wards the center. Eg:
 
 ```txt
         name | Billy
          age | 50
    fav movie | Aliens
 ```
 
 Intended to be used as a two-column `Grid`, with the left column listing attribute names with their
 */
struct AttributeGrid<Content: View>: View {
  @ViewBuilder let content: () -> (Content)
  
  var body: some View {
    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
      content()
    }
  }
  
  @ViewBuilder
  static func Row(_ title: String, rowContent: @escaping () -> (Content)) -> some View {
    GridRow(alignment: .firstTextBaseline) {
      Text(title)
        .font(.caption.weight(.bold))
        .gridColumnAlignment(.trailing)
      
      rowContent()
    }
  }
}
