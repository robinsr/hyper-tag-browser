// created on 9/7/24 by robinsr

import CustomDump
import Defaults
import Factory
import GRDBQuery
import IssueReporting
import OSLog
import SwiftUI



// MARK: - TagsPanel (Main View)

struct ListEditorSheetView: View, SheetPresentable {
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
  
  @State private var focusedItem: ListEditorFocusable = .prefix
  
  @State private var suggestionsCursorIndex: Int = -1
  
  @State private var suggestions: [(Int, TagSuggestions.Suggestion)] = []
  
  @State private var listVM: ListEditorViewModel<FilteringTag>
  
  @State private var textToAdd = TextFieldModel(
    initial: "",
    validate: [],
    updateInterval: .milliseconds(90)
  )

  @FocusState var isTextFocused
  
  @Default(.listEditorSuggestions) var suggestionCount
  
  let onCompletion: ([FilteringTag]) -> ()
  let onSelection: DispatchFn
  let onExit: () -> ()
  var bgImage: CGImage? = nil
  
  // MARK: - TagsPanel Init
  init(
    listItems: [FilteringTag],
    onCompletion: @escaping ([FilteringTag]) -> (),
    onSelection: @escaping DispatchFn = { _ in },
    onExit: @escaping  () -> (),
    backgroundImage: CGImage? = nil
  ) {
    self.listVM = ListEditorViewModel(listItems)
    self.onCompletion = onCompletion
    self.onSelection = onSelection
    self.onExit = onExit
    self.bgImage = backgroundImage
  }
  
  var currentTags: [FilteringTag] {
    listVM.elements.map(\.item)
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
            TopCommandListItem
            ListItems
          }
        }
        .onChange(of: focusedItem) {
          scrollVal.scrollTo(focusedItem.id)
        }
      }
    }
    .buttonShortcut(binding: .listEditorUp, action: keyNavigationUp)
    .buttonShortcut(binding: .listEditorDown, action: keyNavigationDown)
    .buttonShortcut(binding: .dismiss, action: onEscapeKey)
    .buttonShortcut(binding: .copy) {
      onCopyCommand(mods: modState.eventModifiers)
    }
    .buttonShortcut(binding: .paste) {
      onPasteCommand(mods: modState.eventModifiers)
    }
    .ifLet(bgImage) { $0
      .background(ListBackground($1))
    }
  }
  
  
  var ListItems: some View {
    ForEach(listVM.elements, id: \.id) { listItem in
      ListEditorRowItem(focus: $focusedItem, eq: .itemId(listItem.id)) { _ in
        ZStack {
          ListEditorRowSymbol(icon: .itemChecked, color: theme.success)
            .visible(listItem.selected)
          
          ListEditorRowSymbol(icon: .itemCrossed, color: theme.error)
            .hidden(listItem.selected)
        }
        
        Text(listItem.item.description)
          .styleClass(.listEditorItem)
      }
      .id(listItem.id)
    }
  }
  
  var TopCommandListItem: some View {
    ListEditorRowItem(focus: $focusedItem, eq: .prefix) { _ in
      ListEditorRowSymbol(icon: nextCommand.icon)
      
      Text(nextCommand.rawValue)
        .styleClass(.listEditorItem)
    }
  }
  
  var TopControls: some View {
    HStack(alignment: .firstTextBaseline) {
      TextField("", text: $textToAdd.rawValue, prompt: Text("Toggle tags or enter new tag"))
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
      size: .small,
      onTap: { tag in
        textToAdd.reset(to: tag.value)
        isTextFocused = true
        let _ = onReturnKey()
      }
    )
  }
  
  var SuggestedTagButtons: some View {
    VStack {
      HorizontalFlowView {
        TagSuggestions(
          searchText: $textToAdd.value,
          excludedTags: .constant(currentTags),
          bindTo: $suggestions,
          numSuggestions: $suggestionCount,
          searchDomains: [.attribution, .descriptive]
        ) { index, item in
          TagButton(for: item.asFilter, config: tagButtonConfig)
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
extension ListEditorSheetView {
  func selectPrevSuggestion() {
    guard !suggestions.isEmpty else { return }
    suggestionsCursorIndex = suggestions[nullable: suggestionsCursorIndex - 1]
  }
  
  func selectNextSuggestion() {
    guard !suggestions.isEmpty else { return }
    suggestionsCursorIndex = suggestions[nullable: suggestionsCursorIndex + 1]
  }
  
  func acceptSuggestion() {
    guard !suggestions.isEmpty else { return }
    guard let suggestion = suggestions[safe: suggestionsCursorIndex] else { return }
    textToAdd.reset(to: suggestion.1.asFilter.value)
  }
}


extension ListEditorSheetView {
  var shiftKey: KeyStatus { .fromBool(modState.modifierFlags.contains(.shift)) }
  var ctrlKey: KeyStatus { .fromBool(modState.modifierFlags.contains(.control)) }
  
  /// Alternate action is indicated by holding shift
  var secondaryActionIndicated: Bool {
    shiftKey == .held && ctrlKey == .released
  }
  
  var tertiaryActionIndicated: Bool {
    shiftKey == .held && ctrlKey == .held
  }

  /// Computes the value of of the next command to run if the user
  /// were to press return in any moment. Factors include:
  var nextCommand: ListEditorActions {
    if textToAdd.isEmpty {
      if secondaryActionIndicated { return .filterOn } // { return .copy } // Using cmd-c for copy
      if tertiaryActionIndicated { return .none } // { return .paste } // Using cmd-v for paste
      if focusedItem.isItem { return .toggle }
      return .done
    }
    
    if !textToAdd.isEmpty && focusedItem.isItem {
      return secondaryActionIndicated ? .insert : .replace
    }
    
    if !textToAdd.isEmpty {
      return secondaryActionIndicated ? .prepend : .append
    }
    
    return .none
  }
}


extension ListEditorSheetView {
  func closePanel() {
    onExit()
  }

  // MARK: - Keyboard Controls

  func keyNavigationDown() {
    switch focusedItem {

    case .none:
      focusedItem = .prefix

    case .prefix:
      if let firstTag = listVM.first {
        focusedItem = .itemId(firstTag.id)
      }

    case .itemId(let tagId):
      if listVM.isLast(id: tagId) {
        focusedItem = .prefix
      } else {
        if let next = listVM.next(afterId: tagId) {
          focusedItem = .itemId(next.id)
        }
      }
    }
  }

  func keyNavigationUp() {
    switch focusedItem {
      
    case .none:
      if let lastTag = listVM.last {
        focusedItem = .itemId(lastTag.id)
      }

    case .prefix:
      if let lastTag = listVM.last {
        focusedItem = .itemId(lastTag.id)
      }

    case .itemId(let tagId):
      if listVM.isFirst(id: tagId) {
        focusedItem = .prefix
      } else {
        if let prevTag = listVM.previous(beforeId: tagId) {
          focusedItem = .itemId(prevTag.id)
        }
      }
    }
  }

  func onReturnKey() -> KeyPress.Result {
    switch nextCommand {
    case .append: onAddCommand(.append)
    case .prepend: onAddCommand(.prepend)
    case .insert: onAddCommand(.insert)
    case .replace: onAddCommand(.replace)
    case .toggle: onToggleCommand()
    case .copy: onCopyCommand(mods: [])
    case .paste: onPasteCommand(mods: [])
    case .done: onDoneCommand()
    case .filterOn: onSelectCommand()
    default:
      break
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

  func onAddCommand(_ cmd: ListEditorActions) {
    if textToAdd.isEmpty {
      return
    }
    
    let newTag: FilteringTag = .tag(textToAdd.read())
    
    switch cmd {
    case .append: listVM.append(newTag)
    case .prepend: listVM.prepend(newTag)
    case .replace: listVM.replace(id: focusedItem.id, with: newTag)
    case .insert: listVM.insert(newTag, beforeId: focusedItem.id)
    default:
      break
    }
    
    suggestionsCursorIndex = -1
  }
  
  func onToggleCommand() {
    listVM.toggle(id: focusedItem.id)
  }

  func onCopyCommand(mods: EventModifiers = []) {
    dispatch(.copyToClipboard(
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
    
      /// Try to decode the clipboard as a JSON string. This supports transfering tags with their encoded types
    if let tagSet = try? JSONDecoder().decode(FilteringTagSet.self, from: data) {
      return tagSet.values
    }
    
      /// Fallback to a simple comma-separated list of tags
    return str
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
    
    /// Attempt to decode the pasted string (either JSON or comma-separated)
    let pastedItems = getPastedItems(from: clipString)
    
    /// If no items were decoded, just append the pasted string to the textfield
    if pastedItems.isEmpty {
      textToAdd.reset(to: textToAdd.value + clipString)
//      textToAdd += clipString
      return
    }
    
    if mods.isPressed(.shift) {
        /// Alternate action is to replace the current list
      listVM.replace(pastedItems)
    } else {
        /// Default action is to append the pasted items
      listVM.append(contentsOf: pastedItems)
    }
    
    focusedItem = .prefix
  }
  
  
  func onSelectCommand() {
    guard focusedItem.isItem else { return }
    
    if let tag = listVM.retrieveBy(id: focusedItem.id)?.item {
      onSelection(.addFilter(tag, .inclusive))
    }
  }
}


#Preview("Tags Panel (floating)", traits: .defaultViewModel, .previewSize(.panel)) {
  @Previewable @State var listItems = TestData.fruitTags + TestData.vegetableTags
  
  ListEditorSheetView(
    listItems: listItems,
    onCompletion: { val in print(val) },
    onExit: { print("Exited") }
  )
}
