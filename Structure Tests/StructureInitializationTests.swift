//
//  StructureInitializationTests.swift
//  Structure
//
//  Created by Stephen Gerstacker on 1/1/16.
//  Copyright © 2018 Stephen H. Gerstacker. All rights reserved.
//

import XCTest

class StructureInitializationTests: XCTestCase {

    // MARK: - Set Up & Tear Down
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testCreationInMemory() {
        do {
            let _ = try Structure()
            XCTAssertTrue(true, "Structure should be created successully")
        } catch {
            XCTFail("Structure creation should succeed: \(error)")
        }
    }
    
    func testCreationInFile() {
        let tempPath = "\(NSTemporaryDirectory())/test.db"
        
        do {
            let _ = try Structure(path: tempPath)
            try FileManager.default.removeItem(atPath: tempPath)
        } catch {
            XCTFail("Structure creation should succeed: \(error)")
        }
    }
}
