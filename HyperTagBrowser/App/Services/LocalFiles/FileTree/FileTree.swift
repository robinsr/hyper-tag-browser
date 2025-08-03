// created on 11/18/24 by robinsr

import CustomDump
import Foundation
import System


struct FileTreeNode: Hashable, Identifiable, Encodable {
  private var childNodes: [FileTreeNode] = []
  var path: FilePath
  var id: String
  var displayName: String
  var state: NodeState = .initial
  
  var url: URL {
    path.fileURL
  }
  
  enum CodingKeys: String, CodingKey {
    case path, id, displayName, state, childNodes
  }
  
  init(path filepath: FilePath) {
    self.path = filepath
    self.id = filepath.string
    self.displayName = filepath.baseName
  }
  
  init(path filepath: FilePath, children: [FileTreeNode]) {
    self.init(path: filepath)
    self.children = children
  }

  var children: [FileTreeNode] {
    get { childNodes }
    set {
      self.childNodes = newValue
      self.state = .fetched
    }
  }
  
  /*
   * Recursively gathers all the paths present in the tree at the moment
   */
  var paths: [FilePath] {
    [path] + childNodes.flatMap(\.paths)
  }
  
  /**
   * This node's parent `FileTreeNode` (a recreation, not direction reference)
   */
  var parent: FileTreeNode {
    FileTreeNode(path: path.directory)
  }
  
  /**
   * A set of `FileTreeNode`s representing this node's ancenstor chain, starting
   * with filesytem root and ending with this node's parent
   */
  var ancestors: [FileTreeNode] {
    let fsRoot: FilePath = "/"
    
    var ancestors: [FileTreeNode] = []
    var node = self
    var location = node.path.removingLastComponent()
    
    while location != fsRoot {
      node = FileTreeNode(path: location)
      ancestors.append(node)
      location = location.removingLastComponent()
    }
    
    return ancestors
  }

  
  var isEmpty: Bool { children.isEmpty }
  var notEmpty: Bool { !children.isEmpty }
  
  
  enum NodeState: String, Codable {
    case initial, fetched
  }
}

extension FileTreeNode: CustomDebugStringConvertible {
  var debugDescription: String {
    var output = ""
    customDump(self, to: &output, indent: 0)
    return output
  }
}


/*
let components = path.components.dropFirst().collect()
let ancestors = components.map {
 let index = components.firstIndex(of: $0)!
 var path: FilePath = "/"
 
 for i in 0..<index {
   path.append(components[i])
 }
 
 return FileTreeNode(path: path)
}
customDump(ancestors, name: "ancestors")
*/
