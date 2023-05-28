//
//  File.swift
//  
//
//  Created by basiliusic on 28.05.2023.
//

import Foundation

extension Comparable {
    
    func clamped(in range: ClosedRange<Self>) -> Self {
        return range.lowerBound > self ? range.lowerBound
        : range.upperBound < self ? range.upperBound
        : self
    }
    
    mutating func clamp(in range: ClosedRange<Self>) {
        self = clamped(in: range)
    }
    
}
