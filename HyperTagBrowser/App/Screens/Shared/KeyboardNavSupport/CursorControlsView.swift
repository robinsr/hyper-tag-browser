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
  private let logLevel = EnvContainer.shared.logLevel("off")
  
  @Injected(\Container.cursorState) var cursor
  
  @Environment(\.modifierKeys) var modState
  @Environment(\.dispatcher) var dispatch
  @Environment(\.route) var route
  @Environment(AppViewModel.self) var appVM
  
  
  @Environment(\.isTyping) @Binding var isTyping: Bool
  
  typealias Action = CursorState.CursorActions
  
  func getCursorAction(for binding: KeyBinding) -> Action? {
    let mods = modState.modifiers
    
    let nextAction: Action? = switch binding {
    case .gridCursorLeft: .leftArrow(mods: mods)
    case .gridCursorRight: .rightArrow(mods: mods)
    case .gridCursorUp: .upArrow(mods: mods)
    case .gridCursorDown: .downArrow(mods: mods)
    case .dismiss: .escape(mods: mods)
    case .gridSelect: .selectCurrent(mods: mods)
    default: nil
    }
    
    logger.emit(logLevel, "getCursorAction for binding \(binding.description.quoted): \(nextAction?.description ?? "nil")")
    
    return nextAction
  }
  
  func onCursorMove(_ binding: KeyBinding, forPages enabledPages: [Route.Page]) {
    
    // NOTE: @Environment(\.page) and @Environment(\.route) are not being updated accurately. Must use reference
    //       to AppViewModel directly here. TODO: debug stale values from \.page and \.route
    let currentPage: Route.Page = appVM.currentPage
    
    logger.emit(logLevel, "onCursorMove: \(describing: binding) for pages \(enabledPages), on page \(currentPage)")
    
    guard !isTyping else {
      logger.emit(logLevel, "onCursorMove: \(describing: binding) ignored while typing")
      return
    }
    
    if currentPage.oneOf(enabledPages) == false {
      logger.emit(logLevel, "onCursorMove: \(describing: binding) not enabled for current page \(currentPage)")
      return
    }
    
    if let next = getCursorAction(for: binding) {
      let result = cursor.dispatch(next, from: currentPage)
      
      logger.emit(logLevel, "Result of cursor dispatch of \(next): \(result)")
      
      if result == .handled {
        return
      }
    }
    
    if binding == .dismiss {
      logger.emit(logLevel, "onCursorMove: .dismiss triggered")
      dispatch(.dismissRequested)
      return
    }
    
    logger.emit(.warning, "KeyBinding unhandled by CursorState: \(describing: binding)")
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
        onCursorMove(.dismiss, forPages: .all)
      }
  }
}

extension View {
  
  func withCursorControls() -> some View {
    modifier(CursorControlsView())
  }
}
