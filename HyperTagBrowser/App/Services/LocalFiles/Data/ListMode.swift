// created on 10/14/24 by robinsr

import Cache
import CustomDump
import Foundation



/**
 * Defines different options for listing files and directories.
 */
enum ListMode: Hashable, CustomStringConvertible, Codable {
  
  typealias EnumerationOptions = FileManager.DirectoryEnumerationOptions
  
  var description: String {
    "\(type.rawValue)(\(cacheConfig.rawValue))"
  }

  
  /**
   * Equivalent to standard UNIX `ls`. Cache enabled by default to prevent overloading the filesystem with requests.
   */
  case immediate(FileCachingOption = .cached)
  
  /**
   * Equivalent to standard UNIX `ls -R`. Cache enabled by default to prevent overloading the filesystem with requests.
   */
  case recursive(FileCachingOption = .cached)
  
  
    /// Returns the type of listing mode.
  var type: ListModeTypes {
    switch self {
    case .immediate: return .immediate
    case .recursive: return .recursive
    }
  }
  
  
  enum ListModeTypes: String, Codable, CustomStringConvertible {
    case immediate, recursive
    
    var enumerationOpts: EnumerationOptions {
      switch self {
      case .immediate: return .skipsSubdirectoryDescendants
      case .recursive: return .includesDirectoriesPostOrder
      }
    }
    
    var description: String {
      switch self {
      case .immediate: return "Items in folder"
      case .recursive: return "All items under"
      }
    }
  }
  
    /// Defines the `FileManager.DirectoryEnumerationOptions` for the current mode.
  var enumerationOpts: EnumerationOptions {
    return [ type.enumerationOpts, .skipsHiddenFiles, .skipsPackageDescendants]
  }
  
    /// Removes the `.skipsHiddenFiles` option from the current mode.
  var hidden: EnumerationOptions {
    enumerationOpts.subtracting([.skipsHiddenFiles])
  }
  
    /// Returns a specialized `FileManager.DirectoryEnumerationOptions`
    /// option set for certain URLs requiring special handling.
  func forURL(_ url: URL) -> EnumerationOptions {
      
      // Always use non-recursive mode for directories that typically contain many subdirectories.
    if FSPredicates.isHomeDir(url){
      return Self.immediate(.cached).enumerationOpts
    }
    
      // Include hidden files for directories above the home directory, only list immediate children.
    if FSPredicates.isAboveHomeDir(url) {
      return Self.immediate(.cached).hidden
    }
    
    return enumerationOpts
  }
  
  
  var cacheConfig: FileCachingOption {
    switch self {
      case .immediate(let opts), .recursive(let opts): return opts
    }
  }
  
  /**
   * Use cached results (regardless of listing type)
   */
  var useCache: Bool { cacheConfig == .cached }
  
  
  /**
   * Returns a new mode with the opposite type.
   */
  var toggle: Self {
    switch self {
    case .immediate(let opts): return .recursive(opts)
    case .recursive(let opts): return .immediate(opts)
    }
  }
  
  /**
   * Returns a new mode with the opposite type with the specified caching option.
   */
  func toggle(_ opts: FileCachingOption) -> Self {
    switch self {
    case .immediate(_): return .recursive(opts)
    case .recursive(_): return .immediate(opts)
    }
  }
    
  
  /**
   * Retains the current mode but enables caching.
   */
  var withCacheEnabled: Self {
    switch self {
    case .immediate(_): return .immediate(.cached)
    case .recursive(_): return .recursive(.cached)
    }
  }
  
  /**
   * Retains the current mode but disables caching.
   */
  var withCacheDisabled: Self {
    switch self {
    case .immediate(_): return .immediate(.uncached)
    case .recursive(_): return .recursive(.uncached)
    }
  }
}


extension ListMode: RawRepresentable {
  typealias RawValue = String
  
  init?(rawValue: String) {
    let typeSub = rawValue.prefix(while: { $0 != "#" })
    let optsSub = rawValue.suffix(from: typeSub.endIndex).dropFirst()
    
    let opts = FileCachingOption(rawValue: String(optsSub)) ?? .uncached
    let type = ListModeTypes(rawValue: String(typeSub)) ?? .immediate
    
    switch type {
    case .immediate:
      self = .immediate(opts)
    case .recursive:
      self = .recursive(opts)
    }
  }
  
  var rawValue: String {
    switch self {
    case .immediate(let opts): return "immediate#\(opts.rawValue)"
    case .recursive(let opts): return "recursive#\(opts.rawValue)"
    }
  }
}
