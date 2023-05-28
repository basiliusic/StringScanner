//
//  StringSource.swift
//  
//
//  Created by basiliusic on 28.05.2023.
//

import Foundation

public protocol StringSource: AnyObject {
    
    var index: Int { get }
    var length: Int { get }
    
    func seekTo(_ offset: Int, origin: SeekOrigin)
    func read(_ length: Int) -> NSString
    func readCharacter() -> Character
    func readScalar() -> UnicodeScalar
    
}
