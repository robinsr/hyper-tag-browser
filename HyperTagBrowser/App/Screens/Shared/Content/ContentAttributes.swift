// created on 1/16/25 by robinsr

import SwiftUI
import GRDBQuery


struct ContentAttributes: View {
  
  @Environment(\.dispatcher) var dispatch
  @Environment(\.pushState) var navigate
  @Environment(\.replaceState) var replace
  
  @Environment(\.location) var location
  
  var contentItem: ContentItem
  
  var attributions: [FilteringTag] {
    contentItem.tags.filter { $0.domain == .attribution }
  }
  
  var body: some View {
    AttributeGrid {
      AttributeGrid.Row("Filename") {
        Button {
          dispatch(.editName(of: contentItem.pointer))
        }
        label: {
          Text(verbatim: contentItem.name)
        }
        .buttonStyle(.weblink)
      }

      AttributeGrid.Row("Created") {
        DateView(date: contentItem.index.created)
      }
      
      AttributeGrid.Row("Folder") {
        NavigateToFolderButton(
          location: contentItem.location,
          relativeTo: location.filepath
        )
        .buttonStyle(.weblink)
      }
      
      AttributeGrid.Row("Credits") {
        VStack(alignment: .leading) {
          CurrentTagsView(
            contentItem: .constant(contentItem),
            domains: .constant([.attribution])
          )
        }
      }
      
      AttributeGrid.Row("Dimensions") {
        Text(contentItem.pixelDimensions.formatted)
      }
      .when(contentItem, conformsTo: .image)
      
      AttributeGrid.Row("Content ID") {
        HStack {
          Text(verbatim: contentItem.id.shortId)
            .help(contentItem.id.value)
            .styleClass(.identifier)
            .lineLimit(1)
            .selectable()
          
          Button(.copy) {
            dispatch(.copyToClipboard(label: "Content ID", value: contentItem.id.value))
          }
          .buttonStyle(.plain)
          
        }
      }
      
      Group {
        AttributeGrid.Row("FileId") {
          Text(verbatim: contentItem.url.fileIdentifier)
        }
       
        AttributeGrid.Row("SystemId") {
          Text(verbatim: contentItem.url.systemIdentifier)
        }
        
        AttributeGrid.Row("SystemFileId") {
          Text(verbatim: contentItem.url.systemFileIdentifier)
        }
      }
      .debugVisible(flag: .views_debug)
    }
  }
}

#Preview("ContentAttributes", traits: .defaultViewModel, .fixedLayout(width: 400, height: 800)) {
  @Previewable @State var contentItemIndex = 2
  
  VStack {
    HStack {
      Button("Prev") {
        contentItemIndex = TestData.testContentItems[circular: contentItemIndex - 1]
      }
      Spacer()
      Button("Next") {
        contentItemIndex = TestData.testContentItems[circular: contentItemIndex + 1]
      }
    }
    ContentAttributes(contentItem: TestData.testContentItems[contentItemIndex])
      .fillFrame(.vertical)
    DisclosureGroup("JSON View") {
      JSONView(object: .constant(TestData.testContentItems[contentItemIndex]))
    }
  }
  .frame(width: 400, height: 800)
}
