// created on 9/17/24 by robinsr

import Defaults
import Factory
import SwiftUI


struct ImageInspector: View {
  private let logger = EnvContainer.shared.logger("ImageInspectorView")
  
  @Environment(\.dispatcher) var dispatch
  @Environment(\.detailEnv) var detailEnv
  @Environment(\.enabledFlags) var devFlags
  
  @Injected(\IndexerContainer.indexService) var indexer
  @Injected(\Container.spotlightService) var spotlight
  @Injected(\Container.thumbnailStore) var thumbnailStore
  
  @Default(.inspectorPanels) var panelState
  
  var thumbnail: NSImage? {
    if let content = detailEnv.contentItem {
      return thumbnailStore.thumbnailImage(for: content)?.asNSImage
    }
    return nil
  }
  
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 8) {
        if let content = detailEnv.contentItem {
          DetailScreenInspectorContent(content)
        }
      }
      .scenePadding(.minimum, edges: [.leading, .top, .trailing])
      .frame(alignment: .top)
    }
    .scrollIndicators(.never)
    .onDisappear {
      if Defaults[.persistInspectorState] == false {
        Defaults.reset(.inspectorPanels)
      }
    }
  }
  
  @ViewBuilder
  func DetailScreenInspectorContent(_ content: ContentItem) -> some View {
    SectionView(isPresented: $panelState.contains(.contentAttributes)) {
      ContentAttributes(contentItem: content)
    } label: {
      Label("File Attributes", .info.variant(.circle))
        .iconPlacement(.iconTrailing)
        .contextMenu {
          ContextMenuItems(content)
        }
    }
    
    Divider()
    
    SectionView("Applied Tags", isPresented: $panelState.contains(.currentTags)) {
      CurrentTagsView(
        contentItem: .constant(content),
        domains: .constant([.descriptive])
      )
      
      CurrentTagsView(
        contentItem: .constant(content),
        domains: .constant([.queue])
      )
    }
    
    Divider()
    
    SectionView("Add Tags", isPresented: $panelState.contains(.searchTags)) {
      AddTagView(contentItem: content)
    }
    
    Divider()
    
    SectionView("Replace Image", isPresented: $panelState.contains(.replaceContent)) {
      ReplaceContentDropArea()
        .relativeCentering(.horizontal, spanning: 60, of: 100)
    }
    
    Divider()
    
    SectionView("Thumbnail", isPresented: $panelState.contains(.contentThumbnail)) {
      InspectThumbnail
    }
  }
  
  var InspectThumbnail: some View {
    VStack(alignment: .center) {
      if let thumbImage = thumbnail {
        ImageBox(nsImage: thumbImage, resizable: true)
          .frame(maxWidth: 256, maxHeight: 256)
          .fixedSize()
          .centered()
      } else {
        Text("No thumbnail available")
          .foregroundColor(.secondary)
          .centered()
      }
    }
  }
  
  @ViewBuilder
  func ContextMenuItems(_ content: ContentItem) -> some View {
    Button("Inspect Record Data") {
      dispatch(.showSheet(.debug_inspectContentItem(item: content)))
    }
    Button("Inspect Properties") {
      dispatch(.showSheet(.debug_inspectFileMetadata(item: content)))
    }
    Button("Inspect Spotlight Item") {
      dispatch(.showSheet(.debug_inspectSpotlightData(item: content)))
    }
    Button("Reindex in Spotlight") {
      dispatch(.updateSearchIndex(with: [content.pointer]))
    }
  }
}

#Preview("Detail Screen - ImageInspector",
         traits: .defaultViewModel, .detailScreen, .previewSize(.inspector)) {
  @Previewable @Environment(\.detailEnv) var detailEnv
  
  VStack {
    ImageInspector()
  }
  .onAppear {
    detailEnv.contentItem = TestData.testContentItems.randomElement()!
  }
}
