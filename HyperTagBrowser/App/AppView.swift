// created on 9/23/24 by robinsr

import Foundation
import AppKit
import SwiftUI
import Defaults
import OSLog
import System


protocol ModelIntegrated {
  var appVM: AppViewModel { get }
}


extension ModelIntegrated {

  func when<T>(_ val: T?, _ perform: @escaping (T) -> ()) {
    if let val { perform(val) }
  }
  
  func when(isTrue: @escaping () -> (), otherwise: @escaping () -> () = {}) -> (Bool) -> () {
    { value in
      if value == true {
        isTrue()
      } else {
        otherwise()
      }
    }
  }
}


protocol LogIntegrated {
  var logger: Logger { get }
}


protocol LogIntegratedView : LogIntegrated, View {}
