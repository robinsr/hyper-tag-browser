// created on 11/21/24 by robinsr

import Foundation

/**
 * The set of URL extensions for reading and writing extended attributes.
 *
 * Extended attributes are metadata associated with files in Unix-like operating systems.
 *
 * Reference:
 *
 * - [Extended attributes - ArchWiki](https://wiki.archlinux.org/title/Extended_attributes)
 */
extension URL {

  /**
   * Returns the value of an extended attribute for the file at this URL
   */
  func extendedAttribute(forName name: String) throws -> Data {

    let data = try self.withUnsafeFileSystemRepresentation { fileSystemPath -> Data in

      // Determine attribute size:
      let length = getxattr(fileSystemPath, name, nil, 0, 0, 0)
      guard length >= 0 else { throw URL.posixError(errno) }

      // Create buffer with required size:
      var data = Data(count: length)

      // Retrieve attribute:
      let result = data.withUnsafeMutableBytes { [count = data.count] in
        getxattr(fileSystemPath, name, $0.baseAddress, count, 0, 0)
      }
      guard result >= 0 else { throw URL.posixError(errno) }
      return data
    }
    return data
  }

  /**
   * Sets an extended attribute with the given name and data for the file at this URL.
   */
  func setExtendedAttribute(data: Data, forName name: String) throws {

    try self.withUnsafeFileSystemRepresentation { fileSystemPath in
      let result = data.withUnsafeBytes {
        setxattr(fileSystemPath, name, $0.baseAddress, data.count, 0, 0)
      }
      guard result >= 0 else { throw URL.posixError(errno) }
    }
  }

  /**
   * Removes an extended attribute with the given name from the file at this URL.
   */
  func removeExtendedAttribute(forName name: String) throws {

    try self.withUnsafeFileSystemRepresentation { fileSystemPath in
      let result = removexattr(fileSystemPath, name, 0)
      guard result >= 0 else { throw URL.posixError(errno) }
    }
  }

  /**
   * Lists all extended attributes for the file at this URL. This method returns an array of attribute names.
   */
  func listExtendedAttributes() throws -> [String] {

    let list = try self.withUnsafeFileSystemRepresentation { fileSystemPath -> [String] in
      let length = listxattr(fileSystemPath, nil, 0, 0)
      guard length >= 0 else { throw URL.posixError(errno) }

      // Create buffer with required size:
      var namebuf = [CChar](repeating: 0, count: length)

      // Retrieve attribute list:
      let result = listxattr(fileSystemPath, &namebuf, namebuf.count, 0)
      guard result >= 0 else { throw URL.posixError(errno) }

      // Extract attribute names:
      let list = namebuf.split(separator: 0).compactMap {
        $0.withUnsafeBufferPointer {
          $0.withMemoryRebound(to: UInt8.self) {
            String(bytes: $0, encoding: .utf8)
          }
        }
      }
      return list
    }
    return list
  }

  /// Helper function to create an NSError from a Unix errno.
  private static func posixError(_ err: Int32) -> NSError {
    return NSError(
      domain: NSPOSIXErrorDomain,
      code: Int(err),
      userInfo: [
        NSLocalizedDescriptionKey: String(cString: strerror(err))
      ]
    )
  }
}
