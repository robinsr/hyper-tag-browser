// created on 11/6/25 by robinsr

import Foundation
import AppKit

class VolumesService {
  
  private let logger = EnvContainer.shared.logger("MetadataService")
  
  init () {}
  
  func ejectVolume(at url: URL) throws {
    try NSWorkspace.shared.unmountAndEjectDevice(at: url)
  }
}
