//
//  CaseIterable+.swift
//  TaggedFileBrowser
//
//  Created by Ryan Robinson on 5/17/26.
//


extension CaseIterable where Self: Equatable {
  var nextCase: Self {
    let all = Self.allCases
    let idx = all.firstIndex(of: self)!
    let next = all.index(after: idx)
    return all[next == all.endIndex ? all.startIndex : next]
  }
}
