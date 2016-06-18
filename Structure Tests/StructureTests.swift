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
    
    // MARK: - Step Tests
    
    func testStepSuccessfully() {
        try! structure.execute("CREATE TABLE foo (a INT)")
        try! structure.execute("INSERT INTO foo (a) VALUES (1)")
        
        do {
            let statement = try structure.prepare("SELECT a FROM foo")
            
            defer {
                statement.finalize()
            }
            
            if let row = try structure.step(statement) {
                let a: Int = row["a"]
                XCTAssertEqual(1, a)
            } else {
                XCTFail("Failed to step a successful query")
            }
        } catch let e {
            XCTFail("Unknown failure stepping a successful query: \(e)")
        }
    }
    
    func testStepEmpty() {
        try! structure.execute("CREATE TABLE foo (a INT)")
        
        do {
            let statement = try structure.prepare("SELECT a FROM foo")
            
            defer {
                statement.finalize()
            }
            
            XCTAssertNil(try structure.step(statement))
        } catch let e {
            XCTFail("Unknown failure stepping an empty query: \(e)")
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
    
    // MARK: - Concurrency Tests
    
    func testMultipleModifications() {
        // Build a table with an integer value
        try! structure.migrate(1) { s in
            try s.execute("CREATE TABLE foo (id INTEGER PRIMARY KEY, value INTEGER)")
        }
        
        // Inject initial data
        try! structure.execute("INSERT INTO foo (value) VALUES (0)")
        let id = structure.lastInsertedId
        
        // Build statements for fetch and update
        let fetchStatement = try! structure.prepare("SELECT value FROM foo WHERE id = :id")
        let updateStatement = try! structure.prepare("UPDATE foo SET value = :value WHERE id = :id")
        
        // Ensure the default value is set properly
        fetchStatement.bind("id", value: id)
        
        guard let initialRow = try! structure.step(fetchStatement) else {
            XCTFail("Failed to get initial value")
            return
        }
        
        XCTAssertEqual(initialRow["value"] as Int, 0)
        
        // Construct a large series of read / increment / write instructions
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        let group = dispatch_group_create()
        
        for _ in 0 ..< 1000 {
            dispatch_group_async(group, queue) {
                self.structure.transaction { (structure) in
                    // Fetch
                    fetchStatement.reset()
                    fetchStatement.bind("id", value: id)
                    
                    guard let row = try! structure.step(fetchStatement) else {
                        XCTFail("Failed to get initial value")
                        return
                    }
                    
                    // Increment
                    let newValue: Int = row["value"] + 1
                    
                    // Update
                    updateStatement.reset()
                    updateStatement.bind("value", value: newValue)
                    updateStatement.bind("id", value: id)
                    
                    try! structure.perform(updateStatement)
                }
            }
        }
        
        // Wait for everything to complete
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
        
        // Ensure the value got incremented 100 times
        fetchStatement.reset()
        fetchStatement.bind("id", value: id)
        
        guard let finalRow = try! structure.step(fetchStatement) else {
            XCTFail("Failed to get final value")
            return
        }
        
        XCTAssertEqual(finalRow["value"] as Int, 1000)
        
        // Cleanup
        fetchStatement.finalize()
        updateStatement.finalize()
    }
}
