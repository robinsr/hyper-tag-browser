// created on 4/2/25 by robinsr

import SwiftUI


extension Image {
  
    /// Create Image from SFSymbol with optional `variableValue`
  init<T: RawRepresentable>(symbol: T, variableValue: Double? = nil) where T.RawValue == String {
    self.init(systemName: symbol.rawValue, variableValue: variableValue)
  }
  init(_ symbol: SymbolIcon) {
    self.init(systemName: symbol.systemName)
  }
  
  init(_ bundleImage: BundleImageIcon) {
    self.init(nsImage: bundleImage.nsImage)
  }
  
  init(fileType: FileTypeIcon, size: CGFloat = 12) {
    self.init(nsImage: fileType.nsImage.resize(to: .init(width: size, height: size)))
  }
  
  init(_ condition: Bool, _ whenTrue: SymbolIcon, _ whenNot: SymbolIcon) {
    self.init(systemName: condition ? whenTrue.systemName : whenNot.systemName)
  }
}
