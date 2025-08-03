// created on 12/6/24 by robinsr

import SwiftUI

class TextFieldObserver : ObservableObject {
  @Published var debouncedText = ""
  @Published var searchText = ""
  
  private var subscriptions = Set<AnyCancellable>()
  
  init() {
      $searchText
          .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
          .sink(receiveValue: { [weak self] t in
              self?.debouncedText = t
          } )
          .store(in: &subscriptions)
  }
}
