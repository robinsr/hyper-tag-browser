// created on 6/4/25 by robinsr

import Factory
import SwiftUI

struct TagButtonLongPressViewModifier: ViewModifier {
  private let logger = CustomLogger("TagButtonLongPressMod", level: .debug)

  @Environment(\.dispatcher) var dispatch

  @Binding var isPressing: Bool
  let action: TagMenuAction
  let tag: FilteringTag
  
  
  func longPressCompleteHandler() {
    logger.debug("perform callback")
    
    switch action {
      case .changeDate:
        dispatch(.showSheet(.datePickerSheet(tag: tag)))
      case .copyText:
        dispatch(.copyToClipboard(label: "tag value", value: tag.value))
      case .filterIncluding:
        dispatch(.addFilter(tag, .inclusive))
      case .filterExcluding:
        dispatch(.addFilter(tag, .exclusive))
      case .filterOff:
        dispatch(.removeFilter(tag))
      case .invert:
        dispatch(.invertFilter(tag))
      case .removeAll:
        dispatch(.removeTag(tag, scope: .all))
      case .renameAll:
        dispatch(.showSheet(.renameTagSheet(tag: tag, scope: .all)))
      case .searchFor:
        dispatch(.showSheet(.searchSheet(query: tag.asSearchString)))
      case .relabel(_):
        logger.error("Relabeling not possible on long-press")
      default:
        logger.error("TagMenuAction not configured for long press: \(action.id)")
    }
  }
  
  
  var longPressGesture: some Gesture {
    LongPressGesture(minimumDuration: 1.5)
      .onChanged { _ in
        logger.debug("Long Press Started; setting isPressed=true")
        isPressing = true
      }
      .onEnded { pressed in
        logger.debug("Long Press Ended")
        longPressCompleteHandler()
        
        Task { @MainActor in
          try? await Task.sleep(for: .milliseconds(800))
          logger.debug("setting isPressed=false")
          isPressing = false
        }
      }
  }

  func body(content: Content) -> some View {
    content
      .simultaneousGesture(longPressGesture)
  }
}

extension View {

  /**
   * Adds a LongPressGesture to the View, invoking the `TagMenuAction` action with
   * the supplied `FilteringTag` as context
   */
  func longPressTagAction(
    isPressing: Binding<Bool>,
    action: TagMenuAction,
    referencing tag: FilteringTag) -> some View {
    self.modifier(
      TagButtonLongPressViewModifier(isPressing: isPressing, action: action, tag: tag)
    )
  }
}





//  @State var longPressTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
//
//  func newPressTimer() -> Timer.TimerPublisher {
//    Timer.publish(every: 0.1, on: .main, in: .common)
//  }
//
//  func onPressChangedHandler(_ isPressing: Bool) {
//    logger.emit(.debug, "onLongPressGesture - onChange; isPressing: \(isPressing)")
//
//    self.isPressing = isPressing
//
//    if isPressing {
//      longPressTimer = newPressTimer().autoconnect()
//    } else {
//      longPressTimer.upstream.connect().cancel()
//    }
//  }
