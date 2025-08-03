// created on 11/22/24 by robinsr

import Foundation

extension FileWrapper {
  /**
   Returns the value of an extended attribute from a file wrapper
   
   For example, `fileWrapper.fileAttributes` contains:
   
   ```
   "NSFileExtendedAttributes": [
     "com.taggedfilebrowser.contentID": Data(40 bytes)
   ],
   ```
   */
  func extendedAttribute(_ attrName: String) -> String? {
    if let xattrs = self.fileAttributes["NSFileExtendedAttributes"] as? Dictionary<String, Any>,
       let attrData = xattrs[attrName] as? Data,
       let attrValue = String(data: attrData, encoding: .utf8) {
      return attrValue
    } else {
      return nil
    }
  }
}
