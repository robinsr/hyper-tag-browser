// created on 2/12/25 by robinsr

//import Defaults
import Factory
import Foundation
import SwiftUI


struct ProfileListItem: View {
  private let logger = EnvContainer.shared.logger("ProfileInfoListItem")
  
  @Environment(\.dispatcher) var dispatch
  
  @Injected(\PreferencesContainer.userProfileId) var activeProfileId
  
  var profile: ExternalUserProfile
    /// The index of the profile in the list. If set, the profile will be displayed with a shortcut key
  var listPosittion: Int? = nil
  
  @State var isEditing = false
  @State var textModel = TextFieldModel(validate: [.presence])
  @State var isFileChooserShowing = false
  @State var isDeleting = false
  
  var isActive: Bool { profile.id == activeProfileId }
  
  
  func onDatabaseFileChosen(_ urls: [URL]) {
    if let newURL = urls.first {
      profile.update(key: profile.keys.dbFile, value: newURL)
    } else {
      profile.update(key: profile.keys.dbFile, value: .null)
    }
  }
  
  var fileChooserConfig: FileImporterConfiguration {
    .init(
      folder: profile.dbFile.directoryURL,
      allow: [.sqlite],
      onCancel: {
        isFileChooserShowing = false
      },
      onFailure: { err in
        logger.emit(.error, .raised("file importer returned error", err))
        dispatch(.notify(.error("Error importing file")))
      },
      onChoice: { urls in
        onDatabaseFileChosen(urls)
      }
    )
  }
  
  var body: some View {
    HStackSplit(spacing: 12) {
      IsCheckedIcon
      
      if let index = listPosittion, index.isBetween(0...9) {
        KeyBindingIconLabel(symbol: .person, shortcut: .indexed(index))
      }
      
      SwitchView(isSwitched: $isEditing) {
        NameAndDatabaseFile
      } onSwitched: {
        EditNameTextField
      }
    } trailing: {
      ProfileItemContextMenu
    }
    .padding(.vertical, 4)
    .deleteProfileConfirmationDialog(for: profile, isPresented: $isDeleting)
  }
  
  var NameAndDatabaseFile: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(profile.name)
      
      Text(profile.dbFile.filename)
        .prefixWithSymbol(.database)
        .font(.caption)
        .foregroundColor(.disabledControlTextColor)
        .lineLimit(1)
        .truncationMode(.tail)
        .visible(profile.hasCustomDbFile)
    }
  }
  
  var EditNameTextField: some View {
    TextField("", text: $textModel.rawValue)
      .textFieldStyle(.inlineField(err: $textModel.error))
      .onSubmit {
        if textModel.isValid {
          profile.update(key: profile.keys.name, value: textModel.read())
          isEditing = false
        }
      }
      .onKeyPress(.escape) {
        isEditing = false
        return .handled
      } 
      .onAppear {
        textModel.rawValue = profile.name
      }
  }
  
  var IsCheckedIcon: some View {
    Image(systemName: isActive ? "checkmark.circle" : "circle")
      .resizable()
      .frame(width: 16, height: 16)
  }
  
  var ProfileItemContextMenu: some View {
    Menu {
      Button("Copy ID") {
        dispatch(.copyToClipboard(label: "Profile ID of \(profile.name):", value: profile.id))
      }
      
      ContextMenuButton("Rename", .editText) {
        isEditing.toggle()
      }
      
      if profile.hasCustomDbFile {
        ContextMenuButton("Change Database File", .database) {
          isFileChooserShowing.toggle()
        }
        
        ContextMenuButton("Reset Database File", .database) {
          profile.update(key: profile.keys.dbFile, value: .null)
        }
      }
      
      if !profile.hasCustomDbFile {
        ContextMenuButton("Choose Database File", .database) {
          isFileChooserShowing.toggle()
        }
      }
      
      Divider()
      
      ContextMenuButton("Delete Profile", .delete) {
        isDeleting = true
      }
      
    } label: {
      Label("Profile Options", systemImage: "ellipsis.circle")
        .labelStyle(.iconOnly)
    }
    .menuStyle(.toolbar)
    .contextMenuSymbols(enabled: false)
    .fileImporter(
      configuration: fileChooserConfig,
      isPresented: $isFileChooserShowing
    )
  }
}
