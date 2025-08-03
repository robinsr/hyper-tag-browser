// created on 11/15/24 by robinsr

import SwiftUI
import Factory
import GRDBQuery


struct ContentTagContextMenu : View {
  @Injected(\Container.clipboardService) var clippy
  
  let tag: FilteringTag
  let actions: [TagMenuAction]
  var onSelection: DispatchFn = {
    Container.shared.appViewModel().dispatch($0)
  }
  
  init(tag: FilteringTag, actions: [TagMenuAction], onSelection: @escaping DispatchFn) {
    self.tag = tag
    self.actions = actions
    self.onSelection = onSelection
  }
  
  init(tag: FilteringTag, groups: [[TagMenuAction]], onSelection: @escaping DispatchFn) {
    let buttons: [TagMenuAction] = groups.map { $0 + [.separator] }.flatMap { $0 }.dropLast()
    
    self.init(tag: tag, actions: buttons, onSelection: onSelection)
  }
  
  init(tag: FilteringTag, sections: TagMenuSection, onSelection: @escaping DispatchFn) {
    self.init(tag: tag, groups: sections.menuButtons, onSelection: onSelection)
  }
  
  init(tag: FilteringTag, buttons: [TagMenuAction]) {
    self.tag = tag
    self.actions = buttons
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
        
      case .removeFrom(let pointer):
        ContextMenuButton(action) {
          onSelection(.dissociateTag(tag, from: .one(pointer)))
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
        
      @unknown default:
        EmptyView()
      }
    }
  }
  
  func RelabelMenu(_ context: TagMenuContext) -> some View {
    Menu {
      ForEach(tagLabelOptions, id: \.id) { option in
        Button {
          switch context {
          case .whenAppliedAsQueryFilter:
            onSelection(.replaceFilter(tag, with: tag.relabel(using: option.value)))
          case .whenAppliedAsContentTag:
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
