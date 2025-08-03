// created on 11/25/24 by robinsr

import Factory
import IdentifiedCollections
import Outline
import SwiftUI
import System


// @MainActor
@Observable
final class DirTreeModel {
  
  @ObservationIgnored
  private let log = EnvContainer.shared.logger("DirTreeModel")
  
  @ObservationIgnored
  @Injected(\Container.fileService) var fs
  
  private(set) var root = FileTreeNode(path: URL.homeDirectory.filepath, children: [])
  
  var nodeMap: IdentifiedArrayOf<FileTreeNode> = []
  var expanded: Set<FileTreeNode.ID> = []
  var selection: Set<FileTreeNode.ID> = []
  var suggestions: Set<FileTreeNode> = []
  
  var selected: FileTreeNode? {
    selection.first.flatMap { nodeMap[id: $0] }
  }
  
  @available(*, deprecated, message: "Use DirTreeMode.cwdpath instead")
    /// The URL of the root node in the directory tree
  var cwdURL: URL {
    root.url
  }
  
    /// The filepath of the root node in the directory tree
  var cwd: FilePath {
    root.path
  }
  
    /// Name of the root node
  var baseName: String {
    cwd.baseName
  }

  /// Indexed set of ancestor folders 
  var ancestorPath: [(Int, FileTreeNode)] {
    root.ancestors.enumerated().map { ($0, $1) }
  }
  
  @MainActor
  var outlineData: OutlineData<FileTreeNode, FileTreeNode.ID> {
    OutlineData(
      root: root,
      subValues: { node in
        self.open(id: node.id).sorted(by: \.id)
      },
      id: \.id,
      hasSubvalues: \.notEmpty
    )
  }
  
  init(cwd url: URL) {
    self.resetTo(cwd: url)
  }
  
  func resetTo(cwd url: URL) {
    self.root = fs.tree(at: url, depth: 0)
    
    nodeMap.updateOrAppend(root)
    
    for child in self.root.children {
      nodeMap.updateOrAppend(child)
    }
  }
  
  func findNode(id: String) -> FileTreeNode? {
    nodeMap[id: id]
  }
  
  func upDir(distance: Int = 1) {
    var toURL = root.url
    
    for _ in 0..<distance {
      toURL = toURL.deletingLastPathComponent()
    }
    
    root = fs.tree(at: toURL, depth: 1)
    
    (root.children + [root]).forEach {
      nodeMap.updateOrAppend($0)
    }
  }
  
  func select(id: FileTreeNode.ID) {
    guard var node = nodeMap[id: id] else {
      log.emit(.error, "No node found for id: \(id)")
      return
    }
    
    node.children = fs.tree(at: node.url, depth: 1).children
    
    for child in node.children {
      nodeMap.updateOrAppend(child)
    }
    
    self.selection = [node.id]
  }
  
  
  @discardableResult
  func open(id: FileTreeNode.ID) -> [FileTreeNode] {
    guard var node = nodeMap[id: id] else {
      log.emit(.error, "No node found for id: \(id)")
      return []
    }
    
    node.children = fs.tree(at: node.url, depth: 1).children
    
    for child in node.children {
      nodeMap.updateOrAppend(child)
    }
    
    if expanded.contains(node.id) {
      expanded.remove(node.id)
    } else {
      expanded.update(with: node.id)
    }
    
    return node.children
  }
  
  func close(id: FileTreeNode.ID) {
    expanded.remove(id)
  }
  
  func getSuggestions(text searchText: String) {
    do {
      let results = try fs.findFolder(from: root.path, matching: searchText)
      
      suggestions = results.map { FileTreeNode(path: $0, children: []) }.asSet
      
      suggestions.forEach { node in
        nodeMap.updateOrAppend(node)
      }
    } catch {
      log.emit(.error, .raised("Error while searching for folders:", error))
      suggestions.removeAll()
    }
  }
  
  func toggleSuggestion(_ node: FileTreeNode) {
    if selection.contains(node.id) {
      selection = []
    } else {
      expanded.forEach { close(id: $0) }
      
      let newBranch = fs.branch(from: root.path, to: node.path)
      
      var leaf = newBranch
      
      while leaf.children.notEmpty {
        if let next = leaf.children.first {
          nodeMap.updateOrAppend(next)
          expanded.update(with: next.id)
        }
        
        leaf = leaf.children.first!
      }
      
      self.selection = [node.id]
    }
  }
}


extension DirTreeModel: CustomDebugStringConvertible {
  var debugDescription: String {
    """
    DirTreeModel(
      cwd=\(cwd.string)
      expanded=\(expanded.asArray.joined(separator: ", "))
      selection=\(selection.asArray.joined(separator: ", "))
      suggestions=\(suggestions.map(\.displayName).joined(separator: ", "))
      tree=\(root.debugDescription)
    )
    """
  }
}
