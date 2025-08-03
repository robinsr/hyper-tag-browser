// created on 4/5/25 by robinsr

import AVKit
import SwiftUI


struct DetailScreenVideo: View {
  @Binding var fileURL: URL
  @State var player: AVPlayer? = nil
  @State var isPlaying: Bool = false
  
  func onPause() {
    player?.pause()
    isPlaying = false
  }
  
  func onPlay() {
    player?.play()
    isPlaying = true
  }
  
  func onSeek(to time: CMTime) {
    player?.seek(to: time)
  }
  
  var body: some View {
    VStack {
      if let video = player {
        VideoPlayer(player: video)
          .controlSize(.extraLarge)
          .fillFrame(.vertical, alignment: .center)
      }


      Button {
        isPlaying ? onPause() : onPlay()
          
        isPlaying.toggle()
          
        onSeek(to: .zero)
      } label: {
          Image(systemName: isPlaying ? "stop" : "play")
              .padding()
      }
      .onChange(of: fileURL, initial: true) {
        player = AVPlayer(url: fileURL)
      }
    }
  }
}

