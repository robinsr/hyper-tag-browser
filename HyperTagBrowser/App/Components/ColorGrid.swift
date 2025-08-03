// created on 9/21/24 by robinsr

import SwiftUI
import Factory

struct ColorGridPicker<ColorContainer: ColorOption, Content: View>: View {
  typealias Option = SelectOption<ColorContainer>
  
  @Binding var selected: Option?
  var options: [Option]
  var size: Int = 40
  var spacing: Int = 10
  var label: (Option?) -> (Content)
  
  
  var gridSize: GridItem.Size {
    .adaptive(minimum: CGFloat(size), maximum: CGFloat(size))
  }
  
  var columns: [GridItem] {
    [GridItem(gridSize, spacing: CGFloat(spacing))]
  }

  var body: some View {
    VStack {
      label(selected)
        .padding(.bottom, 5)
      
      LazyVGrid(columns: columns, spacing: 5) {
        ForEach(options, id: \.id) { option in
          ColorOption(option)
        }
      }
    }
  }
  
  func ColorOption(_ opt: Option) -> some View {
    RoundedRectangle(cornerRadius: 4, style: .continuous)
      .fill(Color(opt.value.nsColor))
      .aspectRatio(1, contentMode: .fill)
      .modify(when: opt.value == selected?.value) {
        $0.border(.blue.opacity(0.9), width: 3, cornerRadius: 4)
      }
      .modify(unless: opt.value == selected?.value) {
        $0.border(.blue.opacity(0.3), width: 0.5, cornerRadius: 4)
      }
      .onTapGesture {
        selected = opt
      }
  }
}


struct ColorRect: View {
  let color: Color
  var radius: Double = 2.0
  var showDetails: Bool = false
  
  var colorComponent: ImageColorSet.Component {
    ImageColorSet.Component(color.cgColor ?? .clear)
  }
  
  var brightnessVal: CGFloat {
    colorComponent.luminance
  }
  
  var saturationVal: CGFloat {
    colorComponent.saturation
  }
  
  var combined: CGFloat {
    brightnessVal * saturationVal
  }
  
  var body: some View {
    HStack {
      ZStack(alignment: .center) {
        
        RoundedRectangle(cornerRadius: CGFloat(radius), style: .continuous)
          .fill(color)
          .frame(width: 18, height: 18)
          .border(color.foreground, width: 1, cornerRadius: radius)
        
        Text(verbatim: "tx")
          .font(.caption)
          .foregroundStyle(color.foreground)
      }
      if showDetails {
        HStack {
          Label("\(brightness: brightnessVal)", systemImage: "sun.max.fill")
          Label("\(brightness: saturationVal)", systemImage: "paintbrush")
          Label("\(brightness: combined)", systemImage: "circle.righthalf.filled")
          Text("#\(colorComponent.cgColor.hexString)")
            .styleClass(.code).selectable()
        }
      }
    }
  }
}


struct ColorSchemeRect: View {
  @Injected(\Container.themeProvider) var theme
  
  let scheme: ColorScheme
  
  init(_ scheme: ColorScheme) {
    self.scheme = scheme
  }
  
  var icon: some View {
    let iconColor = scheme == .dark ? "Moonraker" : "Yellow Orange"
    let symbolName = scheme == .dark ? "moon" : "sun.max"
    
    return Image(systemName: symbolName)
      .foregroundStyle(theme.current.color(key: iconColor).asColor)
  }
  
  var skyColor: Color {
    let dayColor = Color.blue.mix(with: Color.white, by: 0.75)
    let nightColor = Color.black
    
    return scheme == .dark ? nightColor : dayColor
  }
  
  var body: some View {
    icon
      .background {
        ColorRect(color: skyColor)
      }
  }
}
