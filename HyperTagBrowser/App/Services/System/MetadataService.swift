// created on 9/29/24 by robinsr

import CoreServices
import CoreFoundation
import Factory
import Foundation
import XAttr


struct MetadataService {
  static var shared = MetadataService()
  
  private let log = EnvContainer.shared.logger("MetadataService")
  

  func assignNewXID(to url: URL) throws -> ContentId {
    let id = ContentId.newID(forFile: url)
    
    guard let idData = id.value.data(using: .utf8) else {
      throw MetadataError.createIdFailed(url)
    }
    
    do {
      try url.setExtendedAttribute(data: idData , forName: Constants.xContentIdKey)
    } catch {
      throw MetadataError.attributeWriteError(error)
    }
    
    return id
  }
  
  func retrieveXID(for url: URL) throws -> ContentId? {
    var attributes: [String: Data] = [:]
    
    do {
      attributes = try url.extendedAttributeValues(forNames: try url.extendedAttributeNames())
    } catch {
      throw MetadataError.attributeReadError(error)
    }
    
    guard attributes.keys.contains(Constants.xContentIdKey) else { return nil }
    
    guard let idAttribute = attributes[Constants.xContentIdKey] else {
      throw MetadataError.missingAttribute(Constants.xContentIdKey)
    }
    
    guard let idString = String(data: idAttribute, encoding: .utf8) else {
      throw MetadataError.attributeDecodingError(
        EncodingError.invalidValue(idAttribute, EncodingError.Context(
          codingPath: [], debugDescription: "Could not decode xContentId")
        )
      )
    }
    
    return ContentId(existing: idString)
  }
  
  func cleanAttributes(from pointers: [ContentPointer]) throws {
    for item in pointers {
      do {
        try item.contentPath.removeExtendedAttribute(forName: Constants.xContentIdKey)
      } catch {
        throw MetadataError.attributeWriteError(error)
      }
    }
  }
}

enum MetadataError: Error, CustomStringConvertible {
  case attributeReadError(Error)
  case attributeWriteError(Error)
  case attributeDecodingError(Error)
  case missingAttribute(String)
  case createIdFailed(URL)
  
  var description: String {
    switch self {
    case .attributeReadError(let error):
      return "Error reading attribute: \(error)"
    case .attributeWriteError(let error):
      return "Error writing attribute: \(error)"
    case .attributeDecodingError(let error):
      return "Error decoding attribute: \(error)"
    case .missingAttribute(let attribute):
      return "Missing attribute: \(attribute)"
    case .createIdFailed(let url):
      return "Failed to create ID for URL: \(url)"
    }
  }
}
