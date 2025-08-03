// created on 10/28/24 by robinsr

import SwiftUI
import Flow


struct CreateQueueView: View, SheetPresentable {
  static let presentation: SheetPresentation = .infoFitted(controls: .close)
  
  @Environment(\.dispatcher) var dispatch
  
  @State var queueName = TextFieldModel(validate: [.presence])
  
  var body: some View {
    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
      Section {
        NewQueueForm
          .modalContentBody()
      } header: {
        Text("Create a new Queue")
          .modalContentTitle()
      }
    }
  }
  
  var NewQueueForm: some View {
    Form {
      TextField("", text: $queueName.rawValue, prompt: Text("Queue Name"))
        .textFieldStyle(.roundedBorder)
        .controlSize(.extraLarge)
      
      if let errorMsg = queueName.error {
        Text(errorMsg)
          .font(.caption)
          .foregroundStyle(.red)
      }
      
      FullWidth(alignment: .trailing, spacing: 8) {
        FormCancelButton {
          dispatch(.showSheet(.none))
        }
        
        FormConfirmButton("Create", action: onSubmit)
      }
    }
    .onSubmit(of: .text, onSubmit)
  }
  
  func onSubmit() {
    if queueName.isValid {
      dispatch(.createQueue(name: queueName.read()))
      dispatch(.showSheet(.none))
    }
  }
}


#Preview("", traits: .defaultViewModel, .previewSize(.dialog)) {
  CreateQueueView()
}

