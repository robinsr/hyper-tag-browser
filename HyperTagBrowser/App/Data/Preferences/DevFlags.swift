// created on 2/6/25 by robinsr

import Defaults
import GRDB
import SwiftUI


enum DevFlags: String, Defaults.Serializable, CaseIterable {
  
  // Flags available for user preferences
  case enable_obscureContent
  case enable_dominantColor
  case enable_panAndZoom
  
  // Flags related to feature enablement
  case model_logActionDescription
  
  
  // Flags related to SwiftUI views
  case views_debug
  case views_showTestBorders
  case views_debugDominantColor
  case views_debugColorScheme
  case views_debugToolbar
  case views_debugSearch
  
  // Flags related to Indexer, file data, SQL issues, etc
  case indexer_debugParameters
  case indexer_enableSqlTrace
  case indexer_enableSqlProfiling
  case indexer_debugSqlStatements
  case indexer_debugSqlResponses

  // Flags related to testing
  case testing_verboselogs
  
  
  enum Category: String, CaseIterable, CustomStringConvertible {
    case feature = "enable_"
    case model = "model_"
    case view = "views_"
    case indexer = "indexer_"
    case test = "testing_"
    case unknown = "_"
    
    var description: String {
      switch self {
      case .feature: "Feature Flag"
      case .model: "Debug Models"
      case .indexer: "Debug Indexer"
      case .view: "Debug Views"
      case .test: "Testing"
      case .unknown: "Unknown"
      }
    }
    
    var presentationOrder: Int {
      let ordering: [Category] = [.feature, .model, .view, .indexer, .test, .unknown]
      
      return ordering.firstIndex(of: self) ?? ordering.count
    }
  }
  
  var category: DevFlags.Category {
    Category.allCases.first { self.rawValue.hasPrefix($0.rawValue) } ?? .unknown
  }
  
  
  var description: String {
    switch self {
    case .enable_dominantColor:
      "Enable Dominant Color Background"
    case .enable_obscureContent:
      "Obscure image thumbnails"
    case .enable_panAndZoom:
      "Enable Pan and Zoom Image Controls"
    case .indexer_debugParameters:
      "Debug Query Parameters"
    case .indexer_debugSqlResponses:
      "Inspect SQL Responses"
    case .indexer_debugSqlStatements:
      "Inspect SQL Statements"
    case .indexer_enableSqlProfiling:
      "Enable SQL Profiling"
    case .indexer_enableSqlTrace:
      "Enable SQL Tracing"
    case .model_logActionDescription:
      "Log Model Action Descriptions"
    case .testing_verboselogs:
      "(test only) Verbose Logging"
    case .views_debug:
      "Debug View"
    case .views_debugColorScheme:
      "Show Color Scheme Debug"
    case .views_debugDominantColor:
      "Show Image Color Analysis"
    case .views_debugSearch:
      "Show Search Debug"
    case .views_debugToolbar:
      "Show Toolbar Debug"
    case .views_showTestBorders:
      "Show Test Borders"
    }
  }
  
  var debugDescription: String {
    switch self {
    case .indexer_debugParameters:
      "Logs current query params to console; shows query hash value in UI"
    case .indexer_enableSqlTrace:
      "Enable GRDB SQL tracing"
    case .indexer_enableSqlProfiling:
      "Emit query execution statistics to console"
    case .indexer_debugSqlStatements:
      "Prints formatted SQL statements to console"
    case .indexer_debugSqlResponses:
      "Dumps objects returned from SQL statements to console"
    default:
      "(\(self.rawValue))"
    }
  }
  
  var command: some Commands {
    CommandGroup(replacing: .appInfo) {
      Button(self.description) {
        Defaults[.devFlags].toggleExistence(self)
      }
      .keyboardShortcut("D", modifiers: [.command, .option])
    }
  }
  
  static func list(for stage: AppStage) -> [DevFlags] {
    switch stage {
    case .test:
      Self.allCases.sorted(by: \.category.presentationOrder)
    default:
      Self.allCases
        .filter { $0.category != .test }
        .sorted(by: \.category.presentationOrder)
    }
  }
  
  static let appDefaults: Set<DevFlags> = [.enable_dominantColor, .enable_panAndZoom]
}


extension DevFlags: PreferenceTip {
  var id: String { self.rawValue }
  var label: String { self.description }
  var helpText: String { self.debugDescription }
}


enum QueryableDevFlags: String, Defaults.Serializable, CaseIterable, CustomStringConvertible, CustomDebugStringConvertible {
  
  case ListIndexInfoRequest
  case ListIndexesRequest
  case ListIndexLocationsRequest
  case GetIndexInfoRequest
  case CountIndexesRequest
  
  case ListIndexTagsRequest
  case ListCountedTagsRequest
  
  case ListQueuesRequest
  case ListQueueIndexesRequest
  
  case ListBookmarksRequest

  
  init?(rawValue: String) {
    if let match = Self.allCases.first(where: { $0.rawValue == rawValue }) {
      self = match
    } else {
      return nil
    }
  }
  
  var debugDescription: String {
    "Enable debug feature for query \(self.rawValue)"
  }
  
  var description: String {
    self.rawValue
      .map({ $0.isUppercase ? " \($0)" : "\($0)" })
      .joined()
      
  }
}


extension Binding {
  static func flag(_ flag: DevFlags) -> Binding<Bool> {
    .init(
      get: { Defaults[.devFlags].contains(flag) },
      set: { Defaults[.devFlags].toggleExistence(flag, shouldExist: $0) }
    )
  }
}


extension EnvironmentValues {
  @Entry var enabledFlags: Set<DevFlags> = []
}
