// created on 2/7/25 by robinsr

import SwiftUI


/**
 A `ForEach` view that inserts a divider between each element
 */
struct DividedForEach<Data: RandomAccessCollection, ID: Hashable, Content: View, D: View>: View {
  typealias ContentFn = (Data.Element) -> Content
  
  let data: Data
  let id: KeyPath<Data.Element, ID>
  @ViewBuilder let content: ContentFn
  @ViewBuilder let divider: (() -> D)

  init(
    _ data: Data,
    id: KeyPath<Data.Element, ID>,
    content: @escaping ContentFn,
    divider: @escaping () -> D = { Divider() }
  ) {
    self.data = data
    self.id = id
    self.content = content
    self.divider = divider
  }

  var body: some View {
    ForEach(data, id: id) { element in
      content(element)
    
      if element[keyPath: id] != data.last![keyPath: id] {
        divider()
      }
    }
  }
}
