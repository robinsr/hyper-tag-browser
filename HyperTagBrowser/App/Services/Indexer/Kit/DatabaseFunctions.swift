// created on 12/10/24 by robinsr

import Factory
import Foundation
import GRDB
import OSLog
import UniformTypeIdentifiers

/// Function type for SQLite database functions implemented in Swift.
typealias DbFuncExec = @Sendable ([DatabaseValueConvertible]) -> DatabaseValueConvertible?

protocol DbFuncDefinition: Sendable {
  var fnName: String { get }
  var fnArgs: DbFuncArguments { get }
  var fnType: DbFuncType { get }
  var fnExec: DbFuncExec? { get }
  var fnAggregator: DatabaseAggregate.Type? { get }
}

extension DbFuncDefinition {
  func invokeArgs(_ values: [DatabaseValue]) throws -> [DatabaseValueConvertible] {
    if fnArgs.isEmpty { return [] }

    return try zip(fnArgs.arguments, values).map {
      let typename = String(describing: $0)

      guard let value = $0.fromDatabaseValue($1) else {
        throw DbFuncError.argumentParsingError("Could not parse \(typename) from \($1)")
      }

      return value
    }
  }

  var logger: Logger {
    EnvContainer.shared.logger("dbFuncDefinition.\(#fileID):\(fnName)")
  }

  var funcDef: DatabaseFunction {
    switch fnType {
      case .function:
        guard let fn = fnExec else {
          fatalError("Function \(fnName) must define an executor")
        }

        return DatabaseFunction(
          fnName, argumentCount: fnArgs.argCount, pure: true,
          function: { values in
            do {
              let args = try invokeArgs(values)
              return fn(args)
            } catch {
              logger.emit(.error, "Error invoking function \(fnName): \(error)")
              return nil
            }
          })

      case .aggregate:
        guard let agg = fnAggregator else {
          fatalError("Aggregate function \(fnName) must define an aggregator")
        }

        return DatabaseFunction(fnName, argumentCount: fnArgs.argCount, pure: true, aggregate: agg)
    }
  }
}

enum DbFuncType {
  case function, aggregate
}

enum DbFuncArgument {
  // Expand as needed
  case string, integer, url, uttype

  var type: DatabaseValueConvertible.Type {
    switch self {
      case .string: return String.self
      case .integer: return Int.self
      case .url: return URL.self
      case .uttype: return UTType.self
    }
  }

  func fromDatabaseValue(_ value: DatabaseValue) -> DatabaseValueConvertible? {
    switch self {
      case .string: return String.fromDatabaseValue(value)
      case .integer: return Int.fromDatabaseValue(value)
      case .url: return URL.fromDatabaseValue(value)
      case .uttype: return UTType.fromDatabaseValue(value)
    }
  }
}

enum DbFuncArguments {
  case vararg(of: DbFuncArgument)
  case fixed(of: [DbFuncArgument])
  case noArgs

  var arguments: [DbFuncArgument] {
    switch self {
      case .vararg(let arg): return Array(repeating: arg, count: 100)
      case .fixed(let args): return args
      case .noArgs: return []
    }
  }

  var argCount: Int? {
    switch self {
      case .fixed(let args): return args.count
      default: return nil
    }
  }

  var isEmpty: Bool {
    arguments.isEmpty
  }
}

enum DbFuncError: Error {
  case argumentParsingError(String)
}

/*
  Database functions are defined in the `DatabaseFunction` enum.

  This file defines the database function names, and provides a few
  convenience methods for using them in SQL expressions.
 */
enum DatabaseFunctions: String, CaseIterable {
  case regexpMatch, regexpCapture, regexpReplace
  case concatGroup, textConcat, textJoin, hashId

  case fileExists, fileExistsIn, fileSize, fileContentType, conformsTo, fileConformsTo, xattr,
    fileContents

  var reference: DbFuncDefinition {
    switch self {

      // RegexpDatabaseFunctions cases
      case .regexpMatch: return RegexpDBFunctions.regexpMatch
      case .regexpCapture: return RegexpDBFunctions.regexpCapture
      case .regexpReplace: return RegexpDBFunctions.regexpReplace

      // TextDatabaseFunctions cases
      case .concatGroup: return TextDBFunctions.concatGroup
      case .textConcat: return TextDBFunctions.textConcat
      case .textJoin: return TextDBFunctions.textJoin
      case .hashId: return TextDBFunctions.hashId

      // FileDatabaseFunctions cases
      case .conformsTo: return FilesDBFunctions.conformsTo
      case .fileConformsTo: return FilesDBFunctions.fileConformsTo
      case .fileContents: return FilesDBFunctions.fileContents
      case .fileContentType: return FilesDBFunctions.fileContentType
      case .fileExists: return FilesDBFunctions.fileExists
      case .fileExistsIn: return FilesDBFunctions.fileExistsIn
      case .fileSize: return FilesDBFunctions.fileSize
      case .xattr: return FilesDBFunctions.xattr

    }
  }

  /// References the database function implementation.
  var function: DatabaseFunction {
    reference.funcDef
  }

  /// Alias for `function`, indicating that the function is being invoked in a query.
  var call: DatabaseFunction {
    self.function
  }

  /// References the SQLite concat function (SQL `||` operator).
  static func concat(_ columns: ColumnExpression...) -> SQLExpression {
    columns.map(\.sqlExpression).joined(operator: .concat)
  }

  static func not_null(_ column: ColumnExpression) -> SQLExpression {
    "\(column.name) IS NOT NULL".sqlExpression
  }

  static func replace(_ column: Column, _ pattern: String, _ replacement: String) -> SQLExpression {
    let match = pattern.quotedDatabaseIdentifier
    let repl = replacement.quotedDatabaseIdentifier

    return "replace(\(column.name) \(match), \(repl)".sqlExpression
  }

  static var functionNames: [String] {
    allCases.map { $0.reference.fnName }
  }
}
