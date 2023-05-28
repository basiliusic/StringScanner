//
//  File.swift
//  
//
//  Created by basiliusic on 28.05.2023.
//

import XCTest
@testable import StringScanner

final class StringRawSourceTests: XCTestCase {
    
    // MARK: - Properties
    
    let testText = "abcdefghijk"
    
    // MARK: - Tests
    
    func testSeekFromStart() {
        let source = StringRawSource(testText)
        
        source.seekTo(5, origin: .start)
        
        XCTAssertEqual(
            source.index,
            5,
            "Invalid index after seek from start"
        )
    }
    
    func testSeekFromCurrent() {
        let source = StringRawSource(testText)
        source.index = 5
        
        source.seekTo(-2, origin: .current)
        
        XCTAssertEqual(
            source.index,
            3,
            "Invalid index after seek from current"
        )
    }
    
    func testSeekFromEnd() {
        let source = StringRawSource(testText)
        
        source.seekTo(-5, origin: .end)
        
        XCTAssertEqual(
            source.index,
            testText.count - 5,
            "Invalid index after seek from end"
        )
    }
    
    func testSeekToOutOfLowerBound() {
        let source = StringRawSource(testText)
        
        source.seekTo(-20, origin: .start)
        
        XCTAssertEqual(
            source.index,
            0,
            "Invalid index after seek out of bounds"
        )
    }
    
    func testSeekToOutOfUpperBound() {
        let source = StringRawSource(testText)
        
        source.seekTo(20, origin: .end)
        
        XCTAssertEqual(
            source.index,
            (testText as NSString).length,
            "Invalid index after seek out of bounds"
        )
    }
    
    func testLength() {
        let source = StringRawSource(testText)
        
        XCTAssertEqual(
            source.length,
            (testText as NSString).length,
            "Invalid length"
        )
    }
    
    func testIndexAtStart() {
        let source = StringRawSource(testText)
        
        XCTAssertEqual(
            source.index,
            0,
            "Invalid index at start"
        )
    }
    
    func testReadScalarValue() {
        let source = StringRawSource(testText)
        
        let scalar = source.readScalar()
        
        XCTAssertEqual(
            scalar,
            testText.unicodeScalars.first!,
            "Read scalar is invalid"
        )
    }
    
    func testReadScalarIndex() {
        let source = StringRawSource(testText)
        
        _ = source.readScalar()
        
        XCTAssertEqual(
            source.index,
            1,
            "Invalid index after read scalar"
        )
    }
    
    func testReadCharacterValue() {
        let source = StringRawSource(testText)
        
        let character = source.readCharacter()
        
        XCTAssertEqual(
            character,
            testText.first!,
            "Read character is invalid"
        )
    }
    
    func testReadCharacterIndex() {
        let source = StringRawSource(testText)
        
        _ = source.readCharacter()
        
        XCTAssertEqual(
            source.index,
            1,
            "Invalid index after read character"
        )
    }
    
    func testReadStringValue() {
        let source = StringRawSource(testText)
        let length = 4
        
        let string = source.read(4) as String
        let original = testText[testText.startIndex..<testText.index(testText.startIndex, offsetBy: length)]
        
        XCTAssertEqual(
            string,
            String(original),
            "Read text is invalid"
        )
    }
    
    func testReadStringIndex() {
        let source = StringRawSource(testText)
        let length = 4
        
        _ = source.read(4) as String
        
        XCTAssertEqual(
            source.index,
            length,
            "Invalid index after read text"
        )
    }
    
}
