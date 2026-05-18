// created on 9/7/24 by robinsr

import CustomDump
import Defaults
import Factory
import GRDBQuery
import SwiftUI

// MARK: - TagsPanel (Main View)

struct TagsEditorSheetView: View, SheetPresentable {
  typealias SelectableTag = SelectableItem<FilteringTag>

  static let presentation = SheetPresentation(
    idealSize: .init(width: 720, height: 720),
    controls: .all,
    horizontal: [.fitted, .flexible(20)],
    vertical: [.fitted, .flexible(20)]
  )

  private let logger = EnvContainer.shared.logger("ListEditorView")
  private var clipboard = Container.shared.clipboardService()
  private var theme = Container.shared.themeProvider()

  @Environment(\.dispatcher) var dispatch
  @Environment(\.notify) var notify
  @Environment(\.modifierKeys) var modState
  @Environment(\.sheetControls) var sheetControls
  @Environment(\.expandSheet) var expandSheet

  @State private var focusedItem: ListEditorFocusable = .prefix

  @State private var suggestionsCursorIndex: Int = -1

  @State private var suggestions = SuggestionViewModel()

  @State private var listVM: TagEditorViewModel

  @State private var textField = TextFieldModel(
    initial: "",
    validate: [],
    updateInterval: .milliseconds(90)
  )

  @FocusState var isTextFocused

  @Default(.listEditorSuggestions) var suggestionCount

  let onCompletion: ([FilteringTag]) -> Void
  let onSelection: DispatchFn
  let onExit: () -> Void
  var bgImage: CGImage? = nil

  // MARK: - TagsPanel Init
  init(
    listItems: [FilteringTag],
    onCompletion: @escaping ([FilteringTag]) -> Void,
    onSelection: @escaping DispatchFn = { _ in },
    onExit: @escaping () -> Void,
    backgroundImage: CGImage? = nil
  ) {
    self.listVM = TagEditorViewModel(listItems)
    self.onCompletion = onCompletion
    self.onSelection = onSelection
    self.onExit = onExit
    self.bgImage = backgroundImage
    
    self.suggestions.excludedTags = listItems
    self.suggestions.itemLimit = Defaults[.listEditorSuggestions]
  }

  /// Trigger alternate action when SHIFT
  /// Trigger second alternate action when SHIFT + CTRL
  var keyAlternate: KeyAlternate {
    let secondKeys = KeyCombinations.either([.shift, .command])
    
    if modState.isPressed(.control, with: secondKeys) {
      return .tertiary
    }
    
    if modState.isPressed(secondKeys) {
      return .secondary
    }

    return .primary
  }

  var currentTags: [FilteringTag] {
    listVM.elements.map(\.item)
  }

  var focusedItemText: String {
    if let item = listVM.item(withId: focusedItem.id) {
      return item.item.displayString
    }

    return ""
  }
  
  var activeItem: Bool {
    focusedItem.isItem
  }
  
  var textFieldText: String {
    textField.value
  }
  
  var focusedSuggestion: CountedTagRecord? {
    guard let suggestion = suggestions.items[safe: suggestionsCursorIndex] else {
      return nil
    }
    
    return suggestion
  }
  
  var activeSuggestion: Bool {
    return focusedSuggestion != nil
  }
  
  var suggestionText: String {
    guard let suggestion = focusedSuggestion else { return "" }
    return suggestion.asFilter.displayString
  }


  // MARK: - Body
  var body: some View {
    VStack {

      TopControls
        .padding(EdgeInsets(top: 12, leading: 12, bottom: 4, trailing: 12))
        .onAppear { focusedItem = .prefix }

      SuggestedTagButtons

      Divider()

      ScrollViewReader { scrollVal in
        ScrollView {
          VStack(alignment: .leading, spacing: 0) {
            ProposedCommand
            ListItems
          }
        }
        .onChange(of: focusedItem) {
          scrollVal.scrollTo(focusedItem.id)
        }
      }
    }
    .onChange(of: textFieldText) {
      suggestions.searchText = textFieldText
      suggestions.userDidChangeQuery()
    }
    .buttonShortcut(binding: .listEditorUp, action: keyNavigationUp)
    .buttonShortcut(binding: .listEditorDown, action: keyNavigationDown)
    .buttonShortcut(binding: .dismiss, action: onEscapeKey)
    .buttonShortcut(binding: .copy) {
      onCopyCommand(mods: modState.modifiers)
    }
    .buttonShortcut(binding: .paste) {
      onPasteCommand(mods: modState.modifiers)
    }
    .buttonShortcut(binding: .init("⌘e", named: "Toggle Large Sheet")) {
      expandSheet.wrappedValue.toggle()
    }
    .ifLet(bgImage) { $0
      .background(ListBackground($1))
    }
  }


  var ListItems: some View {
    ForEach(listVM.elements, id: \.id) { listItem in
      ListEditorRowItem(focus: $focusedItem, eq: .itemId(listItem.id)) { _ in
        FullWidthSplit {
          ZStack {
            ListEditorRowSymbol(icon: .itemChecked, color: theme.success)
              .visible(listItem.selected)
            
            ListEditorRowSymbol(icon: .itemCrossed, color: theme.error)
              .hidden(listItem.selected)
          }
          
          Text(listItem.item.displayString)
            .styleClass(.listEditorItem)
        } trailing: {
          Text(listItem.id)
            .font(.caption)
            .italic()
        }
      }
      .id(listItem.id)
    }
  }

  var ProposedCommand: some View {
    ListEditorRowItem(focus: $focusedItem, eq: .prefix) { _ in
      ListEditorRowSymbol(icon: nextCommand.icon)

      Text(nextCommand.label)
        .styleClass(.listEditorItem)
    }
  }

  var TopControls: some View {
    HStack(alignment: .firstTextBaseline) {
      TextField("", text: $textField.rawValue, prompt: Text("Toggle tags or enter new tag"))
        .textFieldStyle(.prominent(icon: .tag))
        .focused($isTextFocused)
        .buttonShortcut(binding: .hzPrevItem, action: selectPrevSuggestion)
        .buttonShortcut(binding: .hzNextItem, action: selectNextSuggestion)

        // Adding alt+arrow shortcuts for selecting suggestions. Macbook only has a
        // left control keys, but it has left and right option keys
        .buttonShortcut(binding: .listEditorLeft, action: selectPrevSuggestion)
        .buttonShortcut(binding: .listEditorRight, action: selectNextSuggestion)

        .onKeyPress(.return, action: onReturnKey)
        .onKeyPress(.tab, action: {
          acceptSuggestion()
          return .handled
        })

      Button(.close.variant(.circle.fill)) {
        closePanel()
      }
      .buttonStyle(.closePanel)
      .hidden(sheetControls.contains(.close))
    }
  }

  var tagButtonConfig: TagButtonConfiguration {
    TagButtonConfiguration(
      counts: .preference,
      onTap: { tag in
        textField.reset(to: tag.value)
        isTextFocused = true
        
        onReturnKey()
      }
    )
  }

  var SuggestedTagButtons: some View {
    VStack {
      HorizontalFlowView {
        ForEach(suggestions.indexed, id: \.0) { index, item in
          TagButton(for: item, config: tagButtonConfig)
            .activateTag(when: index == suggestionsCursorIndex)
        }
      }

      ListControlsHint(selectControl: .tab)
        .italic()
        .scaleEffect(0.8)
        .fillFrame(.horizontal, alignment: .center)
        .hidden(suggestions.isEmpty)
    }
    .padding(.horizontal, 12)
  }

  func ListBackground(_ img: CGImage) -> some View {
    Image(img, scale: 2.0, label: Text(""))
      .resizable()
      .aspectRatio(contentMode: .fill)
      .overlay(Color.black.opacity(0.6))
  }
}


// Handlers for selecting and accepting tag suggestion
extension TagsEditorSheetView {
  func selectPrevSuggestion() {
    guard !suggestions.isEmpty else { return }
    suggestionsCursorIndex = suggestions.items[nullable: suggestionsCursorIndex - 1]
  }

  func selectNextSuggestion() {
    guard !suggestions.isEmpty else { return }
    suggestionsCursorIndex = suggestions.items[nullable: suggestionsCursorIndex + 1]
  }

  func acceptSuggestion() {
    guard activeSuggestion else { return }
    guard let suggestion = suggestions.items[safe: suggestionsCursorIndex] else { return }
    textField.reset(to: suggestion.asFilter.value)
  }
}


extension TagsEditorSheetView {

  /**
   * Determines the command for the next on-enter event
   */
  var nextCommand: EditTagSetAction {
    if textField.isFilled && !activeItem {
      if keyAlternate.isSecondary, let suggestion = focusedSuggestion {
        return .addSuggestion(suggestion)
      }
      
      return .addText(textField.value)
    }
    
    if textField.isFilled && activeItem {
      guard let target = listVM.tag(withId: focusedItem.id) else { return .done }
      
      if keyAlternate.isSecondary, let suggestion = focusedSuggestion {
        return .replaceSuggestion(target, suggestion)
      }
      
      return .replaceText(target, textField.value)
    }
    
    if textField.isEmpty && activeItem {
      guard let target = listVM.tag(withId: focusedItem.id) else { return .done }
      
      if keyAlternate.isSecondary {
        return .filterOn(target)
      }
      
      return .toggle(target)
    }
    
    return .done
  }
}


extension TagsEditorSheetView {
  func closePanel() {
    onExit()
  }

  // MARK: - Keyboard Controls

  func keyNavigationDown() {
    switch focusedItem {
    case .none:
      focusedItem = .prefix

    case .prefix:
      guard let firstTag = listVM.first else { return }
      focusedItem = .itemId(firstTag.id)

    case .itemId(let tagId):
      if listVM.isLast(id: tagId) {
        focusedItem = .prefix
      } else {
        guard let next = listVM.next(afterId: tagId) else { return }
        focusedItem = .itemId(next.id)
      }
    }
  }

  func keyNavigationUp() {
    switch focusedItem {
    case .none:
      guard let lastTag = listVM.last else { return }
      focusedItem = .itemId(lastTag.id)

    case .prefix:
      guard let lastTag = listVM.last else { return }
      focusedItem = .itemId(lastTag.id)

    case .itemId(let tagId):
      if listVM.isFirst(id: tagId) {
        focusedItem = .prefix
      } else {
        guard let prevTag = listVM.previous(beforeId: tagId) else { return }
        focusedItem = .itemId(prevTag.id)
      }
    }
  }

  @discardableResult
  func onReturnKey() -> KeyPress.Result {
    switch nextCommand.type {
    case .addText, .addSuggestion, .replaceText, .replaceSuggestion:
      onAddCommand(nextCommand)
    case .toggle:
      onToggleCommand()
    case .filterOn:
      onSelectCommand()
    case .copyString:
      onCopyCommand(mods: [])
    case .pasteString:
      onPasteCommand(mods: [])
    case .done:
      onDoneCommand()
    default:
      return .ignored
    }

    return .handled
  }

  func onDoneCommand() {
    onCompletion(listVM.elements.filter(\.selected).map(\.item))
  }

  func onEscapeKey() {
    onExit()
  }

  // MARK: - Command Handlers

  func onAddCommand(_ action: EditTagSetAction) {
    switch action {
    case .addText(let text):
      listVM.append(.tag(text))
      textField.reset()
    case .addSuggestion(let suggestion):
      listVM.append(suggestion.asFilter)
    case .replaceText(_, let text):
      if let newItem = listVM.replace(id: focusedItem.id, with: .tag(text)) {
        focusedItem = .itemId(newItem.id)
        textField.reset()
      }
    case .replaceSuggestion(_, let suggestion):
      if let newItem = listVM.replace(id: focusedItem.id, with: suggestion.asFilter) {
        focusedItem = .itemId(newItem.id)
      }
    default:
      break
    }

    suggestionsCursorIndex = -1
  }

  func onToggleCommand() {
    listVM.toggle(id: focusedItem.id)
  }

  func onCopyCommand(mods: EventModifiers = []) {
    dispatch(
      .copyToClipboard(
        label: "tags",
        value: FilteringTagSet(currentTags).asJSON
      ))

    onExit()
  }

  func getPastedItems(from str: String) -> [FilteringTag] {
    guard let data = str.data(using: .utf8) else {
      notify(.warning("Error reading clipboard"))
      return []
    }

    // Try to decode the clipboard as a JSON string. This supports transfering tags with their encoded types
    if let tagSet = try? JSONDecoder().decode(FilteringTagSet.self, from: data) {
      return tagSet.values
    }

    // Fallback to a simple comma-separated list of tags
    return
      str
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .compactMap { FilteringTag(rawValue: $0) }
  }


  func onPasteCommand(mods: EventModifiers = []) {
    guard let clipString = clipboard.readString() else {
      notify(.warning("Error reading clipboard"))
      return
    }

    guard clipString.notEmpty else { return }

    // Attempt to decode the pasted string (either JSON or comma-separated)
    let pastedItems = getPastedItems(from: clipString)

    // If no items were decoded, just append the pasted string to the textfield
    if pastedItems.isEmpty {
      textField.reset(to: textField.value + clipString)
      return
    }

    if mods.isPressed(.shift) {
      // Alternate action is to replace the current list
      listVM.replace(pastedItems)
    } else {
      // Default action is to append the pasted items
      listVM.append(contentsOf: pastedItems)
    }

    focusedItem = .prefix
  }


  func onSelectCommand() {
    guard focusedItem.isItem else { return }

    if let tag = listVM.item(withId: focusedItem.id)?.item {
      onSelection(.addFilter(tag, .inclusive))
    }
  }
}


#Preview("Tags Panel (floating)", traits: .app, .size(.panel)) {
  @Previewable @State var listItems = TestData.fruitTags + TestData.vegetableTags

  TagsEditorSheetView(
    listItems: listItems,
    onCompletion: { val in print(val) },
    onExit: { print("Exited") }
  )
}
