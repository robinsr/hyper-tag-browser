// created on 5/9/25 by robinsr

import Factory
import SwiftUI


/**
 * Adjusts the size of the preview frame to the specified size, and sets the window size observer to match
 * so that any views that depend on the window size can adjust accordingly.
 */
struct PresetSizePreviewModifier: PreviewModifier {
  typealias Context = CGSize
  
  @Injected(\.windowObserver) var windowObserver: WindowSizeObserver
  
  let size: Context
  
  static func makeSharedContext() async throws -> Context {
    CGSize(width: 520, height: 480) // Default size for previews
  }
  
  func body(content: Content, context: Context) -> some View {
    windowObserver.size = CGSize(width: size.width, height: size.height)
    
    return content
      .frame(width: size.width, height: size.height)
      .environment(\.windowSize, windowObserver)
  }
  
  struct PresetSize {
    var width: CGFloat
    var height: CGFloat
    
    var cgSize: CGSize {
      CGSize(width: width, height: height)
    }
    
    var taller: Self {
      self.taller(by: 1.7)
    }
    
    func taller(by factor: CGFloat) -> Self {
      PresetSize(width: width, height: height * factor)
    }
    
    var wider: Self {
      self.wider(by: 1.7)
    }
    
    func wider(by factor: CGFloat) -> Self {
      PresetSize(width: width * factor, height: height)
    }
    
    func scaled(by factor: CGFloat) -> Self {
      PresetSize(width: width * factor, height: height * factor)
    }
    
    static func square(_ size: CGFloat, ratio aspectRatio: CGFloat = 1) -> Self {
      // Applies the aspect ration such that the larger dimensions is no greater than `size`
      let sq = CGSize(width: size, height: size)
        .aspectFit(to: CGSize(width: aspectRatio, height: 1))
      
      return PresetSize(width: sq.width, height: sq.height)
    }
    
    static let superWide: CGFloat = (Constants.smallScreenThreshold * 2) + 20
    
    static let sq200 = PresetSize.square(200, ratio: 1.0) // 200x180
    static let sq340 = PresetSize.square(340, ratio: 1.0) // 300x270
    static let sq520 = PresetSize.square(520, ratio: 1.0) // 440x396
    
    static let wide = PresetSize.square(260, ratio: 2.5)
//    static let xwide = PresetSize.wide.wider(by: 1.5)
//    static let xxwide = PresetSize.wide.wider(by: 2.0)
    
    static let prefs = PresetSize.sq340.taller(by: 2.2)
    static let panel = PresetSize.sq520.taller(by: 0.8)
    static let inspector = PresetSize.sq340.taller(by: 2.2)
    
    static let dialog = PresetSize.sq340.wider(by: 0.75)
  }
}


extension PreviewTrait where T == Preview.ViewTraits {
  @MainActor
  static func previewSize(_ size: PresetSizePreviewModifier.PresetSize) -> Self {
    self.modifier(PresetSizePreviewModifier(size: size.cgSize))
  }
}


extension View {
  func frame(preset: PresetSizePreviewModifier.PresetSize) -> some View {
    self.frame(width: preset.width, height: preset.height)
  }
}
