// created on 10/18/24 by robinsr

import SwiftUI
import GRDBQuery
import OSLog
import Flow
import Factory
import Regex
import IssueReporting


@Observable
class EventHandlerObservable {
  var eventhandle: Any?
}


struct AddTagView: View {
  static let textFieldId = "AddTagTextField"
  
  var logger = EnvContainer.shared.logger("AddTagView")
  
  var contentItem: ContentItem
  
  @Injected(\Container.themeProvider) private var theme
  
  @Environment(\.dispatcher) var dispatch
  @Environment(\.pushState) var navigate
  @Environment(\.modifierKeys) var modState
  @Environment(\.textFieldFocus) var textFieldFocus
  @Environment(\.modifierKeys) var mods
  @Environment(\.cursorState) var cursor
  
  @FocusState var isFocused
  
  @State var evtHandleStore = EventHandlerObservable()
  @State var newTagText = TextFieldModel(validate: [.presence])
  @State var topNumTags = 10
  @State var suggestions: [(Int, TagSuggestions.Suggestion)] = []
  @State var suggestionsCursorIndex: Int = -1
  
  
  var eventhandle: Any?
  
  func resetCursor() {
    suggestionsCursorIndex = -1
  }
  
  func submitNewTag() {
    if let (_, selectedTag) = suggestions[safe: suggestionsCursorIndex] {
      dispatch(.associateTag(selectedTag.asFilter, to: .one(contentItem.pointer)))
      resetCursor()
      return
    }
    
    if newTagText.isValid {
      let value = newTagText.read()
      
      // TODO: Why is this async?
      DispatchQueue.main.async {
        dispatch(.associateTag(.tag(value), to: .one(contentItem.pointer)))
      }
      
      resetCursor()
    }
  }
  
  var body: some View {
    VStack(alignment: .leading) {
      TextInputAndKeyResponder
      TagSuggestionResults
    }
    .onChange(of: contentItem) {
      resetCursor()
      addKeyEventListeners()
    }
    .disabled(contentItem.index.isIndexed == false)
  }
  
  var TextInputAndKeyResponder: some View {
    SearchField(value: $newTagText.rawValue, placeholder: "Search Tags")
      .isTyping($isFocused)
      .focused($isFocused)
      .buttonShortcut(binding: .listEditorLeft, action: selectPrevSuggestion)
      .buttonShortcut(binding: .listEditorRight, action: selectNextSuggestion)
      .onKeyPress(.return) {
        submitNewTag()
        return .handled
      }
      .onDisappear {
        textFieldFocus.focused.remove("AddTagTextField")
      }
      .onAppear {
        addKeyEventListeners()
      }
      .onChange(of: isFocused) {
        textFieldFocus.focused.toggleExistence(Self.textFieldId, shouldExist: isFocused)
      }
  }
  
  var TagSuggestionResults: some View {
    VStack {
      TagSuggestionList
      
      ListControlsHint()
        .scaleEffect(0.9)
        .styleClass(.hint)
        .padding(.vertical, 3)
        .fillFrame(.horizontal, alignment: .center)
        .hidden(suggestions.isEmpty || isFocused == false)
      
      SuggestionCountStepper
    }
  }
  
  var TagSuggestionList: some View {
    HorizontalFlowView(itemSpacing: 4, rowSpacing: 4) {
      TagSuggestions(
        searchText: $newTagText.value,
        selectedItems: .constant([contentItem.id]),
        bindTo: $suggestions,
        numSuggestions: $topNumTags,
        minTextNeeded: 0,
        searchDomains: [.attribution, .descriptive]
      ) { index, item in
        TagButton(
          for: item.asFilter,
          config: tagButtonConfig(usageCount: item.count)
        )
        .activateTag(when: index == suggestionsCursorIndex)
          //.longPressTagAction(.renameAll, referencing: item.asFilter)
      }
    }
    .padding(.top, 12)
  }
  
  var SuggestionCountStepper: some View {
    FullWidth(alignment: .trailing) {
      Button("Show More") {
        topNumTags += 5
      }
      .buttonStyle(.accessoryBarAction)
      .hidden(topNumTags - suggestions.count > 0)
    }
  }
  
  func tagButtonConfig(usageCount: Int?) -> TagButtonConfiguration {
    .init(
      size: .small,
      variant: .primary,
      labelCount: usageCount,
      contextMenuConfig: .whenSuggestedAsContentTag,
      contextMenuDispatch: { action in
        dispatch(action)
        dispatch(.popRoute)
      },
      onTap: { tag in
        dispatch(.associateTag(tag, to: .one(contentItem.pointer)))
      },
      longPressAction: .renameAll
    )
  }
}





extension AddTagView {
  
  struct MacosKeyCodes {
    static let arrowUp = 126
    static let arrowDown = 125
    static let arrowRight = 124
    static let arrowLeft = 123
    static let escape = 53
  }
  
  func selectNextSuggestion() {
    guard isFocused else { return }
    
    let next = suggestionsCursorIndex + 1
    suggestionsCursorIndex = suggestions.indices.contains(next) ? next : -1
  }
  
  func selectPrevSuggestion() {
    guard isFocused else { return }
    
    let next = suggestionsCursorIndex - 1
    let array = Array(-1...suggestions.indices.upperBound)
    suggestionsCursorIndex = array.contains(next) ? next : suggestions.indices.endIndex - 1
  }
  
  func addKeyEventListeners() {
    if evtHandleStore.eventhandle != nil {
      NSEvent.removeMonitor(evtHandleStore.eventhandle!)
    }
    
    evtHandleStore.eventhandle = NSEvent.addLocalMonitorForEvents(matching: [.keyUp]) { nsevent in
      
      // // No longer necessary to listen for key controls here, handled by SearchField
      // if nsevent.keyCode == MacosKeyCodes.arrowRight {
      //   if nsevent.modifierFlags.contains(.shift) {
      //     selectNextSuggestion()
      //     return nil
      //   }
      // }
      // if nsevent.keyCode == MacosKeyCodes.arrowLeft {
      //   if nsevent.modifierFlags.contains(.shift) {
      //     selectPrevSuggestion()
      //     return nil
      //   }
      // }
      
      // Is this one still necessary?
      if nsevent.keyCode == MacosKeyCodes.escape {
        isFocused = false
        return nil
      }
      
      return nsevent
    }
  }
}
