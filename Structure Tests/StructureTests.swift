//
//  StructureTests.swift
//  Structure
//
//  Created by Stephen Gerstacker on 12/20/15.
//  Copyright © 2015 Stephen H. Gerstacker. All rights reserved.
//

import XCTest

class StructureTests: XCTestCase {
    
    // MARK:  Set Up & Tear Down
    
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
        } catch let e {
            XCTFail("Structure creation should succeed: \(e)")
        }
    }
    
    func testCreationInFile() {
        let tempPath = "\(NSTemporaryDirectory())/test.db"
        
        do {
            let _ = try Structure(path: tempPath)
            try NSFileManager.defaultManager().removeItemAtPath(tempPath)
        } catch let e {
            XCTFail("Structure creation should succeed: \(e)")
        }
    }

    // MARK: - User Version Tests
    
    func testDefaultUserVersionIsZero() {
        let structure = try! Structure()
        let userVersion = structure.userVersion
        
        XCTAssertEqual(0, userVersion)
    }
    
    func testSettingUserVersionWorks() {
        let structure = try! Structure()
        let userVersion = Int(arc4random_uniform(255) + 1)
        
        structure.userVersion = userVersion
        
        let storedUserVersion = structure.userVersion
        
        XCTAssertEqual(userVersion, storedUserVersion)
    }
}
