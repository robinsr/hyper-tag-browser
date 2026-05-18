// Created on 9/2/24 by robinsr

import Factory
import KBar
import SwiftUI

struct MainScreen: View {
  private static let logger = EnvContainer.shared.logger("MainScreen")

  @Injected(\PreferencesContainer.prefs) var userPrefs
  @Injected(\PreferencesContainer.userProfileId) var profileKey
  @Injected(\IndexerContainer.indexService) var indexer
  @Injected(\Container.spotlightService) var spotlight

  @Environment(AppViewModel.self) var appVM

  @Environment(\.dispatcher) var dispatch
  @Environment(\.pushState) var navigate
  @Environment(\.location) var location
  @Environment(\.route) var route
  @Environment(\.dbItemDetail) var dbItemDetail
  

  var body: some View {
    @Bindable var appVM = appVM

    VStack {
      ZStack(alignment: .bottom) {
        BrowseScreen()
          .navigationTitle("Browse Screen")
          .withUserPrefBackgroundColor()
          .disabled(route.page == .content)

        if let content = dbItemDetail {
          DetailScreen(contentItem: content)
            .background(.ultraThinMaterial)
            .navigationTitle("Detail Screen")
            
            // TODO: Figure out poor performance issues with withEnvironmentBackgroundColor
            //.withEnvironmentBackgroundColor()
        }
      }
    }
    .overlay(alignment: .bottomTrailing) {
      AlertView()
        .frame(maxWidth: 500)
    }
    .sheet(item: $appVM.activeSheet) { sheet in
      SheetView(style: sheet.presentation) {
        MainScreenSheets(sheet)
      }
    }
    .navigationTitle("Main Screen")
    .withCursorControls()
    .withThumbnailCache()
  }

  @ViewBuilder func MainScreenSheets(_ current: AppSheet) -> some View {
    switch current {
      
      case .keyBindings:
        KeyBindingsTable()

      case .contentDetailSheet(let item):
        ContentDetailSheet(content: item)

      case .searchSheet(let query):
        SearchView(withQuery: query)

      case .editItemTagsSheet(let item, let tags):
        TagSheet(item, tags)

      case .editItemsTagsSheet(let items, let tags):
        MultiItemTagSheet(items, tags)

      case .renameTagSheet(let tag, let scope):
        RenameTagSheetView(tag: tag, scope: scope)

      case .createQueueSheet:
        CreateQueueView()

      case .userProfiles:
        ProfileListSheetView()

      case .changeDirectory:
        ChooseDirectoryForm(
          confirm: "Open Folder",
          onSelection: { path in
            dispatch(.showSheet(.none))
            navigate(.folder(path))
          },
          onCancel: {
            dispatch(.showSheet(.none))
          })

      case .chooseDirectory(for: let pointers):
        ChooseDirectoryForm(
          confirm: "Move \("item", qty: pointers.count)",
          onSelection: { path in
            dispatch(.applyIndexPatch(.location(of: pointers.ids, with: path)))
            dispatch(.showSheet(.none))
          },
          onCancel: {
            dispatch(.showSheet(.none))
          })

      case .renameContentSheet(let content):
        TextFieldSheet(
          filename: content.name,
          onUpdate: { newName in
            dispatch(.applyIndexPatch(.name(of: content.id, with: newName)))
            dispatch(.showSheet(.none))
          },
          onCancel: {
            dispatch(.showSheet(.none))
          })

      case .datePickerSheet(let tag):
        AdjustFilterDateView(
          tag: tag,
          onSelection: { updatedTag in
            dispatch(.replaceFilter(tag, with: updatedTag))
            dispatch(.showSheet(.none))
          },
          onCancel: {
            dispatch(.showSheet(.none))
          })

      case .newSavedQuerySheet(query: let filters):
        SaveQuerySheetView(browseFilters: filters)

      case .updateSavedQuerySheet(record: let query):
        SaveQuerySheetView(savedQuery: query)

      case .debug_inspectContentItem(let item):
        WithIndexInfoView(contentId: item.id) { record in
          JsonSheetView(
            object: .constant(record),
            onCopy: { txt in
              dispatch(.copyToClipboard(value: txt))
              dispatch(.showSheet(.none))
            }
          )
        }

      case .debug_inspectSpotlightData(let item):
        WithIndexInfoView(contentId: item.id) { record in
          JsonSheetView(
            object: .constant(record.asSearchableItem(in: "<none>")),
            onCopy: { txt in
              dispatch(.copyToClipboard(value: txt))
              dispatch(.showSheet(.none))
            }
          )
        }

      case .debug_inspectFileMetadata(let item):
        Text(item.index.comment)
          .styleClass(.code)
          .selectable()
          .fillFrame([.horizontal, .vertical], alignment: .topLeading)

      default:
        EmptyView()
    }
  }

  func TagSheet(_ content: ContentItem, _ tags: [FilteringTag]) -> some View {
    TagsEditorSheetView(
      listItems: tags,
      onCompletion: { tags in
        dispatch(.showSheet(.none))
        dispatch(.replaceTags(tags, of: .only(content.id)))
      },
      onSelection: { action in
        dispatch(.showSheet(.none))
        dispatch(action)
      },
      onExit: {
        dispatch(.showSheet(.none))
      },
      backgroundImage: ThumbnailDisplay.full.cgImage(url: content.url))
  }

  func MultiItemTagSheet(_ items: [ContentItem], _ commonTags: [FilteringTag]) -> some View {
    TagsEditorSheetView(
      listItems: commonTags,
      onCompletion: { resultTags in
        dispatch(.showSheet(.none))
        dispatch(.normalizeTags(initial: commonTags,
                                keeping: resultTags,
                                of: items.map(\.pointer)))
      },
      onSelection: { action in
        dispatch(.showSheet(.none))
        dispatch(action)
      },
      onExit: {
        dispatch(.showSheet(.none))
      })
  }
}


//#Preview("", traits: .databaseContext, .defaultViewModel, .previewSize(.sq340.scaled(by: 2.0))) {
//  @Previewable @Environment(AppViewModel.self) var appVM
//  @Previewable @Environment(AppDispatcher.self) var dsp
//
//  VStack {
//    MainScreen()
//      .onAppear {
//        dsp.dispatch(.navigate(to: .main))
//      }
//  }
//  .environment(CursorState())
//}
