//
//  StringSource.swift
//  
//
//  Created by basiliusic on 28.05.2023.
//

import Foundation

/// Provides consecutive access to string
public protocol StringSource: AnyObject {
    
    /// Current index in source
    var index: Int { get }
    /// Total lenght of string (NSString length)
    var length: Int { get }
        
    /// Reposition the index of the given source
    /// - Parameters:
    ///   - offset: The new offset
    ///   - origin: The origin of the new offset
    func seekTo(_ offset: Int, origin: SeekOrigin)
    /// Read substring from current index and seek index to substring length
    /// - Parameter length: Length of reading substring
    /// - Returns: Read substring in source. Empty if nothing to read
    func read(_ length: Int) -> NSString
    /// Read character from source and seek index to character size
    /// - Returns: Read character
    func readCharacter() -> Character
    /// Read scalar from source and seek index to scalar size
    /// - Returns: Character scalar
    func readScalar() -> UnicodeScalar
    
}
