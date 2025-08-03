// created on 4/23/25 by robinsr

import SwiftUI

/**
 * Renders the checked/unchecked icon for a tag in the picker
 */
struct ListEditorRowSymbol: View {
  
  enum SymbolSize {
    case floatingPanel
    case normal
    
    var width: CGFloat { cgSize.width }
    var height: CGFloat { cgSize.height }
    
    var cgSize: CGSize {
      switch self {
      case .floatingPanel: return CGSize(width: 30, height: 22)
      case .normal: return CGSize(width: 20, height: 14)
      }
    }
  }
  
  let icon: SymbolIcon
  var color: Color = .primary
  var size: SymbolSize = .floatingPanel
  
  var body: some View {
    Image(systemName: icon.systemName)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(width: size.width, height: size.height, alignment: .center)
      .fontWeight(.light)
      .foregroundStyle(color)
      .padding(.leading, 20)
      .padding(.trailing, 2)
  }
}
