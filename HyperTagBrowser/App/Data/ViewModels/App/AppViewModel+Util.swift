// created on 11/24/25 by robinsr

import Defaults
import Factory
import Foundation


extension AppViewModel {
  
    // MARK: - Utility Actions IMPL
  
  func doCopyToClipboard(text: String, label: String?) {
    Container.shared.clipboardService().write(text: text)
    
    if let copyLabel = label {
      messages.send(ok: "\(copyLabel) copied to clipboard")
    } else {
      messages.send(ok: "Copied to clipboard")
    }
  }
  
  func doCopyToClipboard(data: Data, label: String?) {
    Container.shared.clipboardService().write(data: data)
    
    if let copyLabel = label {
      messages.send(ok: "\(copyLabel) copied to clipboard")
    } else {
      messages.send(ok: "Copied to clipboard")
    }
  }
  
  func doEjectVolume(at url: URL) {
    let volumes = Container.shared.volumesService()
    
    do {
      try volumes.ejectVolume(at: url)
      messages.send(ok: "Volume \(url.string) ejected successfully")
    } catch let error as NSError {
      messages.send(ErrorMsg("Failed to eject volume at \(url.string)", error))
    }
  }
}
