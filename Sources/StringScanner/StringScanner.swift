//
//  StringScanner.swift
//  Playlist
//
//  Created by basiliusic on 25.05.2023.
//

import Foundation

public final class StringScanner {
    
    // MARK: - Types
    
    public typealias Index = Int
    public typealias ScanUpResult = (reached: Bool, string: String)
    
    // MARK: - Constants
    
    static let doubleHexSet: CharacterSet = .init(charactersIn: "0123456789ABCDEFabcdef+-.xX")
    static let doubleSet: CharacterSet = .init(charactersIn: "0123456789-+.eE")
    
    static let intSet: CharacterSet = .init(charactersIn: "0123456789-+")
    static let hexSet: CharacterSet = .init(charactersIn: "0123456789ABCDEFabcdef+-xX")
    
    static let unsignedIntSet: CharacterSet = .init(charactersIn: "0123456789+")
    static let unsignedHexSet: CharacterSet = .init(charactersIn: "0123456789ABCDEFabcdef+xX")
    
    // MARK: - Properties
    
    private var source: StringSource
    
    public var length: Int {
        source.length
    }
        
    public var isAtEnd: Bool {
        source.index >= length
    }
    
    public var index: Int {
        source.index
    }
    
    public var charactersToBeSkipped: CharacterSet? = .whitespacesAndNewlines
    
    public var caseSensitive: Bool = false
    
    public init(_ source: StringSource) {
        self.source = source
    }
    
    public convenience init(string: String) {
        self.init(StringRawSource(string))
    }
    
    public convenience init(
        file url: URL,
        encoding: String.Encoding = .utf8
    ) throws {
        let string = try String(
            data: Data(contentsOf: url),
            encoding: encoding
        )
        
        guard let string else {
            throw ScannerError.cantLoadFile
        }
        
        self.init(StringRawSource(string))
    }

    // MARK: - Seek
    
    public func seek(to index: Int) {
        assert(
            index >= 0 && index <= length,
            "Index must be greater or equal to zero and less than string length"
        )
        
        source.seekTo(index, origin: .start)
    }
    
    // MARK: - Substring
    
    public subscript(_ index: Index) -> Character {
        assert(
            index >= 0 && index <= length,
            "Index must be greater or equal to zero and less than string length"
        )
        
        let prevIndex = source.index
        source.seekTo(index, origin: .start)
        let character = source.readCharacter()
        source.seekTo(prevIndex, origin: .start)
        
        return character
    }
    
    public subscript(_ range: Range<Index>) -> String {
        let prevIndex = source.index
        source.seekTo(range.lowerBound, origin: .start)
        let text = source.read(range.count)
        source.seekTo(prevIndex, origin: .start)
        
        return text as String
    }
    
    // MARK: - Scanning Up
    
    public func scanUpToCharacters(from set: CharacterSet) -> ScanUpResult {
        guard !set.isEmpty else {
            assertionFailure("Character set should not be empty")
            
            return (false, "")
        }
        
        var reached: Bool = false
        var range: NSRange = .init(location: source.index, length: 0)
        
        while !isAtEnd {
            if skipIfNeeded() {
                range.length += 1
                
                continue
            }
            
            let scalar = source.readScalar()
            if set.contains(scalar) {
                reached = true
                
                break
            }
            
            range.length += 1
        }
        
        source.seekTo(range.location, origin: .start)
        let string = source.read(range.length) as String
        
        return (reached, string)
    }
    
    public func scanUpToString(_ substring: String) -> ScanUpResult {
        guard !substring.isEmpty else {
            assertionFailure("Substring should not be empty")
            
            return (false, "")
        }
        
        let nsSubstring = substring as NSString
        let firstCharacter = nsSubstring.substring(to: 1)
        var reached: Bool = false
        var range: NSRange = .init(location: source.index, length: 0)
        
        var compareOptions: NSString.CompareOptions = []
        if !caseSensitive {
            compareOptions.formUnion(.caseInsensitive)
        }
        
        while !isAtEnd {
            if skipIfNeeded() {
                range.length += 1
                
                continue
            }
            
            let distanceToEnd = length - source.index
            
            if distanceToEnd < nsSubstring.length {
                range.length += distanceToEnd
                
                break
            }
            
            let prevIndex = source.index
            if source.read(1).compare(firstCharacter, options: compareOptions) == .orderedSame {
                source.seekTo(prevIndex, origin: .start)
                
                let sourceString = source.read(nsSubstring.length)
                if sourceString.compare(substring, options: compareOptions) == .orderedSame {
                    reached = true
                    
                    break
                }
                
                // Seek to next index after current character
                source.seekTo(prevIndex + 1, origin: .start)
            }
                        
            range.length += 1
        }
        
        source.seekTo(range.location, origin: .start)
        let string = source.read(range.length) as String
        
        return (reached, string)
    }
    
    // MARK: - Scanning
        
    public func scanCharacter() -> Character? {
        guard !isAtEnd else { return nil }
        
        return source.readCharacter()
    }
    
    public func scanCharacters(from set: CharacterSet) -> String? {
        guard !set.isEmpty else {
            assertionFailure("Character set should not be empty")
            
            return nil
        }
        
        var range: NSRange = .init(location: source.index, length: 0)
        
        while !isAtEnd {
            if !set.contains(source.readScalar()) {
                break
            }
            
            range.length += 1
        }
        
        source.seekTo(range.location, origin: .start)
        
        if range.length > 0 {
            return source.read(range.length) as String
        } else {
            return nil
        }
    }
    
    public func scanString(_ searchString: String) -> String? {
        guard !searchString.isEmpty else {
            assertionFailure("Substring should not be empty")
            
            return nil
        }
        
        let prevIndex = source.index
        
        let nsString = searchString as NSString
        let distanceToEnd = length - source.index
        guard distanceToEnd >= nsString.length else {
            return nil
        }
        
        let sourceString = source.read(nsString.length)
        
        var options: NSString.CompareOptions = []
        if !caseSensitive {
            options.formUnion(.caseInsensitive)
        }
        if sourceString.compare(searchString, options: options) == .orderedSame {
            return sourceString as String
        }
        
        source.seekTo(prevIndex, origin: .start)
        
        return nil
    }
    
    public func scanDouble(representation: NumberRepresentation = .decimal) -> Double? {
        let prevIndex = source.index
        
        let set = representation == .decimal ? Self.doubleSet : Self.doubleHexSet
        if let string = scanCharacters(from: set) {
            if let val = Double(string) {
                return val
            } else {
                source.seekTo(prevIndex, origin: .start)
            }
        }
        
        return nil
    }
    
    public func scanFloat(representation: NumberRepresentation = .decimal) -> Float? {
        let prevIndex = source.index
        
        let set = representation == .decimal ? Self.doubleSet : Self.doubleHexSet
        if let string = scanCharacters(from: set) {
            if let val = Float(string) {
                return val
            } else {
                source.seekTo(prevIndex, origin: .start)
            }
        }
        
        return nil
    }
    
    public func scanInt(representation: NumberRepresentation = .decimal) -> Int? {
        let prevIndex = source.index
        
        let set = representation == .decimal ? Self.intSet : Self.hexSet
        if let string = scanCharacters(from: set) {
            if let val = Int(string) {
                return val
            } else {
                source.seekTo(prevIndex, origin: .start)
            }
        }
        
        return nil
    }
    
    public func scanInt32(representation: NumberRepresentation = .decimal) -> Int32? {
        let prevIndex = source.index
        
        let set = representation == .decimal ? Self.intSet : Self.hexSet
        if let string = scanCharacters(from: set) {
            if let val = Int32(string) {
                return val
            } else {
                source.seekTo(prevIndex, origin: .start)
            }
        }
        
        return nil
    }
    
    public func scanInt64(representation: NumberRepresentation = .decimal) -> Int64? {
        let prevIndex = source.index
        
        let set = representation == .decimal ? Self.intSet : Self.hexSet
        if let string = scanCharacters(from: set) {
            if let val = Int64(string) {
                return val
            } else {
                source.seekTo(prevIndex, origin: .start)
            }
        }
        
        return nil
    }
    
    public func scanUInt64(representation: NumberRepresentation = .decimal) -> UInt64? {
        let prevIndex = source.index
        
        let set = representation == .decimal ? Self.unsignedIntSet : Self.hexSet
        if let string = scanCharacters(from: set) {
            if let val = UInt64(string) {
                return val
            } else {
                source.seekTo(prevIndex, origin: .start)
            }
        }
        
        return nil
    }
    
    // MARK: - Skipping
    
    @discardableResult
    public func skipCharacter() -> Bool {
        guard !isAtEnd else { return false }
        
        source.seekTo(1, origin: .current)
        
        return true
    }
    
    @discardableResult
    public func skipCharacter(from set: CharacterSet) -> Bool {
        guard !isAtEnd else { return false }
        
        let scalar = source.readScalar()
        if set.contains(scalar) {
            return true
        }
        
        source.seekTo(-1, origin: .current)
        
        return false
    }
    
    @discardableResult
    public func skipCharacters(from set: CharacterSet) -> Bool {
        scanCharacters(from: set) != nil
    }
        
    @discardableResult
    public func skipString(_ substring: String) -> Bool {
        scanString(substring) != nil
    }
    
    @discardableResult
    public func skipUp(from set: CharacterSet) -> Bool {
        guard !set.isEmpty else {
            assertionFailure("Character set should not be empty")
            
            return false
        }
        
        guard !isAtEnd else { return false }
        
        let prevIndex = source.index
        
        let result = scanUpToCharacters(from: set)
        guard result.reached else {
            source.seekTo(prevIndex, origin: .start)
            
            return false
        }
        
        _ = scanCharacters(from: set)
        
        return true
    }
    
    @discardableResult
    public func skipUp(to substring: String) -> Bool {
        guard !substring.isEmpty else {
            assertionFailure("Substring should not be empty")
            
            return false
        }
        
        let distanceToEnd = length - source.index
        guard distanceToEnd >= substring.count else {
            return false
        }
        
        let prevIndex = source.index
        
        let result = scanUpToString(substring)
        guard result.reached else {
            source.seekTo(prevIndex, origin: .start)
            
            return false
        }
        
        _ = scanString(substring)
        
        return true
    }
    
    // MARK: - Support
    
    func skipIfNeeded() -> Bool {
        guard let charactersToBeSkipped else { return false }
        
        guard !charactersToBeSkipped.isEmpty else {
            assertionFailure("Skip characters set should not be empty")
            
            return false
        }
                
        let scalar = source.readScalar()
        if charactersToBeSkipped.contains(scalar) {
            return true
        }
        
        source.seekTo(-1, origin: .current)
        
        return false
    }
    
}
