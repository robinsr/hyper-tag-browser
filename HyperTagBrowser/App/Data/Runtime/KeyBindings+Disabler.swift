// created on 6/8/25 by robinsr

extension KeyBinding {
  
  enum DisableWhen: Hashable {
    case anySheet
    case sheets([AppSheet])
    
    var sheetIds: [AppSheet.ID] {
      switch self {
      case .anySheet:
        return AppSheet.Cases.allCases.map { $0.id }
      case .sheets(let sheets):
        return sheets.map { $0.id }
      }
    }
    
    func contains(_ sheet: AppSheet) -> Bool {
      switch self {
      case .anySheet:
        return true
      case .sheets(let sheets):
        return sheets.contains(sheet)
      }
    }
  }
}


extension Sequence where Element == KeyBinding.DisableWhen {
  func containsAnySheet() -> Bool {
    return self.contains { $0 == .anySheet }
  }
  
  func contains(sheet: AppSheet?) -> Bool {
    guard let sheet = sheet else { return false }
    
    return self.contains { $0.contains(sheet) }
  }
}
