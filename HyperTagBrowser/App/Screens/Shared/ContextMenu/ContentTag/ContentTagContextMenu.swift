// created on 11/15/24 by robinsr

import SwiftUI
import Factory
import GRDBQuery


struct ContentTagContextMenu : View {
  @Injected(\Container.clipboardService) var clippy
  
  let filter: AnyFilterable
  let actions: [TagMenuAction]
  
  var onSelection: DispatchFn = { action in
    Container.shared.dispatcher().dispatch(action)
  }
  
  init(for filter: AnyFilterable, actions: [TagMenuAction], onSelection: @escaping DispatchFn) {
    self.filter = filter
    self.actions = actions
    self.onSelection = onSelection
  }
  
  init(for filter: AnyFilterable, groups: [[TagMenuAction]], onSelection: @escaping DispatchFn) {
    let buttons: [TagMenuAction] = groups.map { $0 + [.separator] }.flatMap { $0 }.dropLast()
    
    self.init(for: filter, actions: buttons, onSelection: onSelection)
  }
  
  init(for filter: AnyFilterable, sections: TagMenuSection, onSelection: @escaping DispatchFn) {
    self.init(for: filter, groups: sections.menuButtons, onSelection: onSelection)
  }
  
  init(for filter: AnyFilterable, buttons: [TagMenuAction]) {
    self.filter = filter
    self.actions = buttons
  }
  
  var tag: FilteringTag {
    self.filter.asFilter
  }
  
  var tagLabelOptions: [SelectOption<FilteringTag.TagType>] {
    FilteringTag.TagType
      .asSelectables
      .filter { tagtype in
        tagtype.value.domain.oneOf(.descriptive, .attribution)
      }
  }
  
  
  var body: some View {
    ForEach(actions, id: \.id) { action in
      switch action {
      case .copyText:
        ContextMenuButton(action) {
          clippy.write(text: tag.value)
        }
        
      case .filterIncluding:
        ContextMenuButton(action) {
          onSelection(.addFilter(tag, .inclusive))
        }
        
      case .filterExcluding:
        ContextMenuButton(action) {
          onSelection(.addFilter(tag, .exclusive))
        }
        
      case .filterOff:
        ContextMenuButton(action) {
          onSelection(.removeFilter(tag))
        }
        
      case .invert:
        ContextMenuButton(action) {
          onSelection(.invertFilter(tag))
        }
        
      case .removeFrom(let contentId):
        ContextMenuButton(action) {
          onSelection(.dissociateTag(tag, from: .only(contentId)))
        }
        
      case .renameAll:
        if tag.domain.oneOf(.descriptive, .attribution) {
          RenameAllMenu
        }
      
      case .removeAll:
        if tag.domain.oneOf(.descriptive, .attribution) {
          RemoveAllMenu
        }
        
      case .changeDate:
        if tag.domain.oneOf(.creation) {
          ContextMenuButton(action) {
            onSelection(.showSheet(.datePickerSheet(tag: tag)))
          }
        }
      
      case .searchFor:
        ContextMenuButton(action) {
          onSelection(.searchForTag(tag))
        }
        
      case .relabel(let context):
        RelabelMenu(context)
        
      case .text(let value, let symbol):
        ContextMenuTextItem(value, symbol)
        
      case .separator:
        Divider()
          .id(String.randomIdentifier(12))
        
      default:
        EmptyView()
      }
    }
  }
  
  func RelabelMenu(_ context: TagMenuContext) -> some View {
    Menu {
      ForEach(tagLabelOptions, id: \.id) { option in
        Button {
          switch context {
          case .editingBrowseFilters:
            onSelection(.replaceFilter(tag, with: tag.relabel(using: option.value)))
          case .taggedOn(_):
            onSelection(.relabelTag(tag, to: option.value, scope: .all))
          default:
            break;
          }
        } label: {
          ContextMenuLabel(option)
        }
      }
    } label: {
      ContextMenuLabel(TagMenuAction.relabel(context))
    }
  }
  
  var RenameAllMenu: some View {
    Menu {
      ForEach(BatchScope.allCases, id: \.id) { scope in
        Button(scope.description) {
          onSelection(.showSheet(.renameTagSheet(tag: tag, scope: scope)))
        }
      }
    } label: {
      ContextMenuLabel(TagMenuAction.renameAll)
    }
  }
  
  var RemoveAllMenu: some View {
    Menu {
      Button(BatchScope.visible.description, role: .destructive) {
        onSelection(.removeTag(tag, scope: .visible))
      }
      
      Button(BatchScope.all.description, role: .destructive) {
        onSelection(.removeTag(tag, scope: .all))
      }
    } label: {
      ContextMenuLabel(TagMenuAction.removeAll, .red)
    }
  }
}
