// created on 10/1/24 by robinsr

import SwiftUI


struct FeatureSwitch<FeatureContent: View, DefaultContent: View> : View {
  @Environment(\.enabledFlags) var devFlags
  
  var flags: [DevFlags] = []
  
  @ViewBuilder
  let featureContent: () -> (FeatureContent)
  
  @ViewBuilder
  let defaultContent: () -> (DefaultContent)
  
  var isEnabled: Bool {
    devFlags.contains(any: flags)
  }
  
  init(_ flags: [DevFlags],
       isOn featureContent: @escaping () -> FeatureContent,
       isOff defaultContent: @escaping () -> DefaultContent = { EmptyView() }
  ) {
    self.flags = flags
    self.featureContent = featureContent
    self.defaultContent = defaultContent
  }
  
  var body: some View {
    if isEnabled {
      featureContent()
    } else {
      defaultContent()
    }
  }
}


struct DebugVisibleModifier: ViewModifier {
  @Environment(\.enabledFlags) var devFlags

  var flag: DevFlags = .views_debug

  func body(content: Content) -> some View {
    FeatureSwitch([flag]) {
      content
    }
  }
}


extension View {
  /**
   Returns a View that is only visible when the ``DevFlags/views_debug`` flag is set
   */
  func debugVisible() -> some View {
    modifier(DebugVisibleModifier())
  }
  
  /**
   Returns a View that is only visible when the specified ``DevFlags`` is set
   */
  func debugVisible(flag: DevFlags) -> some View {
    modifier(DebugVisibleModifier(flag: flag))
  }
}

//struct Debug<Content: View>: View {
//  @Environment(\.enabledFlags) var devFlags
//
//  var flags: [DevFlags] = [.views_debug]
//  var content: () -> Content
//
//  init(_ flags: DevFlags..., @ViewBuilder content: @escaping () -> Content) {
//    self.flags = flags
//    self.content = content
//  }
//
//  var body: some View {
//    if devFlags.contains(any: flags) {
//      content()
//    }
//  }
//}
