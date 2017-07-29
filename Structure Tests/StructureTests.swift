//
//  StructureTests.swift
//  Structure
//
//  Created by Stephen Gerstacker on 12/20/15.
//  Copyright © 2017 Stephen H. Gerstacker. All rights reserved.
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
            try structure.execute(query: "FOO!")
            XCTFail("Execution was successful for an invalid query")
        } catch let e {
            XCTSuccess("Exection of an invalid query failed properly: \(e)")
        }
    }
    
    func testExecutingValidQuery() {
        do {
            try structure.execute(query: "CREATE TABLE foo (a INT)")
            XCTSuccess("Execution was successful for a valid query")
        } catch let e {
            XCTFail("Failed to execute a valid query: \(e)")
        }
    }
    
    func testExecutingInsideATransaction() {
        do {
            try structure.transaction { s in
                try s.execute(query: "CREATE TABLE foo (a INT)")
            }
            
            XCTSuccess("Execution inside a transaction was successful")
        } catch let e {
            XCTFail("Failed to execute query inside of a transaction: \(e)")
        }
    }
    
    // MARK: - Step Tests
    
    func testStepSuccessfully() {
        try! structure.execute(query: "CREATE TABLE foo (a INT)")
        try! structure.execute(query: "INSERT INTO foo (a) VALUES (1)")
        
        do {
            let statement = try structure.prepare(query: "SELECT a FROM foo")
            
            if let row = try structure.step(statement: statement) {
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
        try! structure.execute(query: "CREATE TABLE foo (a INT)")
        
        do {
            let statement = try structure.prepare(query: "SELECT a FROM foo")
            
            XCTAssertNil(try structure.step(statement: statement))
        } catch let e {
            XCTFail("Unknown failure stepping an empty query: \(e)")
        }
    }
    
    // MARK: - Migration Tests
    
    func testMigrationWorksInitially() {
        XCTAssertEqual(0, structure.userVersion)
        
        do {
            try structure.migrate(version: 1) { s in
                try s.execute(query: "CREATE TABLE foo (a INT)")
            }
        } catch let e {
            XCTFail("Migration should not have failed: \(e)")
        }
        
        XCTAssertEqual(1, structure.userVersion)
    }
    
    func testMigrationsWorkSerially() {
        XCTAssertEqual(0, structure.userVersion)
        
        do {
            try structure.migrate(version: 1) { s in
                try s.execute(query: "CREATE TABLE foo (a INT)")
            }
            
            try structure.migrate(version: 2) { s in
                try s.execute(query: "CREATE TABLE bar (a INT)")
            }
        } catch let e {
            XCTFail("Migration should not have failed: \(e)")
        }
        
        XCTAssertEqual(2, structure.userVersion)
    }
    
    func testMigrationFailsIfOutOfSequence() {
        XCTAssertEqual(0, structure.userVersion)
        
        do {
            try structure.migrate(version: 2) { s in
                try s.execute(query: "CREATE TABLE foo (a INT)")
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
            try structure.migrate(version: 1) { s in
                try s.execute(query: "CREATE TABLE foo (a INT)")
            }
            
            try structure.migrate(version: 1) { s in
                try s.execute(query: "INSERT INTO foo (a) VALUES (1)")
            }
        } catch let e {
            XCTFail("Migration should not have failed: \(e)")
        }
        
        XCTAssertEqual(1, structure.userVersion)
        
        let statement = try! structure.prepare(query: "SELECT COUNT(a) as count FROM foo")
        
        var count = -1
        try! structure.perform(statement: statement) { row in
            count = row["count"]
        }
        
        XCTAssertEqual(0, count)
    }
    
    // MARK: - Concurrency Tests
    
    func testMultipleModifications() {
        // Build a table with an integer value
        try! structure.migrate(version: 1) { s in
            try s.execute(query: "CREATE TABLE foo (id INTEGER PRIMARY KEY, value INTEGER)")
        }
        
        // Inject initial data
        try! structure.execute(query: "INSERT INTO foo (value) VALUES (0)")
        let id = structure.lastInsertedId
        
        // Build statements for fetch and update
        let fetchStatement = try! structure.prepare(query: "SELECT value FROM foo WHERE id = :id")
        let updateStatement = try! structure.prepare(query: "UPDATE foo SET value = :value WHERE id = :id")
        
        // Ensure the default value is set properly
        fetchStatement.bind(value: id, for: "id")
        
        guard let initialRow = try! structure.step(statement: fetchStatement) else {
            XCTFail("Failed to get initial value")
            return
        }
        
        XCTAssertEqual(initialRow["value"] as Int, 0)
        
        // Construct a large series of read / increment / write instructions
        let queue = DispatchQueue(label: "Test Queue", attributes: [ .concurrent ])
        let group = DispatchGroup()
        
        for _ in 0 ..< 1000 {
            queue.async(group: group) {
                self.structure.transaction { (structure) in
                    // Fetch
                    fetchStatement.reset()
                    fetchStatement.bind(value: id, for: "id")
                    
                    guard let row = try! structure.step(statement: fetchStatement) else {
                        XCTFail("Failed to get initial value")
                        return
                    }
                    
                    // Increment
                    let newValue: Int = row["value"] + 1
                    
                    // Update
                    updateStatement.reset()
                    updateStatement.bind(value: newValue, for: "value")
                    updateStatement.bind(value: id, for: "id")
                    
                    try! structure.perform(statement: updateStatement)
                }
            }
        }
        
        // Wait for everything to complete
        _ = group.wait(timeout: DispatchTime.distantFuture)
        
        // Ensure the value got incremented 100 times
        fetchStatement.reset()
        fetchStatement.bind(value: id, for: "id")
        
        guard let finalRow = try! structure.step(statement: fetchStatement) else {
            XCTFail("Failed to get final value")
            return
        }
        
        XCTAssertEqual(finalRow["value"] as Int, 1000)
    }
    
    // MARK: - Custom Function Tests
    
    func testUpperFunctionWithStandardString() {
        // Create a table that stores strings
        try! structure.migrate(version: 1) { s in
            try s.execute(query: "CREATE TABLE foo (id INTEGER PRIMARY KEY, value TEXT)")
        }
        
        // Insert some test data
        try! structure.execute(query: "INSERT INTO foo (value) VALUES ('Hello')")
        let id = structure.lastInsertedId
        
        // Fetch the data back out, with upper case values
        let fetchStatement = try! structure.prepare(query: "SELECT UPPER(value) AS value FROM foo WHERE id = :id")
        fetchStatement.bind(value: id, for: "id")
        
        guard let row = try! structure.step(statement: fetchStatement) else {
            XCTFail("Failed to get inserted data")
            return
        }
        
        guard let result: String = row["value"] else {
            XCTFail("Failed to get string value")
            return
        }
        
        XCTAssertEqual(result, "HELLO")
    }
    
    func testUpperFunctionWithComplexString() {
        // Create a table that stores strings
        try! structure.migrate(version: 1) { s in
            try s.execute(query: "CREATE TABLE foo (id INTEGER PRIMARY KEY, value TEXT)")
        }
        
        // Insert some test data
        try! structure.execute(query: "INSERT INTO foo (value) VALUES ('👋🏻 Hello 👋🏼')")
        let id = structure.lastInsertedId
        
        // Fetch the data back out, with upper case values
        let fetchStatement = try! structure.prepare(query: "SELECT UPPER(value) AS value FROM foo WHERE id = :id")
        fetchStatement.bind(value: id, for: "id")
        
        guard let row = try! structure.step(statement: fetchStatement) else {
            XCTFail("Failed to get inserted data")
            return
        }
        
        guard let result: String = row["value"] else {
            XCTFail("Failed to get string value")
            return
        }
        
        XCTAssertEqual(result, "👋🏻 HELLO 👋🏼")
    }
    
    func testUpperFunctionWithUnicodeString() {
        // Create a table that stores strings
        try! structure.migrate(version: 1) { s in
            try s.execute(query: "CREATE TABLE foo (id INTEGER PRIMARY KEY, value TEXT)")
        }
        
        // Insert some test data
        try! structure.execute(query: "INSERT INTO foo (value) VALUES ('exámple óóßChloë')")
        let id = structure.lastInsertedId
        
        // Fetch the data back out, with upper case values
        let fetchStatement = try! structure.prepare(query: "SELECT UPPER(value) AS value FROM foo WHERE id = :id")
        fetchStatement.bind(value: id, for: "id")
        
        guard let row = try! structure.step(statement: fetchStatement) else {
            XCTFail("Failed to get inserted data")
            return
        }
        
        guard let result: String = row["value"] else {
            XCTFail("Failed to get string value")
            return
        }
        
        XCTAssertEqual(result, "EXÁMPLE ÓÓSSCHLOË")
        
    }
}
