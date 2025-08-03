// created on 4/9/25 by robinsr

//import AudioToolbox
//import SystemSound


//struct SoundEffect: Hashable {
//  let id: SystemSoundID
//  let name: String
//
//  func play() {
//    AudioServicesPlaySystemSoundWithCompletion(id, nil)
//  }
//}

//extension SoundEffect {
//  static func getSystemSoundFileEnumerator() -> FileManager.DirectoryEnumerator? {
//    let fm = FileManager.default
//    
//    guard let libraryDirectory = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .systemDomainMask, true).first,
//      let soundsDirectory = NSURL(string: libraryDirectory)?.appendingPathComponent("Sounds"),
//      let soundFileEnumerator = fm.enumerator(at: soundsDirectory, includingPropertiesForKeys: nil)
//    else {
//      return nil
//    }
//    
//    return soundFileEnumerator
//  }
//
//  static let systemSoundEffects: [SoundEffect] = {
//    guard let systemSoundFiles = getSystemSoundFileEnumerator() else { return [] }
//    
//    return systemSoundFiles.compactMap { item in
//      guard let url = item as? URL, let name = url.deletingPathExtension().pathComponents.last else {
//        return nil
//      }
//      
//      var soundId: SystemSoundID = 0
//      
//      AudioServicesCreateSystemSoundID(url as CFURL, &soundId)
//      
//      return soundId > 0 ? SoundEffect(id: soundId, name: name) : nil
//    }
//    .sorted(by: { $0.name.compare($1.name) == .orderedAscending })
//  }()
//}
