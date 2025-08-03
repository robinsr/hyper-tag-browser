// created on 4/9/25 by robinsr

import Defaults
import SwiftUI


extension Defaults {
  
  @available(*, message: "Unused as of 2025-04-09. Remove this warning when it is no longer unused.")
  struct FileSelection: View {
    private let logger = EnvContainer.shared.logger("Toggle.FilePathInput")
    
    var label: String
    var key: Defaults.Key<URL>
    var allowedTypes: AllowedFileTypes
    
    @State var fileDialogShowing = false
    @State var value: URL?
    
    init(label: String, key: Defaults.Key<URL>, allowedTypes: AllowedFileTypes = .all) {
      self.label = label
      self.key = key
      self.allowedTypes = allowedTypes
      self.value = Defaults[key]
    }
    
    func onResult(result: Result<[URL], Error>) {
      do {
        Defaults[key] = try result.get().first!
      } catch {
        logger.emit(.error, "Error selecting file: \(error.localizedDescription)")
      }
    }
    
    var buttonText: String {
      value != nil ? "Change" : "Choose"
    }
    
    var showPath: Bool {
      value != nil && value != SystemLocation.null
    }
    
    var pathValue: String {
      value?.filepath.string ?? ""
    }
    
    var body: some View {
      FilePathInput(selected: $value, label: label, allowedTypes: allowedTypes)
        .onAppear {
          Task {
            for await value in Defaults.updates(key) {
              self.value = value
            }
          }
        }
    }
  }

}
