//
//  StringRawSource.swift
//  
//
//  Created by basiliusic on 28.05.2023.
//

import Foundation

/// Provides consecutive access for stored string
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
    
    func seekTo(
        _ offset: Int,
        origin: SeekOrigin
    ) {
        switch origin {
        case .start:
            index = min(max(offset, 0), length)
        case .current:
            index = min(max(index + offset, 0), length)
        case .end:
            index = min(max(length + offset, 0), length)
        }
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
