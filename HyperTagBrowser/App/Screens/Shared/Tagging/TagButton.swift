// created on 10/26/24 by robinsr

import Factory
import SwiftUI

/**
 A button pre-configured for a ``FilteringTag``

 - Parameter tag: The ``FilteringTag`` to display
 - Parameter size: The ``PillButtonSize`` size of the button
 - Parameter variant: The ``PillButtonVariant`` variant of the button
 - Parameter label: An optional label to display instead of the tag's `value`
 - Parameter menus: A set of menu options ``ContentTagContextMenu/MenuSections`` sections to display in the context menu. Or:
 - Parameter ctxActions: A set of ``ContentTagContextMenu/Component`` components to display in the context menu
 - Parameter dispatch: The function to call when an action is selected
 - Parameter action: The function to call when the button is tapped

 The most common pattern in this app is the TagButton, and for the most part
 there is little variation between them. The general requirements are:

 - Displays the tag's `value` (with the option to override with a label
 - Displays the tag's icon (from ``FilteringTag/icon``)
 - Can be either ``PillButtonSize/small`` or ``PillButtonSize/large``
 - Has a context menu, configurable with some set of ``ContentTagContextMenu/Component``
  components, which when selected will pass the action to the `dispatch` function
  so that the action can be handled by the parent view
 - Has a *primary action* that is performed when tapped, and when the return key is pressed

 Some TODOs left:

 - Prevents the keyboard controls from changing the underlying view when a button is focused

 */
struct TagButton: View {
  private let logger = EnvContainer.shared.logger("TagButton")

  @Environment(\.windowSize) var windowSize
  @Environment(\.dispatcher) var dispatch

  let tag: FilteringTag
  let config: TagButtonConfiguration

  init(for tag: FilteringTag, config: TagButtonConfiguration) {
    self.tag = tag
    self.config = config
  }

  @State var isPressing = false
  @FocusState var isActiveFocus: Bool

  func onButtonTap() {
    config.onTap(tag)
  }


  var body: some View {
    Button {
      logger.emit(.debug, "TagButton - Button action, isPressing=\(isPressing)")
      
      if !isPressing {
        config.onTap(tag)
      }
    } label: {
      config.label(forTag: tag)
    }
    .buttonStyle(
      config.buttonStyle(forWindowSize: windowSize.size)
    )
    .modify(when: config.contextMenuConfig != .noMenu) {
      $0.contextMenu { BtnContextMenu }
    }
    .ifLet(config.keyConfig.keyShortcut) {
      $0.keyboardShortcut($1.keyboardShortcut)
    }
    .longPressTagAction(
      isPressing: $isPressing, action: config.longPressAction, referencing: tag
    )
    .simultaneousGesture(
      TapGesture(count: 2).onEnded {
        logger.emit(.debug, "TagButton - Double Tap")
        // TODO: Support TagButton Double Tap action. Scaffolding left here for now.
      }.exclusively(
        before: TapGesture(count: 1).onEnded {
          logger.emit(.debug, "TagButton - Single Tap")
          config.onTap(tag)
        })
    )
  }

  var BtnContextMenu: some View {
    ContentTagContextMenu(
      tag: tag,
      actions: config.contextMenuConfig.buttons,
      onSelection: config.contextMenuDispatch
    )
  }

}

struct TagLabel: View {
  var tag: FilteringTag
  var label: Text? = nil

  var tagBtnConfig: TagButtonConfiguration {
    .noopButton(
      size: .small,
      variant: .primary(.inclusive)
    )
  }

  var body: some View {
    tagBtnConfig.label(forTag: tag)
      .labelStyle(
        PillLabelStyle(
          size: .small,
          variant: .primary(.inclusive),
          isPressed: false
        ))
  }
}

#Preview(traits: .defaultViewModel, .fixedLayout(width: 300, height: 400)) {
  @Previewable @Environment(AppViewModel.self) var appVM

  @Previewable @State var tags: [FilteringTag] = TestData.fruitTags

  HorizontalFlowView {
    TagLabel(tag: .tag("Banana"), label: Text("I'm a banana"))

    ForEach(tags.indexed, id: \.1.id) { index, tag in
      TagButton(
        for: tag,
        config: .init(
          size: index % 3 == 0 ? .large : .small,
          variant: index % 2 == 0 ? .primary : .secondary,
          contextMenuConfig: .sections([.refining, .editable, .searchable]),
          contextMenuDispatch: { action in
            print("Dispatching action: \(action)")
          },
          onTap: { tag in
            print("Adding tag: \(tag)")
          }
        )
      )
    }
  }
  .preferredColorScheme(.dark)
}


//  init(
//    _ tag: FilteringTag,
//    config: TagButtonConfiguration,
//    active: @escaping @autoclosure () -> Bool,
//    dispatch: @escaping DispatchFn = { _ in },
//    action: @escaping (FilteringTag) -> Void
//  ) {
//    self.tag = tag
//
//    var configCopy = config
//    configCopy.contextMenuDispatch = dispatch
//    configCopy.onTap = action
//    self.config = configCopy
//  }
