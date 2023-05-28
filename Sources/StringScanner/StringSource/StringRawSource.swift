//
//  StringRawSource.swift
//  
//
//  Created by basiliusic on 28.05.2023.
//

import Foundation

class StringRawSource: StringSource {
                    
    // MARK: - Properties
    
    var string: NSString
    var index: Int = 0
    let length: Int
    
    // MARK: - Life cycle
    
    init(_ string: String) {
        self.string = string as NSString
        self.length = self.string.length
    }
    
    // MARK: - StringSource
    
    func seekTo(_ offset: Int, origin: SeekOrigin) {
        var index = self.index
        
        switch origin {
        case .start:
            index = offset
        case .current:
            index += offset
        case .end:
            index = length + offset
        }
        
        self.index = index
            .clamped(in: 0...length)
    }
    
    func read(_ length: Int) -> NSString {
        defer {
            index += length
        }
        
        return string.substring(
            with: .init(
                location: index,
                length: length
            )
        ) as NSString
    }
    
    func readCharacter() -> Character {
        defer {
            index += 1
        }
        
        return Character(string.scalar(at: index))
    }
    
    func readScalar() -> UnicodeScalar {
        defer {
            index += 1
        }
        
        return string.scalar(at: index)
    }
    
}
