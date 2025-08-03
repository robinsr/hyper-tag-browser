// created on 10/14/24 by robinsr

import SwiftUI
import Factory


struct TextFieldSheet: View, SheetPresentable {
  
  static let presentation: SheetPresentation = .textfield
  
  var logger = EnvContainer.shared.logger("TextFieldSheet")
  
  @Environment(\.modifierKeys) var mods
  
  var filename: String
  var onUpdate: (String) -> () = { _ in }
  var onCancel: () -> () = {}
  
  @FocusState var focusRename: Bool

  @State var textModel = TextFieldModel(validate: [
    .presence, .disallow_forwardslash, .disallow_colon, .filename_extension
  ])
  
  var body: some View {
    TextField("", text: $textModel.rawValue, prompt: Text(""))
      .textFieldStyle(.prominent(icon: .editText, err: $textModel.error))
      .onSubmit {
        if textModel.isValid {
          onUpdate(textModel.read())
        }
      }
      .onAppear {
        textModel.rawValue = filename
        focusRename = true
      }
//      .onKeyPress(.escape) {
//        onCancel()
//        return .handled
//      }
      .viewKeyBinding(.dismiss, mods) {
        onCancel()
      }
  }
}



#Preview("TextFieldSheet", traits: .defaultViewModel, .fixedLayout(width: 550, height: 100)) {
  
  VStack {
    TextFieldSheet(filename: "RenameThisFile.txt") {
      print("Renaming file to: \($0)")
    } onCancel: {
      print("Cancelled renaming file")
    }
  }
  .fillFrame()
  .background(.background)
}
