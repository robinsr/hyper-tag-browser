// created on 10/19/24 by robinsr

import SwiftUI
import Flow

struct HorizontalFlowView<Content: View> : View {
  var verticalAlign: VerticalAlignment = .center
  var horizontalAlign: HorizontalAlignment = .center
  
  var spacing: CGFloat = CGFloat(3)
  var itemSpacing: CGFloat? = nil
  var rowSpacing: CGFloat? = nil
  
  var minimizeEmptySpace: Bool = false
  
  var fillAxis: Axis.Set = [.horizontal]
  var fillAlignment: Alignment = .leading
  
  @ViewBuilder let content: () -> (Content)
  
  init(
    vAlign: VerticalAlignment = .center,
    spacing: CGFloat = CGFloat(3),
    flex: FlexibilityBehavior = .minimum,
    minimizeEmptySpace: Bool = false,
    @ViewBuilder content: @escaping () -> (Content)
  ) {
    self.verticalAlign = vAlign
    self.spacing = spacing
    self.minimizeEmptySpace = minimizeEmptySpace
    self.content = content
  }
  
  init(
    vAlign: VerticalAlignment = .center,
    itemSpacing: CGFloat,
    rowSpacing: CGFloat,
    minimizeEmptySpace: Bool = false,
    fillAxis: Axis.Set = [.horizontal],
    fillAlignment: Alignment = .leading,
    @ViewBuilder content: @escaping () -> (Content)
  ) {
    self.verticalAlign = vAlign
    self.itemSpacing = itemSpacing
    self.rowSpacing = rowSpacing
    self.minimizeEmptySpace = minimizeEmptySpace
    self.fillAxis = fillAxis
    self.fillAlignment = fillAlignment
    self.content = content
  }
  
  var body: some View {
    Group {
      if let itemSpacing = itemSpacing, let rowSpacing = rowSpacing {
        HFlow(alignment: verticalAlign,
              itemSpacing: itemSpacing,
              rowSpacing: rowSpacing,
              justified: false,
              distributeItemsEvenly: minimizeEmptySpace) {
          content()
        }
      } else {
        HFlow(alignment: verticalAlign,
              spacing: spacing,
              justified: false,
              distributeItemsEvenly: minimizeEmptySpace) {
          content()
        }
      }
    }
    .fillFrame(fillAxis, alignment: fillAlignment)
  }
}


struct VerticalFlowView<Content: View> : View {
  
  var alignment: Alignment = .center
  var spacing: CGFloat = CGFloat(3)
  var justify: Bool = false
  var distribute: Bool = false
  var maxHeight: CGFloat = 450
  
  @ViewBuilder let content: () -> (Content)
  
  var body: some View {
    VFlow(
      alignment: alignment.horizontal,
      itemSpacing: spacing,
      columnSpacing: spacing,
      justified: justify,
      distributeItemsEvenly: distribute
    ) {
      content()
    }
    .frame(maxHeight: maxHeight)
  }
}
