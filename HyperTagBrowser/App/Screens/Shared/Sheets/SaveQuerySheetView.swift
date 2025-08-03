// created on 5/24/25 by robinsr

import SwiftUI
import UniformTypeIdentifiers


struct SaveQuerySheetView: View, SheetPresentable {
  static let presentation: SheetPresentation = .modalFixed(controls: .close)
  
  @Environment(\.dismiss) var dismiss
  @Environment(\.dispatcher) var dispatch
  
  @State private var queryNameField = TextFieldModel(initial: "", validate: [.presence])
  @State private var query: BrowseFilters
  @State private var queryId: SavedQueryRecord.ID? = nil
  
  init(browseFilters query: BrowseFilters) {
    self.query = query
  }
  
  init(savedQuery record: SavedQueryRecord) {
    self.query = record.query
    self.queryId = record.id
    self.queryNameField.reset(to: record.name)
  }
  
  private func onConfirm() {
    guard queryNameField.isValid else { return }
    
    let queryName = queryNameField.copy()
    
    if let recordId = self.queryId {
        // Update existing saved query
      dispatch(.renameSavedQuery(recordId, to: queryName))
      dispatch(.updateSavedQuery(recordId, with: query))
    } else {
        // Create a new saved query
      dispatch(.createSavedQuery(query, named: queryName))
    }
    
    dismiss()
  }
  
  var body: some View {
    VStack {
      Text("Save Query")
        .modalContentTitle()
      
      Form {
        FormSection("") {
          Group {
            Query_NameField
            Query_Folder
            Query_FolderDescendents
            Query_Tags
          }
          .padding(.bottom, 12)
        }
      }
      .formStyle(.columns)
      .modalContentMain()
      
      HStack {
        FormCancelButton {
          dismiss()
        }
        
        FormConfirmButton("Save") {
          onConfirm()
        }
        .disabled(queryNameField.isEmpty || queryNameField.hasError)
      }
      .modalContentFooter()
    }
    .modalContentBody()
    .fixedSize()
  }
  
  var Query_NameField: some View {
    TextField("Query Name", text: $queryNameField.rawValue)
  }
  
  var Query_Folder: some View {
    LabeledContent("Folder") {
      NavigateToFolderButton(
        location: query.root,
        relativeTo: query.root.directory
      )
      .buttonStyle(.plain)
      .disabled(true)
      .foregroundStyle(.primary)
      .overlay(alignment: .leading) {
          // TODO: Make these icons or something
        switch query.mode {
        case .immediate:
          Image(systemName: "bolt.fill")
        case .recursive:
          Image(systemName: "arrow.clockwise.circle.fill")
        }
      }
    }
  }
  
  var Query_FolderDescendents: some View {
    Picker("Descendants", selection:
        .constant(query.mode)
        .onChange { mode in
          query.mode = mode
        }
    ) {
      Text("Immediate")
        .tag(ListMode.immediate())
      
      Text("Recursive")
        .tag(ListMode.recursive())
    }
    .pickerStyle(.segmented)
  }
  
  
  var filterGroups: [FilteringTag.FilterGroup] {
    return [
      query.includingTags,
      query.excludingTags,
      query.createdAtTags,
      query.notCreatedAtTags,
      query.inqueueTags,
      query.notInqueueTags,
      query.nameMatchingTags,
      query.nameNotMatchingTags,
    ]
  }
  
  var Query_Tags: some View {
    ForEach(filterGroups, id: \.id) { group in
      FormParameter(group.name) {
        if group.isEmpty {
          Text("None")
            .foregroundStyle(.secondary)
        } else {
          HorizontalFlowView(itemSpacing: 6, rowSpacing: 4) {
            ForEach(group.items, id: \.tag.id) { item in
              TagButton(
                for: item.tag,
                config: .noopButton(variant: .primary(item.effect))
              )
            }
          }
        }
      }
    }
  }
  
//  var queryTypes: Binding<[ContentTypeGroup]> {
//    Binding(
//      get: { query.types },
//      set: { newTypes in
//        query.types = newTypes
//      }
//    )
//  }
  
//  var Query_FileTypes: some View {
//    FormParameter("File Types") {
//      MenuMultiSelect(
//        selection: queryTypes,
//        options: ContentTypeGroup.asSelectables,
//        defaultLabel: "All File Types",
//        presentation: .menu,
//        itemLabel: { option in
//          Text(option.value.title)
//            .tag(option.value.id)
//        }
////        ,
////        onSelection: { selections in
////          query.types = selections
////        }
//      )
//    }
//  }
  
    // MARK: - Supporting Views
  
  func FormSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
    Section {
      content()
    } header: {
      Text(title)
        .font(.headline)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }
  }
  
  func FormParameter<Content: View>(
    _ title: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    LabeledContent(title) {
      content()
    }
    .labeledContentStyle(.automatic)
  }
}



#Preview("SaveQuerySheetView") {
  @Previewable @State var filteringTags = (
    TestData.fruitTags.map {
      FilteringTag.Filter(tag: $0, effect: .inclusive)
    } + TestData.vegetableTags.map {
      FilteringTag.Filter(tag: $0, effect: .exclusive)
    }
  ).shuffled()
    
  
  VStack {
    SaveQuerySheetView(
      browseFilters: BrowseFilters(
        root: TestData.projectDir.filepath,
        mode: .immediate(),
        tagsMatching: FilteringTagMultiParam(filteringTags),
        nameMatching: StringValueMultiParam([
          "Snack items",
        ]),
        visibility: ContentItemVisibility.any
      )
    )
  }
  .scenePadding()
  .frame(width: 500, height: 800)
  .background(.background)
  .colorScheme(.dark)
}
