// created on 4/23/25 by robinsr

import SwiftUI


struct TagDraggablePreview: View {
  var title: String = "dropping tags..."
  let tags: [FilteringTag]
  
  var body: some View {
    VStack(alignment: .leading) {
      Text(title)
        .italic()
        .fontWeight(.thin)
      
      ForEach(tags, id: \.self) { tag in
        HStack(spacing: 0) {
          Image(.tag)
          Text(tag.description)
        }
        .font(.caption)
      }
    }
    .fixedSize(horizontal: true, vertical: true)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .shadow(radius: 2)
    .opacity(0.75)
    .background {
      RoundedRectangle(cornerRadius: 3)
        .fill(.quinary)
    }
  }
}
