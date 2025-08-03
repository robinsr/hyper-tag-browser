// created on 12/6/24 by robinsr

import SwiftUI
import Factory
import StyledMarkdown


/**
 * A view that highlights specific words in a string.
 */
struct HighlightedTextView : View {
  var str: String
  var emphasize: [String]
  var emStyle: EmphasisStyle = .info
  
  init(_ str: String, emphasize: [String], emStyle: EmphasisStyle = .info) {
    self.str = str
    self.emphasize = emphasize
    self.emStyle = emStyle
  }
  
  var markupString: String {
    emphasize.reduce(str) { result, emp in
      result.replacingMatches(of: emp, options: [.caseInsensitive]) { _, str in
        "^[\(str)](style: '\(emStyle.key)')"
      }
    }
  }
  
  var body: some View {
    Text(markdown: markupString, styleGroup: EmphasisStyle.styles)
  }
}


extension HighlightedTextView {
  enum EmphasisStyle: String, CaseIterable {
    case info
    case danger
    case highlighter
    
    var key: String { rawValue }
    
    var style: Style {
      let theme = Container.shared.themeProvider()
      
      switch self {
      case .info:
        return Style { style in
          style.foregroundColor = theme.info
        }
      case .danger:
        return Style { style in
          style.foregroundColor = theme.danger
        }
      case .highlighter:
        return Style { style in
          style.backgroundColor = Color.yellow
          style.foregroundColor = Color.black
        }
      }
    }
    
    static var base = Style { style in
      style.font = StyleClass.body.font
    }
    
    static var styles: StyleGroup {
      let stylesMap: [String: Style] = allCases.reduce(into: [:]) { result, option in
        result[option.key] = option.style
      }
      
      return StyleGroup(base: Self.base, stylesMap)
    }
  }
}


#Preview("", traits: .previewSize(.sq520.taller)) {
  ScrollView {
    VStack(alignment: .leading, spacing: 2) {
      ForEach(HighlightedTextView.EmphasisStyle.allCases, id: \.self) { style in
        Text(.init("Style: **\(style.rawValue)**"))
        
        HighlightedTextView(TestData.LOREM, emphasize: TestData.LOREM_MATCH, emStyle: style)
          .fixedSize()
        
        Divider()
      }
      
      ForEach(TestData.LOREM_NO_MATCH, id: \.self) { emphasize in
        Text("Input: \(emphasize)")
        
        HighlightedTextView(TestData.LOREM, emphasize: emphasize, emStyle: .highlighter)
          .fixedSize()
        
        Divider()
      }
    }
    .padding()
  }
  .frame(preset: .sq520.taller)
}
