//
//  File.swift
//  
//
//  Created by basiliusic on 28.05.2023.
//

import Foundation

extension NSString {
    
    func scalar(at index: Int) -> UnicodeScalar {
        let char = character(at: index)
        
        guard let scalar = UnicodeScalar(char) else {
            return .init(UInt8(char))
        }
        
        return scalar
    }
    
}
