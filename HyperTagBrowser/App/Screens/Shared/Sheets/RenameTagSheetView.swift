// created on 9/18/24 by robinsr

import Factory
import SwiftUI

struct RenameTagSheetView: View, SheetPresentable {
  static let presentation: SheetPresentation = .modalSticky(controls: .close)
  
  private let logger = EnvContainer.shared.logger("RenameTagSheetView")
  
  var tag: FilteringTag
  var scope: BatchScope = .all
  
  @Environment(\.dispatcher) var dispatch
  @Environment(\.dismiss) var dismiss
  
  @State var renameText = TextFieldModel(validate: [.presence])
  @State private var selectedScope: BatchScope = .all
  @State private var isPresented: Bool = false
  
  @FocusState var isFocused
  
  
  func onProceed() {
    guard renameText.isValid else { return }
    
    dispatch(.renameTag(tag, to: renameText.read(), scope: selectedScope))
    dismiss()
  }
  
  func onCancel() {
    dismiss()
  }
  
  var body: some View {
    VStack {
      Text("Rename Tag")
        .modalContentTitle()
      
      VStack(spacing: 24) {
        InfoHeader
        InfoForm
      }
      .modalContentMain(alignment: .center)
      
      FullWidth(alignment: .trailing, spacing: 8) {
        FormCancelButton(action: onCancel)
        FormConfirmButton("Perform Rename", action: onProceed)
      }
    }
    .modalContentBody()
    .onAppear {
      isFocused = true
      selectedScope = scope
    }
  }
  
  var InfoHeader: some View {
    HStack {
      Text("Renaming tag")
      TagLabel(tag: tag)
      Text("to:")
    }
  }
  
  var InfoForm: some View {
    Form {
      TagValueInput
      ContentScopePicker
    }
    .formStyle(.columns)
    .onSubmit(onProceed)
  }
  
  var TagValueInput: some View {
    TextField("Tag Value", text: $renameText.rawValue)
      .textFieldStyle(.form(err: $renameText.error))
  }
  
  var ContentScopePicker: some View {
    MenuSelect(
      selection: $selectedScope,
      using: BatchScope.self,
      unselected: "Apply to...",
      presentation: .picker,
      itemLabel: { val in
        Text(.init("In: **\(val.value)**"))
      })
    .pickerStyle(.menu)
  }
}



#Preview("RenameTagSheetView", traits: .defaultViewModel, .sizeThatFitsLayout) {
  @Previewable @State var tag = TestData.fruitTags[0]
  
  RenameTagSheetView(tag: tag)
    .padding()
    .background(.regularMaterial)
}
