// created on 5/3/25 by robinsr

import Factory
import SwiftUI


struct DeleteProfileDialogModifier: ViewModifier {
  @Environment(\.dispatcher) var dispatch
  
  @Injected(\PreferencesContainer.externalProfiles) var externProfiles
  @Injected(\PreferencesContainer.userProfileId) var activeProfileId
  
  var deletingProfile: ExternalUserProfile
  @Binding var isDeleting: Bool
  
  @State var showDeleteDataPrompt: Bool = false
    
  var profileName: String { deletingProfile.name }
  var profileId: String { deletingProfile.id }
  var profileDbFileName: String { deletingProfile.dbFile.filepath.baseName }
  
  var isActive: Bool { profileId == activeProfileId }
  var profileCount: Int { externProfiles.count }
  
  func abandonProfileDelete() {
    isDeleting = false
  }
  
  func proceedWithProfileDelete() {
    isDeleting = false
    showDeleteDataPrompt = true
  }
  
  func deleteProfile(dataPolicy: DataRetentionOption) {
    showDeleteDataPrompt = false
    dispatch(.deleteProfile(profileId, data: dataPolicy))
  }
  
  
  func body(content: Content) -> some View {
    content
      .confirmationDialog(DialogTitle, isPresented: $isDeleting) {
        DialogActions
      } message: {
        DialogMessage
      }
      .confirmationDialog(DeleteDataDialogTitle, isPresented: $showDeleteDataPrompt) {
        DeleteDataDialogActions
      } message: {
        DeleteDataDialogMessage
      }
  }

  
    // --------------------
    // MARK: - Dialog Views
    // --------------------
  
  var DialogTitle: Text {
    Text("Delete profile \(profileName.quoted)?")
  }
  
  var DialogMessage: some View {
    if profileCount == 1 {
      Text("This is the last profile. If you delete it, the app will switch to the default profile.")
    }
    
    else if isActive {
      Text("The profile \(profileName.quoted) is currently active. Deletion requires a restart of the app.")
    }
    
    else {
      Text("Are you sure you want to delete \(profileName.quoted)?")
    }
  }
  
  @ViewBuilder
  var DialogActions: some View {
    Button("Cancel", role: .cancel) {
      abandonProfileDelete()
    }
    .keyboardShortcut(.cancelAction)
    
    Button("Delete", role: .destructive) {
      proceedWithProfileDelete()
    }
    .keyboardShortcut(.defaultAction)
  }
  
  
    // ---------------------------------
    // MARK: - Delete Profile Data Views
    // ---------------------------------
  
  var DeleteDataDialogTitle: Text {
    Text("Delete database file for \(profileName.quoted)?")
  }
  
  var DeleteDataDialogMessage: some View {
    Text(profileDbFileName)
      .prefixWithSymbol(.database)
      .monospaced()
  }
  
  @ViewBuilder
  var DeleteDataDialogActions: some View {
    Button("Preserve Data", role: .cancel) {
      deleteProfile(dataPolicy: .preserve)
    }
    .keyboardShortcut(.cancelAction)
    
    Button("Discard Data", role: .destructive) {
      deleteProfile(dataPolicy: .discard)
    }
    .keyboardShortcut(.defaultAction)
  }
}

extension View {
  func deleteProfileConfirmationDialog(for profile: ExternalUserProfile, isPresented: Binding<Bool>) -> some View {
    modifier(DeleteProfileDialogModifier(deletingProfile: profile, isDeleting: isPresented))
  }
}
