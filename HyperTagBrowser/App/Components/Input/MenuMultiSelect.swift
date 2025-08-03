// created on 5/24/25 by robinsr

import SwiftUI


struct MenuMultiSelect<V: Hashable, LabelContent: View> : View {
  typealias Option = SelectOption<V>
  typealias Options = [SelectOption<V>]
  typealias Selectable = SelectableOptions<V>
  
  typealias Items = [V]
  typealias Selection = Binding<Items>
  
  enum Presentation {
    /**
     Default presentation, uses a `Menu` with `Button` items
     */
    case menu
    /**
     Uses a `Picker` instead of a `Menu`
     */
    case picker
  }
  
  @Binding var selection: Items
  var options: Options
  var noSelectionsLabel: String
  var itemLabel: (Option) -> LabelContent
  var presentation: Presentation = .menu
  var onSelection: ((Items) -> Void)? = nil
  
  init(
    selection: Selection,
    options: Options,
    defaultLabel: String = "Make a selection",
    presentation: Presentation = .menu,
    itemLabel: @escaping (Option) -> LabelContent,
    onSelection: ((Items) -> Void)? = nil
  ) {
    self._selection = selection
    self.options = options
    self.noSelectionsLabel = defaultLabel
    self.itemLabel = itemLabel
    self.presentation = presentation
    self.onSelection = onSelection
  }
  
  init(
    selection: Selection,
    using selectable: any Selectable.Type,
    defaultLabel: String  = "Make a selection",
    presentation: Presentation = .menu,
    itemLabel: @escaping (Option) -> LabelContent,
    onSelection: ((Items) -> Void)? = nil
  ) {
    self._selection = selection
    self.options = selectable.asSelectables
    self.noSelectionsLabel = defaultLabel
    self.itemLabel = itemLabel
    self.presentation = presentation
    self.onSelection = onSelection
  }
  
  /// A map of the option values to their corresponding `Option` instances.
  /// This is useful for quickly accessing an Option when only the value is known.
  var optionsMap: [V: Option] {
    options.reduce(into: [:]) { map, option in
      map[option.value] = option
    }
  }
  
  func optionChecked(_ item: Option) -> String {
    let checked = "✓"
    let unchecked = "\u{00a0}\u{00a0}\u{00a0}"
    
    return selection.contains(item.value) ? checked : unchecked
  }
  
  func onOptionSelected(_ option: Option) {
    var selectedSet = Set(selection)
    selectedSet.toggleExistence(option.value)
    let selectedValues = selectedSet.asArray
    
    if let onSelectFn = onSelection {
      onSelectFn(selectedValues)
      return
    } else {
      // If no callback is provided, update the selection binding directly
      selection = selectedValues
    }
  }
  
  var body: some View {
    switch presentation {
    case .menu:
      MenuPresentation
    case .picker:
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
      if selection.isEmpty {
        Text(noSelectionsLabel)
          .styleClass(.controlLabel)
      } else {
        Text(selection.map { optionsMap[$0]?.label ?? "Unknown" }.joined(separator: ", "))
          .styleClass(.controlLabel)
      }
    }
    .menuStyle(.inlineDropdown)
  }
  
  var PickerPresentation: some View {
    Picker(selection: $selection, label: Text(noSelectionsLabel)) {
      ForEach(options, id: \.id) { option in
        Text(option.label)
          .tag(option.id)
      }
    }
  }
}
