// created on 2/21/25 by robinsr

import Foundation
import Percentage
import SwiftUI

@MainActor
protocol SheetPresentable: View {
  static var presentation: SheetPresentation { get }
}

/**
  A struct that defines the presentation of a sheet view

  - Parameters:
    - idealSize: The size that the sheet would like to be presented at
    - padding: The padding that should be applied to the sheet content
    - fitHorizontal: If the sheet should resize to fit the content horizontally
    - fitVertical: If the sheet should resize to fit the content vertically
    - verticalGive: The amount of vertical space the sheet can take up beyond it's ideal size
    - horizontalGive: The amount of horizontal space the sheet can take up beyond it's ideal size
 */
struct SheetPresentation: Sendable, Equatable, CustomDebugStringConvertible {
  let idealSize: CGSize
  let controls: SheetControl
  var widthSizeSet: Set<Size> = []
  var heightSizeSet: Set<Size> = []
  var padding: EdgeInsets = .zero
  
  var state: SheetExpandState = .initial
  
  init(
    idealSize: CGSize,
    controls: SheetControl = .none,
    horizontal: Set<Size> = [],
    vertical: Set<Size> = [],
    padding: EdgeInsets = .zero,
    behavior: SheetExpandState = .initial
  ) {
    self.idealSize = idealSize
    self.controls = controls
    self.widthSizeSet = horizontal
    self.heightSizeSet = vertical
    self.padding = padding
    self.state = behavior
  }

  // Currently the same for all Presentations, but could be configured
  // differently per presentation in the future
  var resizeAnimation: Animation {
    .bouncy(duration: 0.1, extraBounce: 0.05).delay(0.15)
  }

  var isExpanded: Bool { state == .expanded }
  var isCondensed: Bool { state == .initial }

  var fixedHz: Bool { widthSizeSet.contains(.fixed) }
  var fixedVt: Bool { heightSizeSet.contains(.fixed) }
  var hasFixedEdge: Bool { fixedHz || fixedVt }

  // The default on macos is vertical fitted (`.form.fitted(horizontal: false, vertical: true)`)
  var fitHz: Bool { widthSizeSet.contains(.fitted) }
  var fitVt: Bool { heightSizeSet.contains(.fitted) }
  var isFitted: Bool { fitHz || fitVt }

  var stickyHz: Bool { widthSizeSet.contains(.sticky) }
  var stickyVt: Bool { heightSizeSet.contains(.sticky) }
  var isSticky: Bool { stickyHz || stickyVt }


  var minWidth: Double {
    if case .expanded = state {
      return maxWidth
    } else {
      return widthSizeSet.minSize(from: idealSize.width)
    }
  }

  var maxWidth: Double {
    if case .condensed = state {
      return minWidth
    } else {
      return widthSizeSet.maxSize(from: idealSize.width)
    }
  }

  var minHeight: Double {
    if case .expanded = state {
      return maxHeight
    } else {
      return widthSizeSet.minSize(from: idealSize.height)
    }
  }

  var maxHeight: Double {
    if case .condensed = state {
      return minHeight
    } else {
      return widthSizeSet.maxSize(from: idealSize.height)
    }
  }
  

  /// Returns a copy of the sheet presentation with the ideal size set to the maximum width and height
  var expanded: SheetPresentation {
    var copy = self
    copy.state = .expanded
    return copy
  }

  var condensed: SheetPresentation {
    var copy = self
    copy.state = .condensed
    return copy
  }

  struct SheetControl: OptionSet, SetAlgebra {
    var rawValue: Int

    static let close = SheetControl(rawValue: 1 << 0)
    static let expand = SheetControl(rawValue: 1 << 1)

    static let all: SheetControl = [.close, .expand]
    static let noControls: SheetControl = []
    static let none: SheetControl = []
  }

  enum SheetExpandState: Sendable {
    case initial
    case expanded
    case condensed
  }

  static func == (lhs: SheetPresentation, rhs: SheetPresentation) -> Bool {
    lhs.debugDescription == rhs.debugDescription
  }

  var debugDescription: String {
    """
    SheetPresentation(
         width: \(minWidth) (min), \(idealSize.width) (ideal), \(maxWidth) (max)
        height: \(minHeight) (min), \(idealSize.height) (ideal), \(maxHeight) (max)
       padding: \(padding)
      isFitted: \(isFitted), horiz=\(fitHz), vert=\(fitVt)
      isSticky: \(isSticky), horiz=\(stickyHz), vert=\(stickyVt)
         fixed: \(hasFixedEdge), horiz=\(fixedHz), vert=\(fixedVt)
    )
    """
  }
}

extension SheetPresentation : PresentationSizing {
  func proposedSize(
    for subview: PresentationSizingRoot,
    context: PresentationSizingContext
  ) -> ProposedViewSize {
    ProposedViewSize(self.idealSize)
  }
}


struct SheetSizingRange {
  typealias DimensionRangeValues = (from: CGFloat, to: CGFloat)
  typealias Options = Set<SheetPresentation.Size>


  let horizontal: DimensionRangeValues
  let vertical: DimensionRangeValues


  var hzMin: SheetPresentation.Size {
    .min(horizontal.from)
  }
  
  var hzMax: SheetPresentation.Size {
    .max(horizontal.to)
  }
  
  var vertMin: SheetPresentation.Size {
    .min(vertical.from)
  }
  
  var vertMax: SheetPresentation.Size {
    .max(vertical.to)
  }
  
  var hzMid: CGFloat {
    (horizontal.from + horizontal.to) / 2
  }

  var vertMid: CGFloat {
    (vertical.from + vertical.to) / 2
  }

  func hzOtions(adding opts: Options) -> Options {
    opts.union([hzMin, hzMax])
  }
  
  func vertOptions(adding opts: Options) -> Options {
    opts.union([vertMin, vertMax])
  }


  var idealSize: CGSize {
    CGSize(width: hzMid, height: vertMid)
  }


  static let alert = SheetSizingRange(
    horizontal: (from: 300, to: 650),
    vertical: (from: 175, to: 400)
  )
  
  static let modal = SheetSizingRange(
    horizontal: (from: 340, to: 720),
    vertical: (from: 400, to: 920)
  )
  
  static let modalTall = SheetSizingRange(
    horizontal: (from: 480, to: 480),
    vertical: (from: 400, to: 920)
  )
  
  static let full = SheetSizingRange(
    horizontal: (from: 740, to: 1220),
    vertical: (from: 640, to: 980)
  )
}
