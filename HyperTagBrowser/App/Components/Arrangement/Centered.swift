// created on 11/11/24 by robinsr

import SwiftUI


struct ContentCenteredView<Content: View>: View {
  var axis: Axis.Set = [.horizontal, .vertical]
  
  @ViewBuilder var content: () -> Content
  
  var body: some View {
    ZStack(alignment: .center) {
      content()
    }
    .fillFrame(axis)
  }
}

struct RelativeContainerCenteredModifier : ViewModifier {
  var axis: Axis.Set = .horizontal
  var width: Int = 0
  
  func body(content: Content) -> some View {
    content
      .containerRelativeFrame(axis, count: 100, span: width, spacing: 0)
      .fillFrame(axis, alignment: .center)
  }
}

extension View {
  func relativeCentering(
    _ axis: Axis.Set = .horizontal,
    spanning width: Int = 0,
    of total: Int = 100
  ) -> some View {
    return modifier(RelativeContainerCenteredModifier(axis: axis, width: width))
  }
}

struct SpacerCenteredViewModifier: ViewModifier {
  var axis: Axis.Set = .horizontal
  var width: Int = 0
  
  func body(content: Content) -> some View {
    HStack {
      Spacer()
      content
      Spacer()
    }
  }
}

extension View {  
  func centered() -> some View {
    return modifier(SpacerCenteredViewModifier())
  }
}


#Preview("Centered", traits: .fixedLayout(width: 260, height: 400)) {
  VStack(alignment: .leading) {
    Text("Normal Text")
      .border(.red)
    
    Text("Normal Text - fillFrame Hz")
      .fillFrame(.horizontal)
      .border(.red)
    
    ContentCenteredView {
      Text("{ Centered }")
        .border(.blue)
    }
    .border(.red)
    
    Text(".centered()")
      .centered()
      .border(.red)
    
    VStack {
      Text(".centerContent(width: 30)")
        .border(.blue)
    }
    .relativeCentering(spanning: 30)
    .border(.red)
  }
}
