// created on 1/9/25 by robinsr

import SwiftUI


struct BorderedGroupBoxStyle: GroupBoxStyle {
  
  var borderColor: Color {
    .primary.mix(with: .black, by: 0.2, in: .perceptual).opacity(0.7)
  }
  
  var BoxContainer: some View {
    RoundedRectangle(cornerRadius: 12, style: .continuous).inset(by: 1)
      //.fill(Color.darkModeBackgroundColor.opacity(0.6))
      .fill(.background.opacity(0.6))
      .strokeBorder(borderColor, lineWidth: 0.8)
  }
  
  var LabelContainer: some View {
    RoundedRectangle(cornerRadius: 4, style: .continuous)
      //.fill(Color.darkModeBackgroundColor)
      .fill(.background)
      .strokeBorder(borderColor, lineWidth: 0.8)
  }
  
  func makeBody(configuration: Configuration) -> some View {
    VStack(alignment: .leading) {
      configuration.label
        .styleClass(.hint)
        .shadow(color: .black, radius: 1, x: 1, y: 1)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background {
          LabelContainer
        }
        .offset(x: 12, y: -6)
      
      configuration.content
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
    .background {
      BoxContainer
    }
    .padding(.top, 6)
  }
}

extension GroupBoxStyle where Self == BorderedGroupBoxStyle {
  
  /**
   * Applies the style ``BorderedGroupBoxStyle`` to a `GroupBox`
   *
   * ```swift
   * GroupBox("Boxed") {
   *   // ...
   * }
   * .groupBoxStyle(.bordered)
   * ```
   */
  static var bordered: Self { BorderedGroupBoxStyle() }
}


#Preview("Plain GroupBox", traits: .defaultViewModel) {
  VStack {
    GroupBox("Plain GroupBox") {
      Text(TestData.LOREM)
    }
    .groupBoxStyle(.bordered)
    .fillFrame(.horizontal)
  }
  .frame(preset: .wide.wider(by: 1.5))
  .withTestBorder(.purple)
}
