// created on 2/10/25 by robinsr

import SwiftUI

struct ImageDiffSheetView: View, SheetPresentable {
  static let presentation: SheetPresentation = .modalFitted(controls: .close)
  
  var lhs: URL
  var rhs: URL
  
  let onCancel: () -> Void
  let onConfirm: () -> Void
  
  @State var explainerVisible = false
  
  var body: some View {
    VStack {
      Text("ReplaceImageContents.Title")
        .modalContentTitle()
      
      Text("ReplaceImageContents.Confirm")
        .styleClass(.controlLabel)
        .popover(isPresented: $explainerVisible, arrowEdge: .bottom) {
          ExplainText
        }
        .onHover { over in
            explainerVisible = over
        }
      
      GroupBox {
        HStack(alignment: .center, spacing: 12) {
          ImageBox(lhs)
          
          Image(systemName: "arrow.right.circle.fill")
            .font(.title)
          
          ImageBox(rhs)
        }
        .padding(.init(top: 12, leading: 20, bottom: 12, trailing: 20))
        .fillFrame(.horizontal)
      }
      .padding(.vertical, 24)

      FullWidth(alignment: .trailing, spacing: 12) {
        FormCancelButton(action: onCancel)
        FormConfirmButton("Replace", action: onConfirm)
      }
    }
    .modalContentBody()
  }
  
  func ImageBox(_ url: URL) -> some View {
    Image(nsImage: NSImage(byReferencing: url))
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(maxWidth: 200, maxHeight: 200)
      .background {
        RoundedRectangle(cornerRadius: 2)
          .fill(.black.opacity(0.4))
      }
  }
  
  var ExplainText: some View {
    Text("ReplaceImageContents.Help")
      .padding(12)
      .frame(width: 300)
  }
}

#Preview("ImageDiffSheetView", traits: .sizeThatFitsLayout) {
  VStack {
    ImageDiffSheetView(
      lhs: TestData.testImageURLs.randomElement()!,
      rhs: TestData.testImageURLs.randomElement()!,
      onCancel: {},
      onConfirm: {})
  }
  .scenePadding()
  .frame(width: 500, height: 400)
  .background(.background)
  .colorScheme(.dark)
}
