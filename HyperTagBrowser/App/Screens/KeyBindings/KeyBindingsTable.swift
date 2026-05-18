// created on 11/28/25 by robinsr

import SwiftUI

struct KeyBindingsTable: View, SheetPresentable {
  
  static let presentation: SheetPresentation = .init(
    idealSize: CGSize(width: 920, height: 600),
    controls: .close,
    horizontal: [.fitted, .idealPlus(320)],
    vertical: [.fitted, .idealPlus(200)],
  )
  
  @Environment(\.colorModel) var bgColor
  
  @State var gridRect: CGRect = .zero
  @State var columnCount: Int = 2
  
  static let columnMinWidth: CGFloat = 350
  
  var sortedKeyBindingGroups: [KeyBinding.Group] {
    KeyBinding.Group.allCases
  }
  
  let outerGridRows = [
    GridItem(.adaptive(minimum: Self.columnMinWidth), alignment: .top)
  ]
  
  let innerGridRows = [
    GridItem(.flexible(minimum: 100), alignment: .leading),
    GridItem(.fixed(120), alignment: .trailing),
  ]
  
  func onGridGeometryChange() {
    columnCount = Int((gridRect.width / Self.columnMinWidth).rounded(.down))
  }
  
  var body: some View {
    ScrollView {
      Text("Keyboard Shortcuts")
        .font(.title2)
        .padding()
      
      MasonryColumns(columns: columnCount, spacing: 12) {
        ShortcutGroups
      }
      .padding()
//      .coordinateSpace(name: "KeyBindingsTable")
//      .background(GridGeometrySetter)
    }
    .minimumSize(KeyBindingsScreen.screenSize)
//    .onChange(of: gridRect) {
//      onGridGeometryChange()
//    }
  }
  
  var GridGeometrySetter: some View {
    GeometryReader { geometry in
      Rectangle()
        .fill(Color.clear)
        .onChange(of: geometry.size) {
          gridRect = geometry.frame(in: .named("KeyBindingsTable"))
        }
    }
  }
  
  var _body: some View {
    ScrollView {
      VStack {
        LazyVGrid(columns: outerGridRows, alignment: .center, spacing: 24) {
          ShortcutGroups
        }
      }
      .scenePadding()
    }
    .minimumSize(KeyBindingsScreen.screenSize)
  }
  
  var ShortcutGroups: some View {
    ForEach(sortedKeyBindingGroups.indexed, id: \.1.id) { index, group in
      GroupBox {
        LazyVGrid(columns: innerGridRows, spacing: 4) {
          ForEach(group.members, id: \.id) { keybinding in
            Text(.init(keybinding.name))
            KeyBindingsTableRow(binding: keybinding)
          }
        }
        .padding(4)
      } label: {
        Text(group.name)
          .styleClass(.sectionLabel)
      }
      .groupBoxStyle(.bordered)
    }
  }
}

struct MasonryColumns: Layout {
    var columns: Int = 2
    var spacing: CGFloat = 12

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let width = proposal.width ?? 0
        let columnWidth = (width - CGFloat(columns - 1) * spacing) / CGFloat(columns)

        var columnHeights = Array(repeating: 0.0, count: columns)

        // Simulate placement to figure out the total height
        for subview in subviews {
            let size = subview.sizeThatFits(
                .init(width: columnWidth, height: nil)
            )
            // pick the shortest column so far
            let idx = columnHeights.enumerated().min(by: { $0.element < $1.element })!.offset
            columnHeights[idx] += size.height + spacing
        }

        let height = (columnHeights.max() ?? 0) - spacing
        return CGSize(width: width, height: max(0, height))
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let width = bounds.width
        let columnWidth = (width - CGFloat(columns - 1) * spacing) / CGFloat(columns)
        var columnHeights = Array(repeating: bounds.minY, count: columns)

        for subview in subviews {
            let size = subview.sizeThatFits(
                .init(width: columnWidth, height: nil)
            )
            let idx = columnHeights.enumerated().min(by: { $0.element < $1.element })!.offset

            let x = bounds.minX + CGFloat(idx) * (columnWidth + spacing)
            let y = columnHeights[idx]

            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: .init(width: columnWidth, height: size.height)
            )

            columnHeights[idx] += size.height + spacing
        }
    }
}

#Preview(
  "KeyBindingsTable",
  traits: .fixedLayout(
    width: KeyBindingsScreen.screenSize.width,
    height: KeyBindingsScreen.screenSize.height
  ), .testBordersOff
) {
  KeyBindingsTable()
    .frame(
      width: KeyBindingsScreen.screenSize.width,
      height: KeyBindingsScreen.screenSize.height
    )
}
