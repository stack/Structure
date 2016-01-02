//
//  StructureTests.swift
//  Structure
//
//  Created by Stephen Gerstacker on 12/20/15.
//  Copyright © 2015 Stephen H. Gerstacker. All rights reserved.
//

import XCTest

class StructureTests: XCTestCase {
    
    // MARK: - Set Up & Tear Down
    
    var structure: Structure!
    
    override func setUp() {
        super.setUp()
        structure = try! Structure()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    // MARK: - User Version Tests
    
    func testDefaultUserVersionIsZero() {
        let userVersion = structure.userVersion
        
        XCTAssertEqual(0, userVersion)
    }
    
    func testSettingUserVersionWorks() {
        let userVersion = Int(arc4random_uniform(255) + 1)
        
        structure.userVersion = userVersion
        
        let storedUserVersion = structure.userVersion
        
        XCTAssertEqual(userVersion, storedUserVersion)
    }
    
    // MARK: - Execution Tests
    
    func testExecutingInvalidQuery() {
        do {
            try structure.execute("FOO!")
            XCTFail("Execution was successful for an invalid query")
        } catch let e {
            XCTSuccess("Exection of an invalid query failed properly: \(e)")
        }
    }
    
    func testExecutingValidQuery() {
        do {
            try structure.execute("CREATE TABLE foo (a INT)")
            XCTSuccess("Execution was successful for a valid query")
        } catch let e {
            XCTFail("Failed to execute a valid query: \(e)")
        }
    }
}
