// created on 11/29/25 by robinsr

import Percentage
import SwiftUI

/**
 * Predefined sheet presentations for common use cases.
 *
 * These are designed to be used with the `.sheetPresentation(style:)` view modifier, and provide a
 * consistent sizing and behavior for various types of sheets in the application.
 */
extension SheetPresentation {
  
  static func fixed(width: CGFloat, height: CGFloat, controls: SheetControl = .none) -> SheetPresentation {
    SheetPresentation(
      idealSize: CGSize(width: width, height: height),
      controls: controls,
      horizontal: [.fixed],
      vertical: [.fixed],
      padding: EdgeInsets.fromEdges(10, 10, 10, 10)
    )
  }

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
      horizontal: SheetSizingRange.alert.hzOtions(adding: [.fitted]),
      vertical: SheetSizingRange.alert.vertOptions(adding: [.fitted]),
      padding: EdgeInsets.fromEdges(10, 10, 10, 10),
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
      horizontal: SheetSizingRange.modal.hzOtions(adding: [.sticky]),
      vertical: SheetSizingRange.modal.vertOptions(adding: [.sticky]),
      padding: EdgeInsets.fromEdges(16, 16, 16, 16)
    )
  }

  static func modalFixed(controls: SheetControl = .close) -> SheetPresentation {
    SheetPresentation(
      idealSize: SheetSizingRange.modal.idealSize,
      controls: controls,
      horizontal: SheetSizingRange.modal.hzOtions(adding: [.fixed]),
      vertical: SheetSizingRange.modal.vertOptions(adding: [.fixed]),
      padding: EdgeInsets.fromEdges(16, 16, 16, 16)
    )
  }

  static func modalFitted(controls: SheetControl = .all) -> SheetPresentation {
    SheetPresentation(
      idealSize: SheetSizingRange.modal.idealSize,
      controls: controls,
      horizontal: SheetSizingRange.modal.hzOtions(adding: [.fitted]),
      vertical: SheetSizingRange.modal.vertOptions(adding: [.fitted]),
      padding: EdgeInsets.fromEdges(16, 16, 16, 16)
    )
  }

  static func modalTall(controls: SheetControl = .all) -> SheetPresentation {
    SheetPresentation(
      idealSize: SheetSizingRange.modalTall.idealSize,
      controls: controls,
      horizontal: SheetSizingRange.modalTall.hzOtions(adding: [.sticky]),
      vertical: SheetSizingRange.modalTall.vertOptions(adding: [.sticky]),
      padding: EdgeInsets.fromEdges(16, 16, 16, 16)
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
      horizontal: SheetSizingRange.alert.hzOtions(adding: [.fixed]),
      vertical: SheetSizingRange.alert.vertOptions(adding: [.fixed]),
      padding: EdgeInsets.fromEdges(16, 16, 16, 16),
    )
  }

  static func infoFitted(controls: SheetControl = .close) -> SheetPresentation {
    SheetPresentation(
      idealSize: SheetSizingRange.alert.idealSize,
      controls: controls,
      horizontal: SheetSizingRange.alert.hzOtions(adding: [.fitted]),
      vertical: SheetSizingRange.alert.vertOptions(adding: [.fitted]),
      padding: EdgeInsets.fromEdges(16, 16, 16, 16),
    )
  }

  static func infoSticky(controls: SheetControl = .close) -> SheetPresentation {
    SheetPresentation(
      idealSize: SheetSizingRange.alert.idealSize,
      controls: controls,
      horizontal: SheetSizingRange.alert.hzOtions(adding: [.sticky]),
      vertical: SheetSizingRange.alert.vertOptions(adding: [.sticky]),
      padding: EdgeInsets.fromEdges(16, 16, 16, 16),
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
      horizontal: SheetSizingRange.full.hzOtions(adding: [.fitted]),
      vertical: SheetSizingRange.full.vertOptions(adding: [.fitted]),
      padding: EdgeInsets.fromEdges(0, 16, 16, 16),
    )
  }
  
  
  static func fullSticky(controls: SheetControl = .all) -> SheetPresentation {
    SheetPresentation(
      idealSize: SheetSizingRange.full.idealSize,
      controls: controls,
      horizontal: SheetSizingRange.full.hzOtions(adding: [.sticky]),
      vertical: SheetSizingRange.full.vertOptions(adding: [.sticky]),
      padding: EdgeInsets.fromEdges(16, 16, 16, 16),
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
    horizontal: [.fitted, .min(400), .max(1000), .flexible(50%)],
    vertical: [.fixed],
    padding: EdgeInsets.fromEdges(10, 10, 10, 10),
  )
}
