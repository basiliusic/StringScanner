import XCTest
@testable import StringScanner

final class StringScannerTests: XCTestCase {
    
    // MARK: - Properties
    
    let testText: String = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
    
    // MARK: - Life cycle
    
    func testSubscriptCharacterValue() {
        let scanner = StringScanner(string: testText)
        
        let character = scanner[4]
        
        XCTAssertEqual(
            character,
            Character("m"),
            "Invalid character"
        )
    }
    
    func testSubscriptCharacterIndex() {
        let scanner = StringScanner(string: testText)
        let offset = 20
        scanner.seek(to: offset)
        
        _ = scanner[4]
        
        XCTAssertEqual(
            scanner.index,
            offset,
            "Invalid index after get random character"
        )
    }
    
    func testSubscriptStringValue() {
        let scanner = StringScanner(string: testText)
        
        let substring = scanner[4..<20]
        
        XCTAssertEqual(
            substring,
            (testText as NSString).substring(with: .init(location: 4, length: 20 - 4)),
            "Invalid substring"
        )
    }
    
    func testSubscriptStringIndex() {
        let scanner = StringScanner(string: testText)
        let offset = 20
        scanner.seek(to: offset)
        
        _ = scanner[4..<20]
        
        XCTAssertEqual(
            scanner.index,
            offset,
            "Invalid index after get random substring"
        )
    }
    
    func testSkipIfNeeded() {
        let scanner = StringScanner(string: testText)
        scanner.charactersToBeSkipped = .whitespaces
        scanner.seek(to: 5)
        
        _ = scanner.skipIfNeeded()
        
        XCTAssertEqual(
            scanner.index,
            6,
            "Scanner has to skip characters from skip set"
        )
    }
    
    func testSkipIfNeededNot() {
        let scanner = StringScanner(string: testText)
        scanner.charactersToBeSkipped = .whitespaces
        scanner.seek(to: 4)
        
        _ = scanner.skipIfNeeded()
        
        XCTAssertEqual(
            scanner.index,
            4,
            "Scanner has to skip characters from skip set"
        )
    }
    
    func testScanUpToCharactersReached() {
        let scanner = StringScanner(string: testText)
        scanner.charactersToBeSkipped = nil
        
        let result = scanner.scanUpToCharacters(from: .whitespaces)
        
        XCTAssertEqual(
            result.string,
            "Lorem",
            "Invalid scanned string"
        )
        
        XCTAssertTrue(result.reached)
        
        XCTAssertEqual(
            scanner.index,
            5
        )
    }
    
    func testScanUpToCharactersNotReached() {
        let scanner = StringScanner(string: testText)
        scanner.charactersToBeSkipped = nil
        
        let result = scanner.scanUpToCharacters(from: .init(charactersIn: "%"))
        
        XCTAssertEqual(
            result.string,
            testText,
            "Invalid scanned string"
        )
        
        XCTAssertTrue(!result.reached)
        
        XCTAssertEqual(
            scanner.index,
            scanner.length
        )
        
        XCTAssertTrue(scanner.isAtEnd)
    }
    
    func testScanUpToStringReached() {
        let scanner = StringScanner(string: testText)
        scanner.charactersToBeSkipped = nil
        
        let result = scanner.scanUpToString("dolor")
        
        XCTAssertEqual(
            result.string,
            "Lorem ipsum ",
            "Invalid scanned string"
        )
        
        XCTAssertTrue(result.reached)
        
        XCTAssertEqual(
            scanner.index,
            ("Lorem ipsum " as NSString).length
        )
    }
    
    func testScanUpToStringNotReached() {
        let scanner = StringScanner(string: testText)
        scanner.charactersToBeSkipped = nil
        
        let result = scanner.scanUpToString("agsd")
        
        XCTAssertEqual(
            result.string,
            testText,
            "Invalid scanned string"
        )
        
        XCTAssertTrue(!result.reached)
        
        XCTAssertEqual(
            scanner.index,
            scanner.length
        )
        
        XCTAssertTrue(scanner.isAtEnd)
    }
    
    func testScanCharacter() {
        let scanner = StringScanner(string: testText)
        
        let character = scanner.scanCharacter()
        
        XCTAssertEqual(
            character,
            .init("L"),
            "Invalid character"
        )
        
        XCTAssertEqual(
            scanner.index,
            1,
            "Invalid index after scan character"
        )
    }
    
    func testScanCharacterAtEnd() {
        let scanner = StringScanner(string: testText)
        scanner.seek(to: scanner.length)
        
        let character = scanner.scanCharacter()
        
        XCTAssertNil(character)
        
        XCTAssertTrue(scanner.isAtEnd)
    }
    
    func testScanCharactersSuccess() {
        let scanner = StringScanner(string: testText)
        
        let string = scanner.scanCharacters(from: .init(charactersIn: "Lo"))
        
        XCTAssertEqual(
            string,
            "Lo",
            "Invalid scanned characters"
        )
        
        XCTAssertEqual(
            scanner.index,
            2,
            "Invalid index after scanning characters"
        )
    }
    
    func testScanCharactersFail() {
        let scanner = StringScanner(string: testText)
        
        let string = scanner.scanCharacters(from: .init(charactersIn: "a"))
        
        XCTAssertNil(string)
        
        XCTAssertEqual(
            scanner.index,
            0,
            "Invalid index after scanning characters"
        )
    }
    
    func testScanStringSuccess() {
        let scanner = StringScanner(string: testText)
        let searchString = "Lorem"
        
        let string = scanner.scanCharacters(from: .init(charactersIn: searchString))
        
        XCTAssertEqual(
            string,
            searchString,
            "Invalid scanned string"
        )
        
        XCTAssertEqual(
            scanner.index,
            (searchString as NSString).length,
            "Invalid index after scanning string"
        )
    }
    
    func testScanStringFail() {
        let scanner = StringScanner(string: testText)
        let searchString = "as"
        
        let string = scanner.scanCharacters(from: .init(charactersIn: searchString))
        
        XCTAssertNil(string)
        
        XCTAssertEqual(
            scanner.index,
            0,
            "Invalid index after scanning string"
        )
    }
    
    func testSkipAnyCharacterSuccess() {
        let scanner = StringScanner(string: testText)
        
        let skip = scanner.skipCharacter()
        
        XCTAssertTrue(skip)
        
        XCTAssertEqual(
            scanner.index,
            1,
            "Invalid index after skip character"
        )
    }
    
    func testSkipAnyCharacterFail() {
        let scanner = StringScanner(string: testText)
        scanner.seek(to: scanner.length)
        
        let skip = scanner.skipCharacter()
        
        XCTAssertFalse(skip)
        
        XCTAssertTrue(scanner.isAtEnd)
    }
    
    func testSkipCharacterSuccess() {
        let scanner = StringScanner(string: testText)
        let skipString = "L"
        
        let skip = scanner.skipCharacter(from: .init(charactersIn: skipString))
        
        XCTAssertTrue(skip)
        
        XCTAssertEqual(
            scanner.index,
            1,
            "Invalid index after skip character"
        )
    }
    
    func testSkipCharacterFail() {
        let scanner = StringScanner(string: testText)
        let skipString = "z"
        
        let skip = scanner.skipCharacter(from: .init(charactersIn: skipString))
        
        XCTAssertFalse(skip)
        
        XCTAssertEqual(
            scanner.index,
            0,
            "Invalid index after skip character"
        )
    }
    
    func testSkipCharactersSuccess() {
        let scanner = StringScanner(string: testText)
        let skipString = "Lo"
        
        let skip = scanner.skipCharacters(from: .init(charactersIn: skipString))
        
        XCTAssertTrue(skip)
        
        XCTAssertEqual(
            scanner.index,
            2,
            "Invalid index after skip characters"
        )
    }
    
    func testSkipCharactersFail() {
        let scanner = StringScanner(string: testText)
        let skipString = "zda"
        
        let skip = scanner.skipCharacters(from: .init(charactersIn: skipString))
        
        XCTAssertFalse(skip)
        
        XCTAssertEqual(
            scanner.index,
            0,
            "Invalid index after skip characters"
        )
    }
    
    func testSkipStringSuccess() {
        let scanner = StringScanner(string: testText)
        let skipString = "Lorem"
        
        let skip = scanner.skipString(skipString)
        
        XCTAssertTrue(skip)
        
        XCTAssertEqual(
            scanner.index,
            (skipString as NSString).length,
            "Invalid index after skip string"
        )
    }
    
    func testSkipStringFail() {
        let scanner = StringScanner(string: testText)
        let skipString = "test"
        
        let skip = scanner.skipString(skipString)
        
        XCTAssertFalse(skip)
        
        XCTAssertEqual(
            scanner.index,
            0,
            "Invalid index after skip string"
        )
    }
    
    func testSkipUpCharactersSuccess() {
        let scanner = StringScanner(string: testText)
        scanner.charactersToBeSkipped = nil
        
        let skip = scanner.skipUp(from: .whitespaces)
        
        XCTAssertTrue(skip)
        
        XCTAssertEqual(
            scanner.index,
            6,
            "Invalid index after skip up characters"
        )
    }
    
    func testSkipUpCharactersFail() {
        let scanner = StringScanner(string: testText)
        scanner.charactersToBeSkipped = nil
        
        let skip = scanner.skipUp(from: .newlines)
        
        XCTAssertFalse(skip)
        
        XCTAssertEqual(
            scanner.index,
            0,
            "Invalid index after skip up characters"
        )
    }
    
    func testSkipUpStringSuccess() {
        let scanner = StringScanner(string: testText)
        
        let skip = scanner.skipUp(to: "ipsum")
        
        XCTAssertTrue(skip)
        
        XCTAssertEqual(
            scanner.index,
            ("Lorem ipsum" as NSString).length,
            "Invalid index after skip up characters"
        )
    }
    
    func testSkipUpStringFail() {
        let scanner = StringScanner(string: testText)
        
        let skip = scanner.skipUp(to: "gask")
        
        XCTAssertFalse(skip)
        
        XCTAssertEqual(
            scanner.index,
            0,
            "Invalid index after skip up characters"
        )
    }
    
}
