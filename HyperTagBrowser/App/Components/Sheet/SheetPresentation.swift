// created on 2/21/25 by robinsr

import Foundation
import Percentage
import SwiftUI

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
  var idealSize: CGSize
  var controls: SheetControl
  var horizontal: Set<SizingOption> = []
  var vertical: Set<SizingOption> = []
  var behavior: Behavior = .initial

  // Currently the same for all Presentations, but could be configured
  // differently per presentation in the future
  var resizeAnimation: Animation {
    .bouncy(duration: 0.1, extraBounce: 0.05).delay(0.15)
  }

  var isExpanded: Bool { behavior == .expanded }
  var isCondensed: Bool { behavior == .initial }

  var fixedHz: Bool { horizontal.contains(.fixed) }
  var fixedVt: Bool { vertical.contains(.fixed) }
  var hasFixedEdge: Bool { fixedHz || fixedVt }

  // The default on macos is vertical fitted (`.form.fitted(horizontal: false, vertical: true)`)
  var fitHz: Bool { horizontal.contains(.fitted) }
  var fitVt: Bool { vertical.contains(.fitted) }
  var isFitted: Bool { fitHz || fitVt }

  var stickyHz: Bool { horizontal.contains(.sticky) }
  var stickyVt: Bool { vertical.contains(.sticky) }
  var isSticky: Bool { stickyHz || stickyVt }

  var paddingHz: CGFloat { horizontal.pad }
  var paddingVt: CGFloat { vertical.pad }

  var verticalGive: Percentage { vertical.percent }
  var horizontalGive: Percentage { horizontal.percent }


  var minWidth: Double {
    if case .expanded = behavior {
      return maxWidth
    } else {
      return horizontal.min ?? (idealSize.width - horizontalGive.of(idealSize.width))
    }
  }

  var maxWidth: Double {
    if case .condensed = behavior {
      return minWidth
    } else {
      return horizontal.max ?? (idealSize.width + horizontalGive.of(idealSize.width))
    }
  }

  var minHeight: Double {
    if case .expanded = behavior {
      return maxHeight
    } else {
      return vertical.min ?? (idealSize.height - verticalGive.of(idealSize.height))
    }
  }

  var maxHeight: Double {
    if case .condensed = behavior {
      return minHeight
    } else {
      return vertical.max ?? (idealSize.height + verticalGive.of(idealSize.height))
    }
  }
  

  var padding: EdgeInsets {
    EdgeInsets(
      top: vertical.pad,
      leading: horizontal.pad,
      bottom: vertical.pad,
      trailing: horizontal.pad
    )
  }

  /// Returns a copy of the sheet presentation with the ideal size set to the maximum width and height
  var expanded: SheetPresentation {
    var copy = self
    copy.behavior = .expanded
    return copy
  }

  

  var condensed: SheetPresentation {
    var copy = self
    copy.behavior = .condensed
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

  enum Behavior: Sendable {
    case initial
    case expanded
    case condensed
  }

  enum SizingOption: Sendable, Hashable {
    case fixed
    case fitted
    case sticky          // Modifies self to be sticky in the specified dimensions — growing, but not shrinking.
    case flexible(Percentage)
    case min(CGFloat)
    case max(CGFloat)
    case pad(CGFloat)
  }

  static func == (lhs: SheetPresentation, rhs: SheetPresentation) -> Bool {
    lhs.debugDescription == rhs.debugDescription
  }

  var debugDescription: String {
    """
    SheetPresentation(
         width: \(minWidth) (min), \(idealSize.width) (ideal), \(maxWidth) (max)
        height: \(minHeight) (min), \(idealSize.height) (ideal), \(maxHeight) (max)
          give: \(horizontal.percent) (horiz), \(vertical.percent) (vert)
      isFitted: \(isFitted), horiz=\(fitHz), vert=\(fitVt)
      isSticky: \(isSticky), horiz=\(stickyHz), vert=\(stickyVt)
       padding: \(padding), horiz=\(paddingHz), vert=\(paddingVt)
         fixed: \(hasFixedEdge), horiz=\(fixedHz.asNLGValue), vert=\(fixedVt)
    )
    """
  }
}


struct SheetSizingRange {
  typealias DimensionRangeValues = (from: CGFloat, to: CGFloat)
  typealias Options = Set<SheetPresentation.SizingOption>


  let horizontal: DimensionRangeValues
  let vertical: DimensionRangeValues


  var hzMin: SheetPresentation.SizingOption {
    .min(horizontal.from)
  }
  var hzMax: SheetPresentation.SizingOption {
    .max(horizontal.to)
  }
  var vertMin: SheetPresentation.SizingOption {
    .min(vertical.from)
  }
  var vertMax: SheetPresentation.SizingOption {
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


/**
 * Predefined sheet presentations for common use cases.
 *
 * These are designed to be used with the `.sheetPresentation(style:)` view modifier, and provide a
 * consistent sizing and behavior for various types of sheets in the application.
 */
extension SheetPresentation {

  /**
   * Very small, 300x175, intended for single-sentence alerts. Used in:
   *
   * - ``CreateQueueView``
   * - ``NewProfileFormView``
   * - ``SheetView`` (used as deafult)
   */
  static func alert(controls: SheetControl = .close) -> SheetPresentation {
    SheetPresentation(
      idealSize: SheetSizingRange.alert.idealSize,
      controls: controls,
      horizontal: SheetSizingRange.alert.hzOtions(adding: [.fitted, .pad(10)]),
      vertical: SheetSizingRange.alert.vertOptions(adding: [.fitted, .pad(10)]),
    )
  }

  /**
   * Traditional modal size, 320x200 - 520x660
   *
   * Used in:
   *
   * - ``AppSheet`` (used as default)
   * - ``AdjustFilterDateView``
   * - ``ProfileListSheetView``
   * - ``ProfileListSheetView``
   * - ``RenameTagSheetView``
   */
  static func modalSticky(controls: SheetControl = .all) -> SheetPresentation {
    SheetPresentation(
      idealSize: SheetSizingRange.modal.idealSize,
      controls: controls,
      horizontal: SheetSizingRange.modal.hzOtions(adding: [.sticky, .pad(16)]),
      vertical: SheetSizingRange.modal.vertOptions(adding: [.sticky, .pad(16)])
    )
  }

  static func modalFixed(controls: SheetControl = .close) -> SheetPresentation {
    SheetPresentation(
      idealSize: SheetSizingRange.modal.idealSize,
      controls: controls,
      horizontal: SheetSizingRange.modal.hzOtions(adding: [.fixed, .pad(16)]),
      vertical: SheetSizingRange.modal.vertOptions(adding: [.fixed, .pad(16)])
    )
  }

  static func modalFitted(controls: SheetControl = .all) -> SheetPresentation {
    SheetPresentation(
      idealSize: SheetSizingRange.modal.idealSize,
      controls: controls,
      horizontal: SheetSizingRange.modal.hzOtions(adding: [.fitted, .pad(16)]),
      vertical: SheetSizingRange.modal.vertOptions(adding: [.fitted, .pad(16)])
    )
  }

  static func modalTall(controls: SheetControl = .all) -> SheetPresentation {
    SheetPresentation(
      idealSize: SheetSizingRange.modalTall.idealSize,
      controls: controls,
      horizontal: SheetSizingRange.modalTall.hzOtions(adding: [.sticky, .pad(16)]),
      vertical: SheetSizingRange.modalTall.vertOptions(adding: [.sticky, .pad(16)])
    )
  }


  /**
   * # `.infoFixed`, `.infoFitted`, `.infoSticky`
   *
   *Small, 300x200, intended for single-sentence alerts, with a close button. Used in
   *
   * - ``AdjustFilterDateView``
   * - ``GridSpacingControls``
   * - ``ImageDiffSheetView``
   * - ``PhotoGridView`` (for a debug panel subview sheet)
   * - ``ProfileListSheetView`` (for a debug panel subview sheet)
   * - ``VolumeInfoButton`` (for a another debug panel subview)
   * - As the default value for ``SheetPresentationEnvKey``
   * -
   */


  static func infoFixed(controls: SheetControl = .close) -> SheetPresentation {
    SheetPresentation(
      idealSize: SheetSizingRange.alert.idealSize,
      controls: controls,
      horizontal: SheetSizingRange.alert.hzOtions(adding: [.fixed, .pad(16)]),
      vertical: SheetSizingRange.alert.vertOptions(adding: [.fixed, .pad(16)])
    )
  }

  static func infoFitted(controls: SheetControl = .close) -> SheetPresentation {
    SheetPresentation(
      idealSize: SheetSizingRange.alert.idealSize,
      controls: controls,
      horizontal: SheetSizingRange.alert.hzOtions(adding: [.fitted, .pad(16)]),
      vertical: SheetSizingRange.alert.vertOptions(adding: [.fitted, .pad(16)])
    )
  }

  static func infoSticky(controls: SheetControl = .close) -> SheetPresentation {
    SheetPresentation(
      idealSize: SheetSizingRange.alert.idealSize,
      controls: controls,
      horizontal: SheetSizingRange.alert.hzOtions(adding: [.sticky, .pad(16)]),
      vertical: SheetSizingRange.alert.vertOptions(adding: [.sticky, .pad(16)])
    )
  }


  /**
   * Roughly 3/4 screen, large enough for non-trivial UI but not a whole screen. Used in:
   *
   * - ``SearchView``
   */
  static func full(controls: SheetControl = .all) -> SheetPresentation {
    SheetPresentation(
      idealSize: SheetSizingRange.full.idealSize,
      controls: controls,
      horizontal: SheetSizingRange.full.hzOtions(adding: [.fitted, .pad(16)]),
      vertical: SheetSizingRange.full.vertOptions(adding: [.fitted, .pad(16)])
    )
  }
  
  
  static func fullSticky(controls: SheetControl = .all) -> SheetPresentation {
    SheetPresentation(
      idealSize: SheetSizingRange.full.idealSize,
      controls: controls,
      horizontal: SheetSizingRange.full.hzOtions(adding: [.sticky, .pad(16)]),
      vertical: SheetSizingRange.full.vertOptions(adding: [.sticky, .pad(16)])
    )
  }

  /**
   * Short and wide, 500x100, intended for single text input forms. Used in
   *
   * - ``TextFieldSheet``
   */
  static let textfield = SheetPresentation(
    idealSize: CGSize(width: 950, height: 50),
    controls: [.close],
    horizontal: [.fitted, .pad(10), .min(400), .max(1000), .flexible(50%)],
    vertical: [.fitted, .pad(10)]
  )

  /**
   * Sheet config for presenting various code view (JSON, log output, etc). Used in:
   *
   * - ``SearchResultItem`` (as subview to inspect search result JSON)
   * - For all the `.debug_...` cases in ``AppSheet``
   */
  static let code = SheetPresentation.full(controls: .close).expanded
}


extension Set where Element == SheetPresentation.SizingOption {
  /// Returns the total percentage of flexible sizing options in this set.
  var percent: Percentage {
    self.reduce(Percentage.zero) { result, option in
      switch option {
        case .flexible(let pct): result + pct
        default: result
      }
    }
  }

  var min: CGFloat? {
    self.reduce(nil as CGFloat?) { result, option in
      switch option {
        case .min(let min): result.map { Swift.min($0, min) } ?? min
        default: result
      }
    }
  }

  var max: CGFloat? {
    self.reduce(nil as CGFloat?) { result, option in
      switch option {
        case .max(let max): result.map { Swift.max($0, max) } ?? max
        default: result
      }
    }
  }

  var pad: CGFloat {
    self.reduce(0) { result, option in
      switch option {
        case .pad(let pad): result + pad
        default: result
      }
    }
  }
}


extension Percentage: @unchecked @retroactive Sendable {}
