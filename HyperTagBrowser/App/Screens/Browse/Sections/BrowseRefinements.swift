// Created on 10/28/2024 by robisnr

import Factory
import Flow
import GRDBQuery
import SwiftUI

struct BrowseRefinements: View {

  private let logger = EnvContainer.shared.logger("BrowseRefinements")

  @Environment(AppViewModel.self) var appVM

  @Environment(\.dispatcher) var dispatch
  @Environment(\.windowSize) var windowSize
  @Environment(\.dbContentItemParameters) var query

  @State var newTagText = TextFieldModel(validate: [.presence])
  @State var numSuggestions: Int = 12

  @State var suggestedItems: [(Int, TagSuggestions.Suggestion)] = []


  @State var filteringEnabled: Bool = true

  @Query(GetSavedQueriesRequest(id: nil)) var savedQuery: SavedQueryRecord?

  @FocusState var isFocused
  @Namespace private var animation

  let defaultSpacing: CGFloat = 16

  /// Binding for the "Enabled" toggle in the applied filters section
  var isFilteringEnabled: Binding<Bool> {
    .readOnly(query.tagsMatching.enabled).onChange {
      dispatch(.setTagFiltering(enabled: $0))
    }
  }

  /// Returns the `SavedQueryRecord` that matches the current query, if any.
  var matchingSavedQuery: SavedQueryRecord? {
    savedQuery
  }

  /// Returns true if the current query matches an existing saved query
  var matchingSavedQueryFound: Bool {
    matchingSavedQuery != nil && matchingSavedQuery?.id == query.id
  }

  /// The text to use for the inline "Save Query" button within the "Applied Filters" section
  var saveQueryButtonText: String {
    if let record = matchingSavedQuery {
      return "Update \(record.name.truncated(toLength: 12).quoted)"
    }

    return "Save Query"
  }

  var currentFilters: [FilteringTag.Filter] {
    query.tagsMatching.filters
  }

  var canShowMoreSuggestions: Bool {
    numSuggestions < suggestedItems.count && !suggestedItems.isEmpty
  }

  func onShowMoreSuggestions() {
    numSuggestions += 5
  }

  func onNewTagTextSubmit() {
    if newTagText.isValid {
      let tagValue = newTagText.read()
      dispatch(.addFilter(.tag(tagValue), .inclusive))
    }
  }

  //
  // MARK: - Views
  //

  var body: some View {
    Group {
      if windowSize.upToBreakpoint(.medium) {
        StackedLayout
      } else {
        WideLayout
      }
    }
    .accessibilityLabel("Browse refinements")
    .accessibilityHint("Filter the current view by tags, dates, and other criteria")
    .onChange(of: query) {
      $savedQuery.id.wrappedValue = query.id
    }
  }

  //
  // MARK: - Layouts
  //

  var WideLayout: some View {
    HStack(alignment: .top) {
      SearchTagsSection

      VStack(spacing: defaultSpacing) {
        AppliedFiltersList
        AppliedFiltersControls
        Debug_DebugFiltersSection
      }
    }
  }

  var StackedLayout: some View {
    VStack(spacing: defaultSpacing) {
      SearchTagsSection
      AppliedFiltersList
      AppliedFiltersControls
      Debug_DebugFiltersSection
    }
  }

  var SearchTagsSection: some View {
    BoxContent("Search Tags") {
      Suggestions_SearchField

      FlowItemContainer {
        Suggestions_Items
        LineBreak()
        if canShowMoreSuggestions {
          Suggestions_ShowMoreButton
        }
      }
    }
  }

  var AppliedFiltersList: some View {
    BoxContent("Applied Filters") {
      FlowItemContainer {
        Filters_Items
      }
    }
    .hidden(query.isEmpty)
  }

  var AppliedFiltersControls: some View {
    FullWidthSplit(alignment: .leading, spacing: defaultSpacing) {
      Filters_CompoundOperator
      Filters_VisibilityMenu
    } trailing: {
      Filters_IsEnabledToggle
      Filters_SaveButton
    }
  }


  //
  // MARK: - Applied Filters Subviews
  //

  var Filters_Items: some View {
    ForEach(currentFilters, id: \.id) { filter in
      TagButton(
        for: filter.tag,
        config: getAppliedFilterTagButtonConfig(filter: filter)
      )
      .matchedGeometryEffect(id: filter.id, in: animation)
    }
    .transition(.scale)
  }

  var Filters_CompoundOperator: some View {
    MenuSelect(
      selection: .constant(query.filterOperator),
      using: FilterOperator.self,
      presentation: .menu,
      itemLabel: { val in
        Text("Matching **\(val.label)** filters")
      }
    ) { val in
      dispatch(.setFilterOperator(val))
    }
  }

  var Filters_VisibilityMenu: some View {
    MenuSelect(
      selection: .constant(query.visibility),
      using: ContentItemVisibility.self,
      presentation: .menu,
      itemLabel: { val in
        Text("Item Visibility: **\(val.label)**")
      }
    ) { val in
      dispatch(.setVisibilityFilter(val))
    }
  }

  var Filters_IsEnabledToggle: some View {
    Toggle("Enabled", isOn: isFilteringEnabled)
      .toggleStyle(.switch)
      .controlSize(.mini)
  }

  // TODO: The logic for switching between "Update" and "Save" is broken.
  var Filters_SaveButton: some View {
    Button {
      if let match = matchingSavedQuery {
        // If the current filters match an existing saved query, assume we want to update it.
        // Which MAKES NO SENSE because if it matches, why would we need to update it?
        //
        // Instead, if the filters were loaded from a save, that should be stored somewhere
        // so that we can know this is an "update" operation.
        dispatch(.loadSavedQuery(match.id))
      } else {
        dispatch(.showSheet(.newSavedQuerySheet(query: query)))
      }
    } label: {
      Text(saveQueryButtonText)
    }
    .buttonStyle(.accessoryBarAction)
    .controlSize(.extraLarge)
    .disabled(query.isEmpty)
  }

  //
  // MARK: - Filter Suggestions Subviews
  //

  var Suggestions_Items: some View {
    TagSuggestions(
      searchText: $newTagText.value,
      excludedTags: .constant(currentFilters.tags),
      bindTo: $suggestedItems,
      numSuggestions: $numSuggestions,
      minTextNeeded: 2,
      searchDomains: [.attribution, .descriptive, .queue],
      content: { index, suggestion in
        TagButton(for: suggestion.asFilter, config: getSuggestTagButtonConfig(at: index))
      }
    )
  }

  var Suggestions_ShowMoreButton: some View {
    Button(action: onShowMoreSuggestions) {
      Label("More", .search)
        .padding(4)
    }
    .buttonStyle(.accessoryBarAction)
    .labelStyle(.titleOnly)
    .transition(.scale(scale: 0.0, anchor: .center))
  }


  var Suggestions_SearchField: some View {
    SearchField(value: $newTagText.rawValue, placeholder: "Search Tags")
      .controlSize(.extraLarge)
      .font(.system(size: 20))
      .id("BrowseRefinementsTextField")
      .focused($isFocused, equals: true)
      .onSubmit(onNewTagTextSubmit)
      .frame(minWidth: 200, maxWidth: .infinity)
  }

  // MARK: - Supporting Views

  func BoxContent(_ title: String, @ViewBuilder content: @escaping () -> some View) -> some View {
    VStack(alignment: .leading) {
      GroupBox(title) {
        VStack(spacing: defaultSpacing) {
          content()
        }
      }
      .groupBoxStyle(.bordered)
    }
  }

  func FlowItemContainer<Content: View>(
    itemSpacing spaceItem: CGFloat = 6,
    rowSpacing spaceRow: CGFloat = 4,
    @ViewBuilder content: @escaping () -> Content
  ) -> some View {
    HorizontalFlowView(vAlign: .center, itemSpacing: spaceItem, rowSpacing: spaceRow) {
      content()
    }
    .padding(2)
  }

  //
  // MARK: - TagButton Configurations
  //

  func getSuggestTagButtonConfig(at index: Int) -> TagButtonConfiguration {
    return TagButtonConfiguration(
      size: .small,
      variant: .secondary,
      keyConfig: index < 10 ? .indexed(index, [.control]) : .none,
      contextMenuConfig: .whenSuggestedAsQueryFilter,
      contextMenuDispatch: dispatch,
      onTap: { tag in
        dispatch(.addFilter(tag, .inclusive))
      },
      longPressAction: .renameAll
    )
  }

  /**
   * For FilteringTags currently applied to the browse view.
   * You should be able to make updates to the tag's value (editable), AND modify the tag's filtering value (mutable).
   */
  func getAppliedFilterTagButtonConfig(
    filter: FilteringTag.Filter
  ) -> TagButtonConfiguration {
    let longAction: TagMenuAction = FirstTrueBuilder.withDefault(.invert) {
      (filter.tag.domain == .creation, .changeDate)
      (filter.tag.domain == .descriptive, .renameAll)
    }

    return TagButtonConfiguration(
      size: .small,
      variant: .primary(filter.effect),
      contextMenuConfig: .whenAppliedAsQueryFilter,
      contextMenuDispatch: dispatch,
      onTap: { tag in
        switch tag.domain {
          case .creation:
            dispatch(.showSheet(.datePickerSheet(tag: tag)))
          default:
            dispatch(.removeFilter(tag))
        }
      },
      longPressAction: longAction
    )
  }


  //
  // MARK: - Debugging Views
  //

  var Debug_DebugFiltersSection: some View {
    HStack(spacing: defaultSpacing) {
      Group {
        Debug_CopyHashButton
        Debug_CopyJSONButton
      }
      .buttonStyle(.accessoryBarAction)
      .controlSize(.small)
    }
    .debugVisible(flag: .indexer_debugParameters)
  }

  var Debug_CopyHashButton: some View {
    Button {
      dispatch(.copyToClipboard(label: "Query Hash", value: query.hashId))
    } label: {
      Text("Query Hash: \(query.hashId.quoted)")
    }
  }

  var Debug_CopyJSONButton: some View {
    Button {
      dispatch(.copyToClipboard(label: "Query JSON", value: JSONEncoder.pretty(query)))
    } label: {
      Text("Query JSON")
    }
  }

}

#Preview(
  "Narrow", traits: .databaseContext, .defaultViewModel, .fixedLayout(width: 400, height: 800)
) {
  @Previewable @Environment(AppViewModel.self) var appVM

  VStack {
    BrowseRefinements()
  }
  .fillFrame(.vertical, alignment: .top)
  .preferredColorScheme(.dark)
  .environment(\.dbContentItemParameters, appVM.dbIndexParameters)
}

#Preview(
  "Wide", traits: .databaseContext, .defaultViewModel, .testBordersOff,
  .fixedLayout(width: 1200, height: 200)
) {
  @Previewable @Environment(AppViewModel.self) var appVM

  VStack {
    BrowseRefinements()
  }
  .preferredColorScheme(.dark)
  .environment(\.dbContentItemParameters, appVM.dbIndexParameters)
}
