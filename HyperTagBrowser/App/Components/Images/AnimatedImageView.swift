// created on 4/6/25 by robinsr


import SDWebImageSwiftUI
import SwiftUI


struct AnimatedImageContent: View {
  
  let imageURL: URL
  
  var body: some View {
    WebImage(url: imageURL)
      .resizable()
      .aspectRatio(contentMode: .fit)
  }
}

