// created on 11/1/25 by robinsr

import SwiftUI


/**
 * Defines action that can be taken in the context of editing a set of tags (for a 
 */
enum EditTagSetAction {
  typealias TagSuggestion = CountedTagRecord
  
  case addText(String)
  case addSuggestion(TagSuggestion)
  
  case replaceText(FilteringTag, String)
  case replaceSuggestion(FilteringTag, TagSuggestion)
  
  case toggle(FilteringTag)
  case filterOn(FilteringTag)
  
  case copyString
  case pasteString
  
  case done
  case none

  
  private var proposedText: String {
    switch self {
    case .addText(let text):
      return text
    case .addSuggestion(let suggestion):
      return suggestion.asFilter.value
    case .replaceText(_, let text):
      return text
    case .replaceSuggestion(_, let suggestion):
      return suggestion.asFilter.value
    case .toggle(let tag):
      return tag.description
    default:
      return ""
    }
  }
  
  private var currentText: String {
    switch self {
    case .replaceText(let tag, _), .replaceSuggestion(let tag, _):
      return tag.value
    case .toggle(let tag), .filterOn(let tag):
      return tag.value
    default:
      return ""
    }
  }
  
  var label: LocalizedStringKey {
    switch self {
    case .addText(_), .addSuggestion(_):
      return "Add tag (\(proposedText))"
    case .replaceText(_, _), .replaceSuggestion(_, _):
      return "Replace *\(currentText)* with *(\(proposedText))*"
    case .toggle(_):
      return "Toggle *\(currentText)*"
    case .filterOn(_):
      return "Filter on *\(currentText)*"
    case .copyString:
      return "Copy tags"
    case .pasteString:
      return "Paste tags"
    case .done:
      return "Done"
    case .none:
      return "..."
    }
  }

  /// Returns a SF Icon string for the command type
  var icon: SymbolIcon {
    switch self {
    case .addText(_), .addSuggestion(_): return .editText
    case .replaceText(_, _), .replaceSuggestion(_, _): return .insertText
    
    case .toggle: return .itemChecked
    case .filterOn: return .filterOn
    
    case .copyString: return .copy
    case .pasteString: return .paste
    
    case .done: return .lgtm
    case .none: return .unknown
    }
  }
  
  enum ActionType {
    case addText
    case addSuggestion
    case replaceText
    case replaceSuggestion
    case toggle
    case filterOn
    case copyString
    case pasteString
    case done
    case none
  }
  
  var type: ActionType {
    switch self {
    case .addText(_): return .addText
    case .addSuggestion(_): return .addSuggestion
      
    case .replaceText(_, _): return .replaceText
    case .replaceSuggestion(_, _): return .replaceSuggestion
    
    case .toggle: return .toggle
    case .filterOn: return .filterOn
    
    case .copyString: return .copyString
    case .pasteString: return .pasteString
    
    case .done: return .done
    case .none: return .none
    }
  }
}
