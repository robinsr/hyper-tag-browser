// created on 1/12/26 by robinsr

import SwiftUI

struct TagLabel: View {
  
  @Environment(\.windowSize) var windowSize
  
  let filter: AnyFilterable
  let config: TagButtonConfiguration
  let isPressed: Binding<Bool>
  
  init(
    for filter: AnyFilterable,
    isPressed: Binding<Bool> = .constant(false),
    config: TagButtonConfiguration
  ) {
    self.filter = filter
    self.isPressed = isPressed
    self.config = config
  }
  
  init(
    for filter: AnyFilterable,
    isPressed: Binding<Bool> = .constant(false),
    _ config: @escaping () -> TagButtonConfiguration
  ) {
    self.init(for: filter, isPressed: isPressed, config: config())
  }
  
  var tag: FilteringTag { filter.asFilter }
  var count: Int { filter.count }
  
  var btnSize: PillButtonSize {
    windowSize.size.width.isWithinBreakpoint(.small) ? .small : config.size
  }
  
  var labelStyle: some LabelStyle {
    PillLabelStyle(size: btnSize, variant: config.variant, isPressed: isPressed)
  }

  var body: some View {
    Label {
      Text(config.label ?? tag.displayString)
        .lineLimit(1)
        .truncationMode(.tail)
      
      Text(String(count))
        .textScale(.secondary)
        .hidden(config.showCount)

      if config.hasKeyBinding {
        KeyBindingHintView(binding: config.binding!)
          .lineLimit(1)
          .textScale(.secondary)
          .fontWeight(.regular)
          .scaleEffect(0.9)
      }
    } icon: {
      Image(tag.icon)
        .symbolVariant(config.symbol)
        .font(.system(size: 10))
    }
    .labelStyle(labelStyle)
  }
}
