//
//  StringScanner.swift
//  Playlist
//
//  Created by basiliusic on 25.05.2023.
//

import Foundation

/// Scans string from given source.
/// Class works with `NSString` for performance goal.
public final class StringScanner {
    
    // MARK: - Types
    
    /// Index of stored elements
    public typealias Index = Int
    /// Stores info of scanned data
    /// - Parameter reached: Indicates whether scaner reached search element or not.
    /// - Parameter string: Substring accumulated before scanner reached search element.
    public typealias ScanUpResult = (reached: Bool, string: String)
    
    // MARK: - Constants
    
    static let doubleHexSet: CharacterSet = .init(charactersIn: "0123456789ABCDEFabcdef+-.xX")
    static let doubleSet: CharacterSet = .init(charactersIn: "0123456789-+.eE")
    
    static let intSet: CharacterSet = .init(charactersIn: "0123456789-+")
    static let hexSet: CharacterSet = .init(charactersIn: "0123456789ABCDEFabcdef+-xX")
    
    static let unsignedIntSet: CharacterSet = .init(charactersIn: "0123456789+")
    static let unsignedHexSet: CharacterSet = .init(charactersIn: "0123456789ABCDEFabcdef+xX")
    
    // MARK: - Properties
    
    /// Provides access to string.
    private let source: StringSource
    
    /// Length of the scanning source.
    /// - warning: provides count of Unicode characters count, same as **NSString.length**.
    public var length: Int {
        source.length
    }
    
    /// Indicates when scanner has achieved end of the source.
    public var isAtEnd: Bool {
        source.index >= length
    }
    
    /// Current index in scanning source.
    public var index: Int {
        source.index
    }
    
    /// Character set containing the characters the scanner ignores when looking for a scannable element.
    public var charactersToBeSkipped: CharacterSet? = .whitespacesAndNewlines
    
    /// Flag that indicates whether the receiver distinguishes case in the characters it scans.
    public var caseSensitive: Bool = false
    
    /// Returns a `StringScanner` with specified source.
    /// - Parameter source: Provides consecutive access to string
    public init(_ source: StringSource) {
        self.source = source
    }
    
    /// Returns a `StringScanner` with specified string
    /// - Parameter string: String to scan
    public convenience init(string: String) {
        self.init(StringRawSource(string))
    }
    
    /// Loads file contants from specified `URL` and returns `StringScanner`
    /// - Parameters:
    ///   - url: `URL` to load file
    ///   - encoding: String encoding
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
    
    /// Change current index
    /// - Parameter index: New index
    public func seek(to index: Int) {
        assert(
            index >= 0 && index <= length,
            "Index must be greater or equal to zero and less than string length"
        )
        
        source.seekTo(index, origin: .start)
    }
    
    // MARK: - Substring
    
    /// Get character at specified index
    /// - Parameter index: Index of the character
    /// - Returns: Character stored at index
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
    
    /// Get substring in specified range
    /// - Parameter index: Index of the character
    /// - Returns: Character stored at index
    public subscript(_ range: Range<Index>) -> String {
        let prevIndex = source.index
        source.seekTo(range.lowerBound, origin: .start)
        let text = source.read(range.count)
        source.seekTo(prevIndex, origin: .start)
        
        return text as String
    }
    
    // MARK: - Scanning Up
    
    /// Scans the string until a character from a given character set is encountered, accumulating characters into a string that's returned.
    /// - Parameter set: The set of characters up to which to scan.
    /// - Returns: Result that stores scan info
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
    
    /// Scans the string until a given string is encountered, accumulating characters into a string that's returned.
    /// - Parameter substring: The 
    /// - Returns: Result that stores scan info
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
    
    /// Scans next characters and returns it
    /// - Returns: Character stored at current index
    public func scanCharacter() -> Character? {
        guard !isAtEnd else { return nil }
        
        return source.readCharacter()
    }
    
    /// Scans the string as long as characters from a given character set are encountered, accumulating characters into a string that's returned.
    /// - Parameter set: The set of characters to scan.
    /// - Returns: Upon return, contains the characters scanned.
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
    
    /// Scans a given string, returning an equivalent  string object if a match is found.
    /// - Parameter searchString: The string for which to scan at the current scan location.
    /// - Returns: Upon return, if the receiver contains a string equivalent to `searchString` at the current scan location, contains a string equivalent to `searchString`.
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
    
    /// Scans for a `Double` value, returning a found value.
    /// - Parameter representation: Determines how scanner should read value.
    /// - Returns: Scanned `Double` value if it exists.
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
    
    /// Scans for a `Float` value, returning a found value.
    /// - Parameter representation: Determines how scanner should read value.
    /// - Returns: Scanned `Float` value if it exists.
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
    
    /// Scans for a `Int` value, returning a found value.
    /// - Parameter representation: Determines how scanner should read value.
    /// - Returns: Scanned `Int` value if it exists.
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
    
    /// Scans for a `Int32` value, returning a found value.
    /// - Parameter representation: Determines how scanner should read value.
    /// - Returns: Scanned `Int32` value if it exists.
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
    
    /// Scans for a `Int64` value, returning a found value.
    /// - Parameter representation: Determines how scanner should read value.
    /// - Returns: Scanned `Int64` value if it exists.
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
    
    /// Scans for a `UInt64` value, returning a found value.
    /// - Parameter representation: Determines how scanner should read value.
    /// - Returns: Scanned `UInt64` value if it exists.
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
        
    /// Skip next character.
    /// - Returns: True if scanner successfully skipped a character.
    @discardableResult
    public func skipCharacter() -> Bool {
        guard !isAtEnd else { return false }
        
        source.seekTo(1, origin: .current)
        
        return true
    }
        
    /// Skip next character if it exists in specified set.
    /// - Parameter set: Set to characters be skipped.
    /// - Returns: True if scanner successfully skipped a character.
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
        
    /// Skip characters until set contains them.
    /// - Parameter set: Set to skip characters.
    /// - Returns: True if scanner successfully skipped any characters.
    @discardableResult
    public func skipCharacters(from set: CharacterSet) -> Bool {
        scanCharacters(from: set) != nil
    }
            
    /// Skip specified string.
    /// - Parameter substring: String to skip.
    /// - Returns: True if scanner successfully skipped specified substring.
    @discardableResult
    public func skipString(_ substring: String) -> Bool {
        scanString(substring) != nil
    }
        
    /// Scans till find any characters stored in the set and skip it.
    /// Scanner doesn't change index if no characters found.
    /// - Parameter set: Set to scan up to first character and skip it.
    /// - Returns: True if scanner successfully skipped any characters.
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
    
    /// Scans till find specified substring and skips it.
    /// Scanner doesn't change index if no substring found.
    /// - Parameter substring: Substring to scan up and skip it.
    /// - Returns: True if scanner successfully skipped substring.
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
    
    /// Skip current character if `charactersToBeSkipped` contains the character.
    /// - Returns: True if character was skipped
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
