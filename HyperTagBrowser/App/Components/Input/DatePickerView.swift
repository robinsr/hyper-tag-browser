// created on 10/29/24 by robinsr

import SwiftUI

struct AdjustFilterDateView: View, SheetPresentable {
  static let presentation: SheetPresentation = .infoFitted(controls: .close)
  
  typealias TagDomain = FilteringTag.TagDomain

  var tag: FilteringTag
  var onSelection: (FilteringTag) -> ()
  var onCancel: () -> ()
  
  @State var date: Date = .now
  @State var boundary: DateBoundary = .on
  @State var tagDomain: TagDomain = .creation
  
  var validTagDomains: [TagDomain] = [.creation]
  
  private func onConfirm() {
    let date = BoundedDate(date: date, bounds: boundary)
    
    guard
      let newFilter: FilteringTag = .timeBounded(date: date, domain: tagDomain)
    else {
      return
    }
    
    onSelection(newFilter)
  }
  
  var body: some View {
    VStack {
      Text("Adjust Date Filter")
        .modalContentTitle()
      
      Form {
        TargetAttributePicker
        OperationTypePicker
        DateValuePicker
      }
      .formStyle(.columns)
      .modalContentMain()
      
      HStack {
        FormCancelButton(action: onCancel)
        FormConfirmButton(action: onConfirm)
      }
      .modalContentFooter()
    }
    .modalContentBody()
    .onAppear {
      date = tag.boundedDate?.date ?? .now
      boundary = tag.boundedDate?.bounds ?? .on
      tagDomain = tag.domain
    }
  }
  
  var TargetAttributePicker: some View {
    Picker("Filter on...", selection: $tagDomain) {
      ForEach(validTagDomains, id: \.self) { domain in
        Text(domain.description)
          .tag(domain)
      }
    }
  }
  
  var OperationTypePicker: some View {
    Picker("Date Range", selection: $boundary) {
      ForEach(DateBoundary.allCases, id: \.self) { value in
        Text(value.description.capitalized)
          .tag(value)
      }
    }
    .pickerStyle(.menu)
  }
  
  var DateValuePicker: some View {
    DatePicker(selection: $date, displayedComponents: [.date]) {
      Text("Date")
    }
    .datePickerStyle(.automatic)
  }
}
