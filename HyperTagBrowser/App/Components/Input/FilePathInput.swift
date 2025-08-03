// created on 1/8/25 by robinsr

import SwiftUI

struct FilePathInput: View {
  
  @Environment(\.location) var currentLocation
  
  @Binding var selected: URL?
  var label: String
  var allowedTypes: AllowedFileTypes
  
  @State var fileDialogShowing = false
  
  var buttonText: String {
    selected != nil ? "Change File" : "Choose File"
  }
  
  var inputIsUnset: Bool {
    selected == nil || selected == SystemLocation.null
  }
  
  func onFileImporterCompletion(_ result: Result<[URL], Error>) {
    if case .success(let urls) = result {
      self.selected = urls.first
    }
    
    if case .failure(let error) = result {
      print("File path import error: \(error.legibleDescription)")
    }
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 10) {
        Text(label)
        ActionButton
      }
      
      if !inputIsUnset {
        CurrentInputValue
      }
    }
    .contextMenu {
      ButtonContextMenu
    }
    .fileImporter(
      isPresented: $fileDialogShowing,
      allowedContentTypes: AllowedFileTypes.types(for: allowedTypes),
      allowsMultipleSelection: false,
      onCompletion: onFileImporterCompletion)
  }
  
  
  var ActionButton: some View {
    Button {
      fileDialogShowing.toggle()
    } label: {
      Label(inputIsUnset ? "Choose File" : "Change File", systemImage: "folder")
    }
    .labelStyle(.titleOnly)
    .buttonStyle(.bordered)
    .controlSize(.small)
  }
  
  
  var CurrentInputValue: some View {
    Text(selected?.filepath.string ?? "")
      .lineLimit(1)
      .truncationMode(.head)
      .foregroundStyle(.disabledControlTextColor)
  }
  
  
  @ViewBuilder
  var ButtonContextMenu: some View {
    Button("Use curernt location") {
      selected = currentLocation
    }
    
    Button("Clear Selection") {
      selected = SystemLocation.null
    }
    .disabled(inputIsUnset)
  }
}
