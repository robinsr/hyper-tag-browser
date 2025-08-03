// created on 1/20/25 by robinsr

import SwiftUI

/**
 * Designates the view as the content of the modal (Sheet). Only apply to
 * one view per sheet, and only to a container view for the rest of the
 * modal content (title, main, sections, footer, etc)
 *
 * With this modifier, the view receives fills both horizontally and vertically,
 * aligning the content to the top. It wraps the view in a VStack with
 * a frame with minimum width and height set based on the `SheetPresentation`
 * variant found in the environment keyed ``SheetPresentationEnvKey``
 *
 *
 */
private struct ModalContentBodyModifier: ViewModifier {
  var spacing: CGFloat

  init(spacing: CGFloat? = nil) {
    self.spacing = spacing ?? 12
  }

  @Environment(\.sheetPresentation) var style

  func body(content: Content) -> some View {
    VStack(spacing: spacing) {
      content
        .frame(alignment: .top)
    }
    // .frame(minWidth: style.minWidth, minHeight: style.minWidth, alignment: alignment))
    //.fillFrame([.horizontal, .vertical], alignment: .top)
    .withTestBorder(.purple, "modal#body")
  }
}


/**
 * Designates the view as the primary content container within the modal (Sheet).
 *
 * This modifier is used to ensure that the view fills the available space in the sheet
 * not occupied by the non-primary view areas, beign typically the title/header and
 * controls in the footer area.
 *
 * Only one view per sheet should receive the primary designation. With this
 * modifier, the view receives fills both horizontally and vertically, and aligns content
 * (`.top` bu default)
 */
private struct ModalContentMainModifier: ViewModifier {
  var alignment: Alignment = .top
  var padding: EdgeInsets? = nil

  func body(content: Content) -> some View {
    VStack(spacing: 0) {
      content
    }
    .ifLet(padding) { $0.padding($1) }
    .fillFrame(.vertical, alignment: alignment)
    .withTestBorder(.orange, "modal#main")
  }
}


/**
 * Designates the view as the title content within the modal (Sheet).
 *
 * This modifier is used to ensure that the view is styled and positioned
 * appropriately for a title, typically centered at the top of the sheet.
 *
 * Only one view per sheet should receive the title designation. With this
 * modifier, the view receives appropriate styling and padding for a title.
 */
struct ModalContentTitleModifier: ViewModifier {
  var font: Font = StyleClass.dialogTitle.font


  func body(content: Content) -> some View {
    content
      .font(font)
      .centered()
      .padding(.bottom, 6)
      .withTestBorder(.red, "modal#title")
  }
}


/**
 * Designates the view as a section within the modal (Sheet).
 *
 * This modifier is used to ensure that the view is styled and positioned
 * appropriately for a section, typically with a label and padding.
 *
 * Multiple views can receive this designation within a single sheet.
 */
struct ModalContentSectionModifier: ViewModifier {
  var title: String? = nil
  var spacing: CGFloat? = nil

  func body(content: Content) -> some View {
    GroupBox {
      VStack(alignment: .leading, spacing: 12) {
        content
      }
      .padding(.vertical, 18)
      .padding(.horizontal, 12)
    } label: {
      Text(verbatim: title ?? "")
        .visible(title != nil)
    }
    .padding(.vertical, spacing ?? 18)
    .withTestBorder(.mint, "modal#section")
  }
}


/**
  * Designates the view as the footer content within the modal (Sheet).
  *
  * This modifier is used to ensure that the view is positioned at the bottom
  * of the sheet, and fills the available horizontal space.
  *
  * Only one view per sheet should receive the footer designation. With this
  * modifier, the view receives fills horizontally, and aligns content
  * (`.trailing` by default) within the footer area.
 */
private struct ModalContentFooterModifier: ViewModifier {
  var alignment: Alignment = .trailing

  func body(content: Content) -> some View {
    FullWidth(alignment: alignment, spacing: 12) {
      content
    }
    .withTestBorder(.blue, "modal#footer")
  }
}


extension View {

  /// Modifies the view with ``ModalContentTitleModifier``
  func modalContentBody(spacing: CGFloat? = nil) -> some View {
    modifier(ModalContentBodyModifier(spacing: spacing))
  }

  /// Modifies the view with ``ModalContentMainModifier``
  func modalContentMain(alignment: Alignment = .top, padding: EdgeInsets? = nil) -> some View {
    self.modifier(ModalContentMainModifier(alignment: alignment, padding: padding))
  }

  /// Modifies the view with ``ModalContentTitleModifier``
  func modalContentTitle(font: Font = StyleClass.dialogTitle.font) -> some View {
    modifier(ModalContentTitleModifier(font: font))
  }

  /// Modifies the view with ``ModalContentSectionModifier``
  func modalContentSection(_ title: String? = nil, spacing: CGFloat? = nil) -> some View {
    modifier(ModalContentSectionModifier(title: title, spacing: spacing))
  }

  /// Modifies the view with ``ModalContentFooterModifier``
  func modalContentFooter(alignment: Alignment = .trailing) -> some View {
    self.modifier(ModalContentFooterModifier(alignment: alignment))
  }
}
