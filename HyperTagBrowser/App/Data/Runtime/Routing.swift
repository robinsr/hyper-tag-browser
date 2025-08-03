// Created on 9/7/24 by robinsr

import Foundation
import Defaults
import System


enum Route: Hashable {
  case main
  case folder(_ path: FilePath)
  case content(_ id: ContentPointer)
  
  var filepath: FilePath {
    switch self {
    case .folder(let path): return path
    case .content(let pointer): return pointer.contentPath
    default: return Defaults[.profileOpenTo].filepath
    }
  }
  
  var name: String {
    switch self {
    case .main: return "main"
    case .folder(_): return "folder"
    case .content(_): return "content"
    }
  }
  
  var page: Page {
    switch self {
    case .main: return .main
    case .folder(_): return .folder
    case .content(_): return .content
    }
  }
  
  func eq(_ route: Route) -> Bool {
    return self.name == route.name
  }
  
  static func forURL(_ url: FilePath) -> Route {
    if url.isDirectory {
      return .folder(url)
    }
    
    return .content(ContentPointer(filePath: url))
  }
  
  public enum Page: CaseIterable {
    case main
    case folder
    case content
  }
  
  public enum Action: String {
    case push
    case replace
  }
}

extension Collection where Element == Route.Page {
  
  /**
   * The collection of all `Page`s
   */
  static var all: [Element] {
    Route.Page.allCases
  }
  
  /**
   * The collection of `Page` values excluding `.main`
   */
  static var notMain: [Element] {
    Array(all.filter { $0 != .main })
  }
  
  /**
   * All pages for browsing content. `.main` is excluded because its the start location
   * and should be immediately replaced with a `.folder` of the user's preferred start location
   */
  static var browseOnly: [Element] { [.folder] }
  
  /**
   * All detail viewing pages
   */
  static var contentOnly: [Element] { [.content] }
}


extension Route: CustomStringConvertible {
  var description: String {
    switch self {
    case .main: return "main"
    case .folder(let path): return "folder: \(path)"
    case .content(let pointer): return "content: \(pointer)"
    }
  }
}


extension Route: Equatable {
  static func ==(lhs: Route, rhs: Route) -> Bool {
    return lhs.filepath == rhs.filepath
  }
}


extension Route: Codable {
  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let path = try container.decode(FilePath.self)
    self = Route.forURL(path)
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(self.filepath)
  }
}


extension Array where Element == Route {
  var hasPrevious: Bool {
    self.count > 1
  }
}
