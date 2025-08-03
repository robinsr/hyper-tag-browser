// created on 4/9/25 by robinsr

//import SwiftUI
//import AudioToolbox
//import SystemSound


/**
 * Usage:
 * ```swift
 * SoundEffectPicker()
 * ```
 */
//struct SoundEffectPicker: View {
//  
//  @State var selection: SoundEffect?
//
//  var body: some View {
//    Picker(selection: $selection, label: Text("Sound:")) {
//      Text("None").tag(nil as SoundEffect?)
//      ForEach(SoundEffect.systemSoundEffects, id: \.self) { sound in
//        Text(sound.name).tag(sound as SoundEffect?)
//      }
//    }.onChange(of: selection) {
//      selection?.play()
//    }
//  }
//}
