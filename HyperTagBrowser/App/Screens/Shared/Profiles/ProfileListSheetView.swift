// created on 12/18/24 by robinsr

import Factory
import IdentifiedCollections
import SwiftUI


struct ProfileListSheetView: View, SheetPresentable {
  static var presentation: SheetPresentation = .modalSticky(controls: .all)
  
  @Environment(\.dispatcher) var dispatch
  @Environment(\.sheetPadding) var sheetPadding

  @Injected(\PreferencesContainer.profileKeys) var profileKeys
  @Injected(\PreferencesContainer.externalProfiles) var externProfiles
  @Injected(\PreferencesContainer.stagePrefsURL) var preferenceFileURL
  @Injected(\PreferencesContainer.userProfileId) var activeProfileId
  @Injected(\EnvContainer.stageName) var currentStage
  
  @State var switchToProfileSelection: ExternalUserProfile.ID? = nil
  @State var showCreateForm = false
  @State var showProfileData = false
  
  var indexedProfileItems: [(Int, ExternalUserProfile, KeyBinding?)] {
    externProfiles
      .sorted(by: { $0.created < $1.created })
      .enumerated()
      .map { ($0, $1, KeyBinding.indexed($0 + 1)) }
  }
  
  var body: some View {
    VStack {
      Text(verbatim: "Profiles")
        .modalContentTitle()
      
      VStack {
        ListItems
      }
      .modalContentMain()
      .switchProfileConfirmationDialog(selection: $switchToProfileSelection)
        
      
      SpacedHStack {
        DebugProfileDataButton
        CreateNewProfileButton
      }
      .modalContentFooter()
    }
    .modalContentBody()
    .overlay(alignment: .bottom) {
      if showCreateForm {
        NewProfileFormView(isPresented: $showCreateForm)
          .sheetBottomForm()
      }
    }
    .sheetView(isPresented: $showProfileData, style: JSONView.presentation) {
      VStack(alignment: .leading) {
        JSONView(object: .constant(externProfiles))
        DebugProfileDataSheet
      }
      .presentationBackground(.thickMaterial)
    }
  }
  
  var CreateNewProfileButton: some View {
    FormButton(.secondary, "Create New Profile") {
      withAnimation(.easeInOut(duration: 0.4)) {
        showCreateForm.toggle()
      }
    }
  }
  
  func confirmProfileSwitch(to id: ExternalUserProfile.ID) {
    switchToProfileSelection = id
  }
  
  var ListItems: some View {
    ForEach(indexedProfileItems, id: \.0) { index, profile, keybinding in
      ProfileListItem(profile: profile, listPosittion: index)
        .contentShape(Rectangle())
        .modify(when: profile.id != activeProfileId) { view in
          view
            .onTapGesture {
              confirmProfileSwitch(to: profile.id)
            }
            .buttonShortcut(binding: keybinding) {
              confirmProfileSwitch(to: profile.id)
            }
        }
    }
  }
  
  var DebugProfileDataButton: some View {
    Button("Show Profile Data") {
      showProfileData.toggle()
    }
    .buttonStyle(.link)
    .controlSize(.mini)
  }
  
  var DebugProfileDataSheet: some View {
    HStack {
      LabeledContent("Stage \(currentStage) preference file") {
        Text(preferenceFileURL.filepath.string)
          .monospaced()
      }
      .font(.caption2)
      .opacity(0.7)
      
      Button(preferenceFileURL, using: .finder) {
        Text("Show in Finder")
      }
      .buttonStyle(.link)
    }
  }
}


#Preview("ProfileInfo", traits: .defaultViewModel, .sheetSize(.modalSticky()), .testBordersOn) {
  ProfileListSheetView()
    .padding(16)
    .environment(\.sheetPadding, .init(top: 16, leading: 16, bottom: 16, trailing: 16))
}
