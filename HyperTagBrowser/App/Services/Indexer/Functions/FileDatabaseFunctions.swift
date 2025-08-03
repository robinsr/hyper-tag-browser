// created on 11/19/24 by robinsr

import Defaults
import Factory
import Foundation
import GRDB
import Regex
import UniformTypeIdentifiers

enum FilesDBFunctions: String, DbFuncDefinition, CaseIterable {
  private static let logger = EnvContainer.shared.logger("FilesDBFunctions")
  private static let quicklook = Container.shared.quicklookService()

  case conformsTo
  case fileConformsTo
  case fileContents
  case fileContentType
  case fileExists
  case fileExistsIn
  case fileSize
  case xattr

  var fnType: DbFuncType { .function }
  var fnName: String { rawValue }
  var fnAggregator: DatabaseAggregate.Type? { return nil }

  var fnArgs: DbFuncArguments {
    switch self {
      case .conformsTo:
        return .fixed(of: [.uttype, .uttype])
      case .fileConformsTo:
        return .fixed(of: [.url, .uttype])
      case .fileContents:
        return .fixed(of: [.url])
      case .fileContentType:
        return .fixed(of: [.url])
      case .fileExists:
        return .fixed(of: [.url])
      case .fileExistsIn:
        return .fixed(of: [.url, .string])
      case .fileSize:
        return .fixed(of: [.url])
      case .xattr:
        return .fixed(of: [.url, .string])
    }
  }

  var fnExec: DbFuncExec? {
    switch self {
      case .conformsTo:
        return Self.execConformsTo
      case .fileConformsTo:
        return Self.execFileConformsTo
      case .fileContents:
        return Self.execFileContents
      case .fileContentType:
        return Self.execFileContentType
      case .fileExists:
        return Self.execFileExists
      case .fileExistsIn:
        return Self.execFileExistsIn
      case .fileSize:
        return Self.execFileSize
      case .xattr:
        return Self.execXattr
    }
  }

  static let execFileExists: DbFuncExec = { values in
    measureExecutionTime {
      guard let fileURL = values[0] as? URL else { return nil }

      let exists = FileManager.default.fileExists(at: fileURL)

      logger.emit(.debug.off, "File \(fileURL) exists? \(exists)")

      return exists
    }
  }

  static let execFileExistsIn: DbFuncExec = { values in
    measureExecutionTime {
      guard let folderURL = values[0] as? URL else { return nil }
      guard let filename = values[1] as? String else { return nil }

      let fileURL = folderURL.appendingPathComponent(filename)

      let exists = FileManager.default.fileExists(at: fileURL)

      logger.emit(.debug.off, "File \(fileURL) exists? \(exists)")

      return exists
    }
  }

  static let execFileSize: DbFuncExec = { values in
    return measureExecutionTime {
      guard let fileURL = values[0] as? URL else { return nil }
      guard FileManager.default.fileExists(at: fileURL) else { return nil }

      return fileURL.fileSize
    }
  }

  static let execFileContentType: DbFuncExec = { values in
    return measureExecutionTime {
      guard let fileURL = values[0] as? URL else { return nil }
      return fileURL.contentType
    }
  }

  static let execConformsTo: DbFuncExec = { values in
    return measureExecutionTime {
      guard let uttype1 = values[0] as? UTType else { return nil }
      guard let uttype2 = values[1] as? UTType else { return nil }

      let isConforming = uttype1.conforms(to: uttype2)

      logger.emit(
        .debug.off, "Content type \(uttype1) conforms to type \(uttype2)? \(isConforming)")

      return isConforming
    }
  }

  static let execFileConformsTo: DbFuncExec = { values in
    return measureExecutionTime {
      guard let fileURL = values[0] as? URL else { return nil }
      guard let uttype = values[1] as? UTType else { return nil }

      let isConforming = fileURL.contentType.conforms(to: uttype)

      logger.emit(
        .debug.off,
        "Extracting contentType from url: \(fileURL); conforms to type \(uttype)? \(isConforming)")

      return isConforming
    }
  }

  static let execXattr: DbFuncExec = { values in
    guard let fileURL = values[0] as? URL else { return nil }
    guard let key = values[1] as? String else { return nil }

    do {
      let value = try fileURL.extendedAttribute(forName: key)
      return String(data: value, encoding: .utf8)
    } catch {
      logger.emit(.error, ErrorMsg("Error getting extended attribute for \(fileURL)", error))
      return nil
    }
  }

  static let execFileContents: DbFuncExec = { values in
    guard let fileURL = values[0] as? URL else { return nil }

    do {
      return try Data(contentsOf: fileURL)
    } catch {
      logger.emit(.error, ErrorMsg("Error reading image data for \(fileURL)", error))
      return nil
    }
  }
}
