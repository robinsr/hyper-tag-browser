// created on 9/18/24 by robinsr

import IdentifiedCollections
import SwiftUI
import Defaults


typealias PanMater = NSVisualEffectView.Material
typealias PanBlend = NSVisualEffectView.BlendingMode
typealias PanState = NSVisualEffectView.State


struct PanelMaterialView<Content: View>: View {
  var material: PanMater = .fullScreenUI
  var state: PanState = .active
  var emphasized: Bool = true
  
  @ViewBuilder let content: () -> (Content)
  
  @Default(.backgroundOpacity) var bgOpacity
  
  
//  material: .popover,
  var body: some View {
    ZStack {
      if bgOpacity < 100 {
        VisualEffectView(material: material,
                         blendingMode: .behindWindow,
                         state: state,
                         emphasized: emphasized)
      }
      content()
    }
  }
}

struct InnerMaterialView<Content: View>: View {
  var material: PanMater = .headerView
  var state: PanState = .followsWindowActiveState
  var emphasized: Bool = true
  
  @ViewBuilder let content: () -> (Content)
  
  var body: some View {
    ZStack {
      VisualEffectView(material: material,
                       blendingMode: .withinWindow,
                       state: state,
                       emphasized: emphasized)
      content()
    }
  }
}

fileprivate struct TestMaterial: Identifiable {
  var id: String
  var material: PanMater
}



#Preview() {
  let testcases: IdentifiedArrayOf<TestMaterial> = [
    TestMaterial(id: "contentBackground", material: .contentBackground),
    TestMaterial(id: "fullScreenUI", material: .fullScreenUI),
    TestMaterial(id: "headerView", material: .headerView),
    TestMaterial(id: "hudWindow", material: .hudWindow),
    TestMaterial(id: "menu", material: .menu),
    TestMaterial(id: "popover", material: .popover),
    TestMaterial(id: "selection", material: .selection),
    TestMaterial(id: "sheet", material: .sheet),
    TestMaterial(id: "sidebar", material: .sidebar),
    TestMaterial(id: "titlebar", material: .titlebar),
    TestMaterial(id: "toolTip", material: .toolTip),
    TestMaterial(id: "underPageBackground", material: .underPageBackground),
    TestMaterial(id: "underWindowBackground", material: .underWindowBackground),
    TestMaterial(id: "windowBackground", material: .windowBackground),
]
  
  ZStack {
    HStack {
      VStack {
        Text("PanelMaterialView")
          .font(.caption)
        
        ForEach(testcases, id: \.id) { test in
          PanelMaterialView(material: test.material) {
            Text(test.id).font(.caption2)
          }
          .frame(height: 80)
        }
      }
      
      Spacer(minLength: 5)
      
      VStack {
        Text("InnerMaterialView")
          .font(.caption2)
        
        ForEach(testcases, id: \.id) { test in
          InnerMaterialView(material: test.material) {
            Text(test.id).font(.caption2)
          }
          .frame(height: 80)
        }
      }
    }
  }
  .scenePadding()
  .background(.gray)
}
