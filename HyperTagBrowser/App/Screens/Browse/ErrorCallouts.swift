// created on 4/23/25 by robinsr

import Factory
import GRDBQuery
import SwiftUI


struct ErrorCallouts: View {
  @Injected(\Container.fileService) private var fs
  
  @Injected(\PreferencesContainer.userPreferences) var userPrefs
  
  @Environment(\.dispatcher) var dispatch
  @Environment(\.location) var location
  @Environment(\.queryResultCount) var resultCount
  @Environment(\.dbContentItemsHiddenCount) var hiddenItemCount
  @Environment(\.dbLocations) var dbLocations
  
  var body: some View {
    FirstTrueScenarioView {
      ContentItemsTruncated
      WorkingDirNotIndexed
      WorkingDirIsEmpty
      WorkingDirVolumeNotMounted
      WorkingDirNotFound
    }
  }
  
  var volumeIsBrowsable: Bool {
    location.volumeInfo?.isBrowsable ?? false
  }
  
  var volumeName: String {
    location.volumeInfo?.name ?? "Unknown"
  }
  
  var locationKnown: Bool {
    dbLocations.contains(startOf: location.filepath)
  }
  
  var locationExists: Bool {
    fs.exists(at: location)
  }
  
  var noContentItems: Bool {
    resultCount == 0
  }
  
  var someHiddenItems: Bool {
    hiddenItemCount > 0
  }
  
  var ContentItemsTruncated: some View {
    ErrorScenarioCallout(
      id: "ContentItemsExceedGridLimit",
      isTrue: { someHiddenItems },
      title: "\("items", qty: hiddenItemCount) hidden",
      help: "Showing up \("items", qty: userPrefs.forKey(.photoGridItemLimit)). Try adjusting your filters or choose a different sort option",
      icon: .eyeslash
    )
  }
  
  var WorkingDirIsEmpty: some View {
    ErrorScenarioCallout(
      id: "WorkingDirIsEmpty",
      isTrue: {
        noContentItems && locationKnown
      },
      title: "No items to show",
      help: "Try adjusting your filters",
      icon: .noFolder
    )
  }
  
  var WorkingDirNotIndexed: some View {
    ErrorScenarioSubcontentCallout(
      id: "WorkingDirNotIndexed",
      isTrue: {
        noContentItems && !locationKnown
      },
      title: "Folder not indexed",
      help: "Folder \(location.filepath) hasn't been indexed yet",
      icon: .noFolder
    ) { content in
        VStack {
          content
          IndexItemsButton
        }
      }
  }
  
  var WorkingDirNotFound: some View {
    ErrorScenarioCallout(
      id: "WorkingDirNotFound",
      isTrue: {
        !locationExists
      },
      title: "Folder not found",
      help: "Folder \(location.filepath) doesn't appear to exist",
      icon: .noFolder
    )
  }
  
  var WorkingDirVolumeNotMounted: some View {
    ErrorScenarioCallout(
      id: "WorkingDirVolumeNotMounted",
      isTrue: {
        !volumeIsBrowsable
      },
      title: "Volume not mounted",
      help: "Volume \(volumeName) is not mounted",
      icon: .noFolder
    )
  }
  
  var IndexItemsButton: some View {
    Button("Index files") {
      dispatch(.indexItems(inFolder: location))
    }
    .buttonStyle(.borderedProminent)
    .controlSize(.extraLarge)
  }
}
