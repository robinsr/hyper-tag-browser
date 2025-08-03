// created on 10/26/24 by robinsr

import Factory
import SwiftUI


/**
 * A ViewModifier that adds keyboard bindings for arrow directional navigation, updating the
 * environmental CursorState viewmodel
 *
 * Also handles dismiss action and selection of the current item in the grid.
 */
struct CursorControlsView: ViewModifier {
  private let logger = EnvContainer.shared.logger("CursorControlsView")
  
  @Injected(\Container.cursorState) var cursor
  
  @Environment(\.modifierKeys) var modState
  @Environment(\.dispatcher) var dispatch
  @Environment(\.page) var currentPage
  
  
  @Environment(\.isTyping) @Binding var isTyping: Bool
  
  typealias Action = CursorState.CursorActions
  
  func getCursorAction(for binding: KeyBinding) -> Action? {
    let mods = modState.eventModifiers
    
    let nextAction: Action? = switch binding {
    case .gridCursorLeft: .leftArrow(mods: mods)
    case .gridCursorRight: .rightArrow(mods: mods)
    case .gridCursorUp: .upArrow(mods: mods)
    case .gridCursorDown: .downArrow(mods: mods)
    case .dismiss: .escape(mods: mods)
    case .gridSelect: .selectCurrent(mods: mods)
    default: nil
    }
    
    logger.emit(.debug.off, "getCursorAction for binding \(binding.description.quoted): \(nextAction?.description ?? "nil")")
    
    return nextAction
  }
  
  func onCursorMove(_ evt: KeyBinding, forPages enabledPages: [Route.Page]) {
    guard !isTyping else {
      logger.emit(.debug, "onCursorMove: \(evt.description.quoted) ignored while typing")
      return
    }
    
    if currentPage.oneOf(enabledPages) == false {
      logger.emit(.debug, "onCursorMove: \(evt.description.quoted) not enabled for current page \(currentPage)")
      return
    }
    
    var result: KeyPress.Result = .ignored
    
    if let next = getCursorAction(for: evt) {
      result = cursor.dispatch(next, from: currentPage)
    }
    
    if result == .ignored && evt == .dismiss {
      dispatch(.dismissRequested)
    }
  }
  
  func body(content: Content) -> some View {
    content
      .buttonShortcut(binding: .gridCursorLeft) {
        onCursorMove(.gridCursorLeft, forPages: .notMain)
      }
      .buttonShortcut(binding: .gridCursorRight) {
        onCursorMove(.gridCursorRight, forPages: .notMain)
      }
      .buttonShortcut(binding: .gridCursorUp) {
        onCursorMove(.gridCursorUp, forPages: .browseOnly)
      }
      .buttonShortcut(binding: .gridCursorDown) {
        onCursorMove(.gridCursorDown, forPages: .browseOnly)
      }
      .buttonShortcut(binding: .gridSelect) {
        onCursorMove(.gridSelect, forPages: .browseOnly)
      }
      .buttonShortcut(binding: .dismiss) {
        onCursorMove(.dismiss, forPages: .browseOnly)
      }
  }
}

extension View {
  
  func withCursorControls() -> some View {
    modifier(CursorControlsView())
  }
}
