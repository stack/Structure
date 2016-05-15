//
//  StructureTests.swift
//  Structure
//
//  Created by Stephen Gerstacker on 12/20/15.
//  Copyright © 2016 Stephen H. Gerstacker. All rights reserved.
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
        try! structure.close()
        structure = nil
        
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
    
    func testExecutingInsideATransaction() {
        do {
            try structure.transaction { s in
                try s.execute("CREATE TABLE foo (a INT)")
            }
            
            XCTSuccess("Execution inside a transaction was successful")
        } catch let e {
            XCTFail("Failed to execute query inside of a transaction: \(e)")
        }
    }
    
    // MARK: - Migration Tests
    
    func testMigrationWorksInitially() {
        XCTAssertEqual(0, structure.userVersion)
        
        do {
            try structure.migrate(1) { s in
                try s.execute("CREATE TABLE foo (a INT)")
            }
        } catch let e {
            XCTFail("Migration should not have failed: \(e)")
        }
        
        XCTAssertEqual(1, structure.userVersion)
    }
    
    func testMigrationsWorkSerially() {
        XCTAssertEqual(0, structure.userVersion)
        
        do {
            try structure.migrate(1) { s in
                try s.execute("CREATE TABLE foo (a INT)")
            }
            
            try structure.migrate(2) { s in
                try s.execute("CREATE TABLE bar (a INT)")
            }
        } catch let e {
            XCTFail("Migration should not have failed: \(e)")
        }
        
        XCTAssertEqual(2, structure.userVersion)
    }
    
    func testMigrationFailsIfOutOfSequence() {
        XCTAssertEqual(0, structure.userVersion)
        
        do {
            try structure.migrate(2) { s in
                try s.execute("CREATE TABLE foo (a INT)")
            }
            XCTFail("Migration should not have succeeded")
        } catch let e {
            XCTSuccess("Migration failed properly: \(e)")
        }
        
        XCTAssertEqual(0, structure.userVersion)
    }
    
    func testMigrationSkipsIfDone() {
        XCTAssertEqual(0, structure.userVersion)
        
        do {
            try structure.migrate(1) { s in
                try s.execute("CREATE TABLE foo (a INT)")
            }
            
            try structure.migrate(1) { s in
                try s.execute("INSERT INTO foo (a) VALUES (1)")
            }
        } catch let e {
            XCTFail("Migration should not have failed: \(e)")
        }
        
        XCTAssertEqual(1, structure.userVersion)
        
        let statement = try! structure.prepare("SELECT COUNT(a) as count FROM foo")
        
        defer {
            statement.finalize()
        }
        
        var count = -1
        try! structure.perform(statement) { row in
            count = row["count"]
        }
        
        XCTAssertEqual(0, count)
    }
}
