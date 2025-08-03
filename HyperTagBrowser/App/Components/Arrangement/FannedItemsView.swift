// created on 4/4/25 by robinsr

import SwiftUI


struct FannedItemsView<Data: Hashable, Content: View>: View {
  
  let data: [Data]
  var maxItems: Int = 22
  var spread: SpreadBehavior = .logarithmic(maxAngle: .degrees(78.0))
  var direction: RotationalDirection = .clockwise
  var anchor: UnitPoint = .center // default anchor point for scaling and rotation
  var size: CGSize = CGSize(width: 200, height: 200) // default size if not specified
  
  @ViewBuilder let content: (Data) -> Content
  
    /// limit the number of fanned items to `maxItems`
  var displayCount: Int {
    min(data.count, maxItems)
  }
  
    /// A N=displayCount array of angular values to apply to items in sequence to give them a fanned effect.
  var rotatedMap: SpreadBehavior.RotationMap {
    spread.rotationMap(itemCount: displayCount).mapValues {
      direction.apply(to: $0) // apply the rotation direction to each angle
    }
  }
  
    /// N=displayCount array of scaling values for items to create a depth effect.
  var scaleValues: [Double] {
    logarithmicScale(count: displayCount, range: 0.9...1.0).reversed()
  }
  
    /// A value of counter-rotation applied to the entire view to keep it visually balanced
  var counterRotate: Angle {
    direction.inverted.apply(to: spread.maxAngle(itemCount: displayCount) / 10)
  }
  
  func rotateItems(_ items: [Data]) -> [RotatingItem] {
    items
      .suffix(maxItems) // limit the number of items to preview
      .reversed() // reverse the items so that the first items receive the most rotation
      .indexed
      .map { index, item in
        RotatingItem(
          id: index,
          angle: rotatedMap[index] ?? .degrees(0),
          scale: scaleValues[index],
          data: item
        )
      }
      .reversed() // reverse again to maintain the order in the view
      .collect()
  }
  
  var body: some View {
    ZStack {
      ForEach(rotateItems(data), id: \.id) { item in
        content(item.data)
          .frame(width: size.width, height: size.height)
          .rotationEffect(item.angle, anchor: anchor)
          .scaleEffect(item.scale, anchor: .center) // scale around the center
          .shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 2)
          .scaleEffect(0.7)
      }
    }
    .rotationEffect(counterRotate)
    .offset(x: -anchor.x * size.width * 0.1,
            y: -anchor.y * size.height * 0.1)
    .frame(width: size.width, height: size.height)
    .overlay(alignment: .bottomTrailing) {
      IconAndCount
        .visible(data.count > 1)
    }
    .background {
      RoundedRectangle(cornerRadius: 8)
        .fill(Color.gray.opacity(0.05))
        .stroke(Color.gray.opacity(0.4), lineWidth: 1.25) // Optional border for visibility
    }
  }
  
  var IconAndCount: some View {
    GridItemThumbnailOverlayView(
      icon: .itemChecked,
      label: "\("item", qty: data.count)",
      alignment: .bottomTrailing
    )
    .fontWeight(.medium)
  }
  
  struct RotatingItem: Identifiable {
    let id: Int
    let angle: Angle
    let scale: Double
    let data: Data
  }
}


#Preview("FannedItemsView Preview", traits: .sizeThatFitsLayout) {
  
  // Adjust gridState.itemWidth as needed to test different grid-based item sizes.
  // This is the intended use for this view (GridItemThumbnailOverlayView uses
  // gridState to adjust the font size to scale with the photo grid item size)
  @Previewable @State var gridState = PhotoGridState(itemWidth: 380)
  
  // Adjust range values as needed for testing
  // eg : 0..<10 for 10 items, 0..<1 for single item, etc.
  @Previewable @State var testDataItems = TestData.testImages(
    limit: 30, resizedTo: .sized(.init(widthHeight: 50), .squared)
  )
  
  @Previewable @State var testMaxAngle: Double = 45.0
  @Previewable @State var testMaxItems: Int = 10
  @Previewable @State var testDirection: RotationalDirection = .anticlockwise
  @Previewable @State var testAnchorX: Double = 0.5
  @Previewable @State var testAnchorY: Double = 0.5
  
  var testAnchor: UnitPoint {
    .init(x: testAnchorX, y: testAnchorY)
  }
  
  let testSpreads: [SpreadBehavior] = [
    .linear(maxAngle: .degrees(testMaxAngle)),
    .logarithmic(maxAngle: .degrees(testMaxAngle)),
    .incremental(maxAngle: .degrees(testMaxAngle), atCount: 10, approach: .linear),
    .incremental(maxAngle: .degrees(testMaxAngle), atCount: 10, approach: .logarithmic)
  ]
    
  
  VStack {
    
    LazyVGrid(columns: [ GridItem(.fixed(400)), GridItem(.fixed(400))]) {
      ForEach(Array(testSpreads.enumerated()), id: \.offset) { index, spread in
        FannedItemsView(
          data: testDataItems,
          maxItems: testMaxItems,
          spread: spread,
          direction: testDirection,
          anchor: testAnchor,
          size: gridState.itemSquare
        ) { nsImage in
          Image(nsImage: nsImage).resizable()
        }
        .overlay(alignment: .topLeading) {
          Text(spread.rawValue).monospaced().opacity(0.7)
        }
      }
    }
    
    Form {
        // TESTING
      Slider(value: $testMaxAngle, in: 0...360) {
        Text("Rotation Angle: \(Int(testMaxAngle))°")
      }
      
      Slider(value: $testAnchorX, in: 0...1) {
        Text("Anchor X: \(String(format: "%.1f", testAnchorX))")
      }
      
      Slider(value: $testAnchorY, in: 0...1) {
        Text("Anchor Y: \(String(format: "%.1f", testAnchorY))")
      }
      
        // TESTING
      Stepper("Display Items Max: \(testMaxItems)", value: $testMaxItems, in: 0...30, step: 1)
      
        // TESTING
      Picker("Label", selection: $testDirection) {
        ForEach(RotationalDirection.allCases, id: \.rawValue) { dir in
          Text(dir.description).tag(dir)
        }
      }
      .pickerStyle(.segmented)
    }
  }
  
  .padding()
  .background {
    Rectangle()
      .fill(Color.darkModeBackgroundColor.opacity(0.8))
  }
  .frame(width: 800, height: 920, alignment: .top)
  .environment(\.photoGridState, gridState)
}
