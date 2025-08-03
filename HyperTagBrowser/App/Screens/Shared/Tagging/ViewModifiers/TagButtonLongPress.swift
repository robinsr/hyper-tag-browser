// created on 6/4/25 by robinsr

import Factory
import SwiftUI

struct TagButtonLongPressViewModifier: ViewModifier {
  private let logger = EnvContainer.shared.logger("TagButtonLongPressMod")

  @Environment(\.dispatcher) var dispatch

  @Binding var isPressing: Bool
  let action: TagMenuAction
  let tag: FilteringTag
  
  
  func longPressCompleteHandler() {
    logger.emit(.debug, "onLongPressGesture - perform callback")
    
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
      case .relabel(.whenAppliedAsContentTag),
        .relabel(.whenAppliedAsQueryFilter),
        .relabel(.whenSuggestedAsContentTag),
        .relabel(.whenSuggestedAsQueryFilter):
        logger.emit(.error, "Relabeling not possible on long-press")
      default:
        logger.emit(.error, "TagMenuAction not configured for long press: \(action.id)")
    }
  }

  func body(content: Content) -> some View {
    content
      .simultaneousGesture(
        LongPressGesture(minimumDuration: 1.5).onChanged { _ in
          logger.emit(.debug, "onLongPressGesture - Long Press Started")
          isPressing = true
        }
        .onEnded { pressed in
          logger.emit(.debug, "onLongPressGesture - Long Press Ended")
          longPressCompleteHandler()
          
          DispatchQueue.main.asyncAfter(.milliseconds(800)) {
            logger.emit(.debug, "onLongPressGesture - setting isPressed=false")
            isPressing = false
          }
        }
      )
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
