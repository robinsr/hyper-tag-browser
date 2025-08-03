// created on 3/2/25 by robinsr

import AppKit
import CustomDump
import Factory


// TODO: launch profile from dock menu
class AppDelegate: NSObject, NSApplicationDelegate {
  
  private let logger = EnvContainer.shared.logger("AppDelegate")
  
  @Injected(\PreferencesContainer.externalProfiles) var profiles
  @Injected(\PreferencesContainer.userProfileId) var current
  
  var menuItems: [NSMenuItem] {
    return profiles.map { profile in
      let item = NSMenuItem(title: profile.name, action: #selector(tappedButton), keyEquivalent: "")
      
      item.state = (profile.id == current) ? .on : .off
      item.target = self
      item.representedObject = profile
      
      return item
    }
  }
  
  func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
    let nsMenu = NSMenu()
      
    for item in menuItems {
      nsMenu.addItem(item)
    }
    
    return nsMenu
  }
  
  @objc func tappedButton(_ sender: NSMenuItem?) {
    guard let profile = sender?.representedObject as? AnyUserProfile else {
      logger.emit(.error, "Profile not found in sender's representedObject")
      return
    }
    
    logger.emit(.info, "Selected profile: \(profile.name)")
    
    profile.launchProfile()
  }
}
