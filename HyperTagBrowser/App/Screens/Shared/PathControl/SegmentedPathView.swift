  // created on 1/7/25 by robinsr

import SwiftUI
import UniformTypeIdentifiers


struct SegmentedPathView: View {
  var url: URL
  
  func allowedPath(_ url: URL) -> Bool {
    let okDirs = [
      UserLocation.home,
      SystemLocation.volumes.fileURL
    ]
    
    return okDirs.contains(where: { url.isDescendant(of: $0) })
  }
  
  var steps: [URLPathSegment] {
    var steps: [URLPathSegment] = []
    
    if !allowedPath(url) {
      return [URLPathSegment(url: url)]
    }
    
    var stepURL = url
    
    while allowedPath(stepURL) {
      steps.prepend(.init(url: stepURL))
      stepURL = stepURL.deletingLastPathComponent()
    }
    
    return steps
  }
  
  var bookends: [URLPathSegment] {
    [steps.first, steps.last].compactMap{ $0 }
  }
  
  var body: some View {
    ViewThatFits(in: .horizontal) {

      HStack(spacing: 0) {
        ForEach(steps, id: \.id) { step in
          PathSegmentButton(step: step)
        }
      }
        
      HStack(spacing: 0) {
        ForEach(steps.indexed, id: \.1.id) { index, step in
          PathSegmentButton(step: step, collapsible: true)
        }
      }
      
      HStack(spacing: 0) {
        ForEach(bookends, id: \.id) { step in
          PathSegmentButton(step: step)
        }
      }
      
      PathSegmentButton(step: steps.last!)
    }
    .fillFrame(.horizontal, alignment: .leading)
  }
}


#Preview("DirectoryPath", traits: .defaultViewModel) {
  @Previewable @State var testURL = TestData.dbFile
  
  VStack(alignment: .leading) {
    VStack {
      SegmentedPathView(url: testURL)
    }
    .frame(width: 750, alignment: .leading)
    .withTestBorder(.red)
    
    VStack {
      SegmentedPathView(url: testURL)
    }
    .frame(width: 450)
    .withTestBorder(.green)
    
    VStack {
      SegmentedPathView(url: testURL)
    }
    .frame(width: 150)
    .withTestBorder(.blue)
  }
  .scenePadding()
  .background(Color.secondary)
}
