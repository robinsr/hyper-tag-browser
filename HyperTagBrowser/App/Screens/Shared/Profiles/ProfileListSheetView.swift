// created on 12/18/24 by robinsr

import Factory
import IdentifiedCollections
import SwiftUI


struct ProfileListSheetView: View, SheetPresentable {
//  static var presentation: SheetPresentation = .modalSticky(controls: .all)
  
  static var presentation = SheetPresentation(
    idealSize: SheetSizingRange.modal.idealSize,
    controls: .all,
    horizontal: SheetSizingRange.modal.hzOtions(adding: [.sticky]),
    vertical: SheetSizingRange.modal.vertOptions(adding: [.sticky]),
    padding: .zero
  )
  
  @Environment(\.dispatcher) var dispatch
  @Environment(\.sheetPadding) var sheetPadding

  @Injected(\PreferencesContainer.profileKeys) var profileKeys
  @Injected(\PreferencesContainer.externalProfiles) var externProfiles
  @Injected(\PreferencesContainer.appPrefsFile) var prefsFile
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
  
  var bodyPadding: EdgeInsets {
    .init(top: 16, leading: 16, bottom: 16, trailing: 16)
  }
  
  func confirmProfileSwitch(to id: ExternalUserProfile.ID) {
    switchToProfileSelection = id
  }
  
  var body: some View {
    NavigationStack {
      VStack {
        DefaultViewContent
      }
      .padding(bodyPadding)
      .overlay(alignment: .bottom) {
        if showCreateForm {
          NewProfileFormView(isPresented: $showCreateForm)
            .padding(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
            .sheetBottomForm(insets: bodyPadding)
        }
      }
      .navigationTitle("Profiles")
      .navigationDestination(isPresented: $showProfileData) {
        ProfileData
          .modalContentMain(padding: bodyPadding)
          .navigationTitle("Profile Data")
      }
    }
  }
  
  @ViewBuilder
  var DefaultViewContent: some View {
    VStack {
      ProfileItems
    }
    .modalContentMain()
    .switchProfileConfirmationDialog(selection: $switchToProfileSelection)
    
    SpacedHStack {
      ShowProfileDataButton
      CreateNewProfileButton
    }
    .modalContentFooter()
  }
  
  var CreateNewProfileButton: some View {
    FormButton(.secondary, "Create New Profile") {
      withAnimation(.easeInOut(duration: 0.4)) {
        showCreateForm.toggle()
      }
    }
  }
  
  var ProfileItems: some View {
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
  
  // Debug Only
  var ShowProfileDataButton: some View {
    Button("Show Profile Data") {
      showProfileData.toggle()
    }
    .buttonStyle(.link)
    .controlSize(.mini)
  }
  
  var ProfileData: some View {
    GeometryReader { geo in
      VStack(alignment: .leading) {
        ScrollView(.vertical) {
          JsonCodeView(object: .constant(externProfiles))
            .frame(maxWidth: geo.size.width)
        }
        
        ProfileDataButtons
      }
      .onChange(of: geo.size, initial: true) {
        print("ProfileListSheetView/ProfileData Geometry size: \(geo.size.formatted)")
      }
    }
  }
  
  var ProfileDataButtons: some View {
    SpacedHStack {
      LabeledContent {
        Text(prefsFile.string)
          .monospaced()
          .multilineTextAlignment(.leading)
      } label: {
        Text("Preference File")
        Text("Stage \(currentStage)")
      }
      .font(.caption2)
      .opacity(0.7)
      
      Button(prefsFile.fileURL, using: .finder) {
        Text("Show in Finder")
      }
      .buttonStyle(.link)
    }
    .modalContentFooter()
  }
}


#Preview("ProfileInfo", traits: .defaultViewModel, .sheetSize(.modalSticky()), .testBordersOn) {
  ProfileListSheetView()
    .padding(16)
    .environment(\.sheetPadding, .init(top: 16, leading: 16, bottom: 16, trailing: 16))
}
