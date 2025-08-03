// created on 2/14/25 by robinsr

import Outline
import SwiftUI

@MainActor
@Observable
final class OutlineModel {

  var onDblClick: (URL) -> Void = { _ in }

  init() {}

  init(onDblClick: @escaping (URL) -> Void) {
    self.onDblClick = onDblClick
  }

  func configureView(_ view: NSOutlineView) {
    // Fill the view vertically and horizontally
    view.autoresizingMask = [.width, .height]

    // Disable default focus ring
    view.focusRingType = .none
    view.backgroundColor = Color.darkModeBackgroundColor.opacity(0.2).nsColor
    view.intercellSpacing = NSSizeFromCGSize(.init(width: 0, height: 2))


    // Disable multiple selection
    // TODO: Make this configurable for other use cases
    view.allowsMultipleSelection = false


    // Should allow for double-clicking on outlineview item
    view.target = self
    view.doubleAction = #selector(self.didDoubleClick)
  }

  @objc func didDoubleClick(_ sender: NSOutlineView) {

    // TODO: Cant figure out what to cast this to
    let item = sender.item(atRow: sender.clickedRow)


    if let node = item as? FileTreeNode {
      self.onDblClick(node.url)
      return
    }

    if let url = item as? URL {
      self.onDblClick(url)
      return
    }

    print("Failed to determine URL for item double-clicked")
  }
}

struct DirectoryTreeOutlineView: View {
  @Environment(\.directoryTree) var dirTree

  @State var outlineModel = OutlineModel()
  @State var hoveredItem: FileTreeNode? = nil


  var body: some View {
    @Bindable var dirTree = dirTree

    OutlineView(
      data: dirTree.outlineData,
      expansion: $dirTree.expanded,
      selection: $dirTree.selection,
      configuration: outlineModel.configureView
    ) { value in
      SidebarButton(
        isActive: .constant(dirTree.selection.contains(value.id)),
        isHovered: .constant(hoveredItem == value),
        hoverEffectOn: [.inactive]
      ) {
        FolderIndicator(name: value.displayName)
      }
    }
    .onAppear {
      self.outlineModel.onDblClick = { url in
        dirTree.resetTo(cwd: url)
      }
    }
  }
}
