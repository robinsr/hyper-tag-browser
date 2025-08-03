// created on 12/17/24 by robinsr

import SwiftUI


struct CarouselButton : View {
  let direction: Direction
  let onTap: () -> ()
  
  @State var isHovered = false
  
  let iconWidth: CGFloat = 30
  
  let effectDiameter: CGFloat = 220
  
  var frameWidth: CGFloat {
    CGFloat((effectDiameter / 2) - (iconWidth / 2))
  }
  
  var onHoverGradient: RadialGradient {
    .radialGradient(
      .init(colors: [.primary.opacity(0.1), .clear]),
      center: .center,
      startRadius: 0,
      endRadius: effectDiameter
    )
  }
  
  var body: some View {
    VStack {
      Image(systemName: direction.icon)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: iconWidth, height: iconWidth)
    }
    .frame(width: frameWidth, alignment: direction.alignment)
    .fillFrame(.vertical)
    .background(alignment: direction.alignment.inverse()) {
      if isHovered {
        Circle()
          .fill(onHoverGradient)
          .transition(.scale)
          .frame(width: effectDiameter, height: effectDiameter)
      }
    }
    .onHover { isOver in
      withAnimation(.easeIn(duration: 0.2)) {
        isHovered = isOver
      }
    }
    .contentShape(Rectangle())
    .onTapGesture(perform: onTap)
  }

  enum Direction: String {
    case forward, backward
    
    var icon: String {
      "chevron.\(rawValue)"
    }
    
    var alignment: Alignment {
      switch self {
      case .forward:
        return .trailing
      case .backward:
        return .leading
      }
    }
  }
}

