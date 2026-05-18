// created on 10/26/24 by robinsr

import Factory
import SwiftUI


struct TagButton: View {
  
  private let logger = CustomLogger("TagButton", level: .debug)

  @Environment(\.isPresented) var isPresented
  @Environment(\.isFocused) var isFocused
  @Environment(\.dispatcher) var dispatch

  let filter: AnyFilterable
  let config: TagButtonConfiguration

  init(for filter: AnyFilterable, config: TagButtonConfiguration) {
    self.filter = filter
    self.config = config
  }
  
  init(for filter: AnyFilterable, _ config: @escaping () -> TagButtonConfiguration) {
    self.init(for: filter, config: config())
  }

  @State var isPressing = false
  @FocusState var isActiveFocus: Bool
  
  var tag: FilteringTag { filter.asFilter }

  func onTapGesture() {
    if !isPressing {
      config.onTap(tag)
    }
  }
  
  func onLongPressComplete() {
    logger.debug("Long Press performing callback")
    config.onLongPress?(tag)
  }
  
  var tapGesture: some Gesture {
    TapGesture()
      .onEnded {
        
      }
  }
  
  @GestureState var isLongPressing = false
  
  var longPressGesture: some Gesture {
    LongPressGesture(minimumDuration: 0.45)
      .updating($isLongPressing) { cur, prev, _ in
        logger.debug("Long Press Updated; setting isPressing=true")
        isPressing = true
        prev = cur
      }
      .onEnded { pressed in
        logger.debug("Long Press Ended; setting isPressing=false")
        isPressing = false
        onLongPressComplete()
      }
  }
  
  var combinedGesture: some Gesture {
    tapGesture.exclusively(before: longPressGesture)
  }
  
  var body: some View {
    TagLabel(for: filter, isPressed: $isPressing, config: config)
      
      // Context Menu
      .modify(when: config.hasMenu) { $0
        .contextMenu { BtnContextMenu }
      }
      
      // Keyboard shortcut
      .modify(when: config.hasKeyBinding) { $0
        .buttonShortcut(binding: config.binding!, action: onTapGesture)
      }
    
      // System drag & drop payload
      .modify(when: config.draggable) { $0
        .draggable(filteringTag: tag)
      }
      
      // Tap - least invasive
      .modify(when: config.hasTap) { $0
        .onTapGesture {
          logger.debug("TapGesture ended")
          onTapGesture()
        }
      }
      
      // Long press — run alongside tap (shouldn't steal it)
      .modify(when: config.hasLongPress) { $0
        .gesture(longPressGesture)
      }
    
      // Accessibility: if it behaves like a control, mark it as such
      .modify(when: config.hasTap || config.hasLongPress || config.hasMenu) { $0
        .accessibilityAddTraits(.isButton)
      }
  }

  var BtnContextMenu: some View {
    ContentTagContextMenu(
      for: tag,
      actions: config.buttons,
      onSelection: config.onMenuItem
    )
  }
}


#Preview(traits: .defaultViewModel, .fixed(300, 400)) {
  @Previewable @State var tags: [FilteringTag] = TestData.fruitTags

  HorizontalFlowView {
    ForEach(tags.indexed, id: \.1.id) { index, tag in
      TagButton(
        for: tag,
        config: .init(
          size: index % 3 == 0 ? .large : .small,
          variant: index % 2 == 0 ? .primary : .secondary,
          menu: .tagMenu(when: .taggingContent),
          onMenuItem: { action in
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
