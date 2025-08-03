// created on 5/9/25 by robinsr

import SwiftUI


struct TestBorderViewModifier: ViewModifier {
  var color = Color.red
  var label: String? = nil
  
  @Environment(\.testBordersEnabled) var environmentEnabled
  @Environment(\.enabledFlags) var devFlags
  
  var enabled: Bool {
    environmentEnabled || devFlags.contains(.views_showTestBorders)
  }
  
  func body(content: Content) -> some View {
    content
      .modify(when: enabled && label != nil) { $0
        .background(alignment: .topLeading) {
          BorderLabel
        }
      }
      .modify(when: enabled) { $0
        .border(color, width: 1.0)
      }
  }
  
  var BorderLabel: some View {
    Text(label ?? "")
      .font(.system(size: 8))
      .padding(1)
      .background(Color.black.opacity(0.2))
      .foregroundColor(color)
      .offset(x: 2, y: -2)
  }
}


extension View {
    
    /// Adds a visible border to a view for debugging layout issues
  func withTestBorder(_ color: Color = Color.red) -> some View {
    return modifier(TestBorderViewModifier(color: color))
  }
  
    /// Adds a labeled visible border to a view for debugging layout issues
  func withTestBorder(_ color: Color = Color.red, _ label: String) -> some View {
    return modifier(TestBorderViewModifier(color: color, label: label))
  }
}


struct TestBorderKey: EnvironmentKey {
  private static var appStage = EnvContainer.shared.stage()
  private static let prefs = PreferencesContainer.shared.userPreferences()
  
  static var defaultValue: Bool {
    if appStage == .prod {
      return false
    }
    
    return prefs.forKey(.devFlags).contains(.views_showTestBorders)
  }
}


extension EnvironmentValues {
  @Entry var testBordersEnabled: Bool = false
}
