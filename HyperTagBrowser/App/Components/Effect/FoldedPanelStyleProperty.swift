// created on 4/30/25 by robinsr

import SwiftUI


extension View {
  
  /**
   * Sets the specified FoldedPanelStyle to the view.
   *
   * This follows the SwiftUI convention of using a "fooStyle" modifier to
   * apply a style to a view. It works by storing the style in the
   * environment, which is then used by the view to determine how to
   * render itself.
   */
  func panelStyle(_ style: some FoldedPanelStyle) -> some View {
    environment(\.foldedPanelStyle, style)
  }
}


/**
 * A proxy view that wraps the FoldedPanelStyle and its configuration.
 */
struct StyledFoldedPanelView<Style: FoldedPanelStyle>: View {
  let style: Style
  let configuration: Style.Configuration

  var body: some View {
    style.makeBody(configuration: configuration)
  }
}


/**
 * A protocol for defining styles for FoldedPanel views.
 */
protocol FoldedPanelStyle: DynamicProperty {
  typealias Configuration = FoldedPanelStyleConfiguration
  associatedtype Body: View
  
  @ViewBuilder func makeBody(configuration: Configuration) -> Body
}

extension FoldedPanelStyle {
  func resolve(configuration: Configuration) -> some View {
    StyledFoldedPanelView(style: self, configuration: configuration)
  }
}


/**
 Configuration object for FoldedPanelStyles
 */
struct FoldedPanelStyleConfiguration {
  struct Content: View {
    let body: AnyView
  }
  
  let content: Content

  init(content: some View) {
    self.content = Content(body: AnyView(content))
  }
}


/**
 * A environment key containing the FoldedPanelStyle, accessible within the proxied View
 */
struct FoldedPanelStyleEnvironmentKey: EnvironmentKey {
  static var defaultValue: any FoldedPanelStyle = PlainFoldedPanelStyle()
}

extension EnvironmentValues {
  var foldedPanelStyle : any FoldedPanelStyle {
    get { self[FoldedPanelStyleEnvironmentKey.self] }
    set { self[FoldedPanelStyleEnvironmentKey.self] = newValue }
  }
}
