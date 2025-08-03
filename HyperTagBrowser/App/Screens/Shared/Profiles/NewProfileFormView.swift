// created on 2/19/25 by robinsr

import SwiftUI


struct NewProfileFormView: View {
  
  @Environment(\.dispatcher) var dispatch
  
  @Binding var isPresented: Bool
  
  @State var newProfileText = TextFieldModel(validate: [.presence])
  
  func onSumit() {
    if newProfileText.isValid {
      dispatch(.createProfile(name: newProfileText.read()))
    }
    
    isPresented = false
  }

  var body: some View {
    Form {
      VStack(spacing: 12) {
        
        Text("Add Profile")
          .styleClass(.sectionLabel)
          .fillFrame(.horizontal, alignment: .leading)
        
        TextField(text: $newProfileText.rawValue, prompt: Text("New Profile Name")) {
          Text("Profile Name")
        }
        .labelsHidden()
        .textFieldStyle(.form(err: $newProfileText.error))
        
        HStack(spacing: 12) {
          CancelButton
          ConfirmButton
        }
        .fillFrame(.horizontal, alignment: .trailing)
      }
    }
    .onSubmit {
      withAnimation {
        onSumit()
      }
    }
  }
  
  var CancelButton: some View {
    FormCancelButton("Cancel") {
      withAnimation {
        isPresented = false
      }
    }
  }
  
  var ConfirmButton: some View {
    FormConfirmButton("Create") {
      onSumit()
    }
    .focusable()
  }
}

#Preview("NewProfileFormView", traits: .defaultViewModel, .sheetSize(.alert())) {
  NewProfileFormView(isPresented: .constant(true))
}
