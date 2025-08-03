// created on 4/6/25 by robinsr

import SwiftUI
import UniformTypeIdentifiers


struct FileImporterConfiguration {
  
    /// The location from the file importer dialog should open
  var folder: URL = .homeDirectory
  
    /// Allow multiple file selection
  var multi: Bool = false
  
    /// The file types that are allowed to be imported
  var allow: [UTType] = [.folder, .content]
  
    /// Pass true to add a tap gesture to the attached view, which will trigger the file importer
  var tapAction: Bool = false
  
    /// A handler called when the file importer is cancelled
  var onCancel: (() -> Void)? = nil
  
    /// A handler called when the file importer fails
  var onFailure: ((Error) -> Void)? = nil
  
    /// A handler called when the file importer successfully imports files
  var onChoice: (([URL]) -> Void)? = nil
  
    /// A closure that returns an array of ``ModelActions`` to be dispatched
    /// when the file importer successfully imports files
  var onChoiceActions: (([URL]) -> [ModelActions])? = nil
}



struct FileImportModifier: ViewModifier {
  @Environment(\.dispatcher) var dispatch
  
  @Binding var isPresented: Bool
  
  var configuration: FileImporterConfiguration
  
  func body(content: Content) -> some View {
    let cfg = configuration
    
    content
      .fileImporter(
        isPresented: $isPresented,
        allowedContentTypes: cfg.allow,
        allowsMultipleSelection: cfg.multi,
        onCompletion: { result in
          switch result {
          case .success(let urls): onImportSuccess(urls)
          case .failure(let error): onImportFailure(error)
          }
        },
        onCancellation: {
          if cfg.onCancel != nil {
            // Call the cancel handler if provided
            cfg.onCancel?()
          } else {
            // Default behavior: just dismiss the importer
            isPresented = false
          }
        }
      )
      .modify(when: cfg.tapAction) { $0
        .onTapGesture {
          isPresented = true
        }
      }
  }
  
  func onImportSuccess(_ urls: [URL]) {
    // This function can be used to handle successful imports if needed
    if let onChoiceFn = configuration.onChoice {
      onChoiceFn(urls)
      return
    }
    
    if let onChoiceActionsFn = configuration.onChoiceActions {
      // If onChoiceActions is provided, we handle it here
      let actions = onChoiceActionsFn(urls)
      
      for action in actions {
        dispatch(action)
      }
      
      return
    }
  }
  
  func onImportFailure(_ error: Error) {
    if configuration.onFailure != nil {
      // Call the failure handler if provided
      configuration.onFailure?(error)
      return
    }
  }
}


extension View {
  
  /**
   * Returns a View configured to import files via SwiftUI's `fileImporter` modifier and the various
   * file-importer-related modifiers. Using the `FileImporterConfiguration` struct, this simplifies
   * the API when creating a file importer, intended allow for cleaner code in the view layer.
   */
  func fileImporter(configuration: FileImporterConfiguration, isPresented: Binding<Bool>) -> some View {
    self.modifier(FileImportModifier(isPresented: isPresented, configuration: configuration))
  }
}
