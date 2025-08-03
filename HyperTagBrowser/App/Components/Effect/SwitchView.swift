// created on 4/18/25 by robinsr

import SwiftUI


struct SwitchView<DefaultContent: View, AltContent: View> : View {
  @Binding var isSwitched: Bool
  
  @ViewBuilder
  let defaultContent: () -> (DefaultContent)
  
  @ViewBuilder
  let onSwitched: () -> (AltContent)
  
  var body: some View {
    if isSwitched {
      onSwitched()
    } else {
      defaultContent()
    }
  }
}
