// created on 3/31/25 by robinsr

import SwiftUI


struct MenuSelect<V: Hashable, LabelContent: View> : View {
  typealias Option = SelectOption<V>
  typealias Options = [SelectOption<V>]
  typealias Selectable = SelectableOptions<V>
  
  
  @Binding var selection: V
  var options: Options
  var unselected: String
  var itemLabel: (Option) -> LabelContent
  var presentation: Presentation = .menu
  var onSelection: ((V) -> Void)? = nil
  
  init(
    selection: Binding<V>,
    options: Options,
    unselected: String  = "Make a selection",
    presentation: Presentation = .menu,
    itemLabel: @escaping (Option) -> LabelContent,
    onSelection: ((V) -> Void)? = nil
  ) {
    self._selection = selection
    self.options = options
    self.unselected = unselected
    self.itemLabel = itemLabel
    self.presentation = presentation
    self.onSelection = onSelection
  }
  
  init(
    selection: Binding<V>,
    using selectable: any Selectable.Type,
    unselected: String  = "Make a selection",
    presentation: Presentation = .menu,
    itemLabel: @escaping (Option) -> LabelContent,
    onSelection: ((V) -> Void)? = nil
  ) {
    self._selection = selection
    self.options = selectable.asSelectables
    self.unselected = unselected
    self.itemLabel = itemLabel
    self.presentation = presentation
    self.onSelection = onSelection
  }
  
  var optionsMap: [V: Option] {
    options.reduce(into: [:]) { map, option in
      map[option.value] = option
    }
  }
  
  func optionChecked(_ item: Option) -> String {
    let checked = "✓"
    let unchecked = "\u{00a0}\u{00a0}\u{00a0}"
    
    return selection == item.value ? checked : unchecked
  }
  
  func onOptionSelected(_ option: Option) {
    if let callback = onSelection {
      callback(option.value)
    } else {
      selection = option.value
    }
  }
  
  var body: some View {
    if presentation == .menu {
      MenuPresentation
    } else {
      PickerPresentation
    }
  }
  
  var MenuPresentation: some View {
    Menu {
      ForEach(options, id: \.id) { option in
        Button {
          onOptionSelected(option)
        } label: {
          Text("\(optionChecked(option)) \(option.label)")
        }
      }
    } label: {
      if let selected = optionsMap[selection] {
        itemLabel(selected)
          .styleClass(.controlLabel)
      } else {
        Text(unselected)
          .styleClass(.controlLabel)
      }
    }
    .menuStyle(.inlineDropdown)
  }
  
  var PickerPresentation: some View {
    Picker(selection: $selection, label: Text(unselected)) {
      ForEach(options, id: \.id) { option in
        Text(option.label).tag(option.value)
      }
    }
  }
  
  enum Presentation: String, CaseIterable, Hashable, Sendable {
      /// Default presentation, uses a `Menu` with `Button` items
    case menu
      /// Uses a `Picker` instead of a `Menu`
    case picker
  }
}



#Preview("MenuSelect", traits: .defaultViewModel, .previewSize(.sq340)) {
  @Previewable @State var selectedA: String?
  @Previewable @State var selectedB: String?
  
  VStack {
    MenuSelect(
      selection: $selectedA,
      options: ["red", "green", "blue"].map { .init(value: $0, label: $0) },
      unselected: "Please make chosen",
      itemLabel: { item in
        Text("You chosed: **\(item.label)**")
      })
    
    MenuSelect(
      selection: $selectedB,
      options: ["red", "green", "blue"].map { .init(value: $0, label: $0) }) { val in
        Text("You chosed: **\(describing: val.label)**")
      } onSelection: { val in
        print("Selected: \(describing: val)")
        selectedB = val
      }
  }
  .frame(preset: .sq340)
}

