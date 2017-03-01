//
//  StatementTests.swift
//  Structure
//
//  Created by Stephen Gerstacker on 1/1/16.
//  Copyright © 2017 Stephen H. Gerstacker. All rights reserved.
//

import XCTest
@testable import Structure

class StatementTests: XCTestCase {

    // MARK: - Set Up & Tear Down
    
    var structure: Structure!
    
    override func setUp() {
        super.setUp()
        
        structure = try! Structure()
        try! structure.execute(query: "CREATE TABLE foo (a INTEGER PRIMARY KEY AUTOINCREMENT, b TEXT, c REAL, d INT, e BLOB)")
    }
    
    override func tearDown() {
        try! structure.close()
        structure = nil
        
        super.tearDown()
    }
    
    // MARK: - Bind Tests
    
    func testBindEmoji() {
        let insertStatement = try! structure.prepare(query: "INSERT INTO foo (b) VALUES (:b)")
        insertStatement.bind(value: "💩 Fletch 💩", for: "b")
        
        _ = try! structure.step(statement: insertStatement)
        
        let selectStatement = try! structure.prepare(query: "SELECT b FROM foo LIMIT 1")
        let row = try! structure.step(statement: selectStatement)
        
        let result: String = row!["b"]!
        XCTAssertEqual(result, "💩 Fletch 💩")
    }
    
    // MARK: - Prepare Tests
    
    func testPrepareInvalidStatement() {
        do {
            _ = try structure.prepare(query: "SELECT FOO BAR BAZ")
            XCTFail("Preparation of invalid query succeeded")
        } catch let e {
            XCTSuccess("Preparation of invalid query failed: \(e)")
        }
    }
    
    func testPrepareRequiresNamedParameters() {
        do {
            _ = try structure.prepare(query: "SELECT a FROM foo WHERE b = ?")
            XCTFail("Preparation of query with unnamed parameters succeeded")
        } catch let e {
            XCTSuccess("Preparation of query with unnamed parameters failed: \(e)")
        }
        
    }
    
    func testPrepareValidStatement() {
        do {
            let statement = try structure.prepare(query: "SELECT a, b, c FROM foo WHERE b IS :ONE OR b IS $TWO OR c IS @THREE")
            
            XCTAssertEqual(3, statement.bindParameters.count)
            XCTAssertEqual(1, statement.bindParameters["ONE"])
            XCTAssertEqual(2, statement.bindParameters["TWO"])
            XCTAssertEqual(3, statement.bindParameters["THREE"])
            
            XCTAssertEqual(3, statement.columns.count)
            XCTAssertEqual(0, statement.columns["a"])
            XCTAssertEqual(1, statement.columns["b"])
            XCTAssertEqual(2, statement.columns["c"])
        } catch let e {
            XCTFail("Preparation of valid query failed: \(e)")
        }
    }
    
    // MARK: - Read / Write Tests
    
    func testDeleteStatement() {
        do {
            // Insert a row
            let insertStatement = try structure.prepare(query: "INSERT INTO foo (b, c, d, e) VALUES (:B, :C, :D, :E)")
            
            insertStatement.bind(value: "foo", for: "B")
            insertStatement.bind(value: 42.1, for: "C")
            insertStatement.bind(value: 42, for: "D")
            
            let data = Data(bytes: UnsafePointer<UInt8>([ 0x41, 0x42, 0x43 ] as [UInt8]), count: 3)
            insertStatement.bind(value: data, for: "E")
            
            try structure.perform(statement: insertStatement)
            
            // Ensure we have 1 row
            let initialCount = countFoo()
            XCTAssertEqual(1, initialCount)
            
            // Delete all rows
            let deleteStatement = try structure.prepare(query: "DELETE FROM foo")
            
            try structure.perform(statement: deleteStatement)
            
            // Ensure we have 0 rows
            let deletedCount = countFoo()
            XCTAssertEqual(0, deletedCount)
        } catch let e {
            XCTFail("Failed testing delete statement: \(e)")
        }
    }
    
    func testInsertStatement() {
        do {
            // Ensure we have no rows
            let initialCount = countFoo()
            XCTAssertEqual(0, initialCount)
            
            // Insert a row
            let insertStatement = try structure.prepare(query: "INSERT INTO foo (b, c, d, e) VALUES (:B, :C, :D, :E)")
            
            insertStatement.bind(value: "foo", for: "B")
            insertStatement.bind(value: 42.1, for: "C")
            insertStatement.bind(value: 42, for: "D")
            
            let data = Data(bytes: UnsafePointer<UInt8>([ 0x41, 0x42, 0x43 ] as [UInt8]), count: 3)
            insertStatement.bind(value: data, for: "E")
            
            try structure.perform(statement: insertStatement)
            
            // Ensure we have 1 row
            let updatedCount = countFoo()
            XCTAssertEqual(1, updatedCount)
            
            // Get the data that was inserted
            let lastId = structure.lastInsertedId
            let selectStatement = try structure.prepare(query: "SELECT a, b, c, d, e FROM foo")
            
            try structure.perform(statement: selectStatement) { row in
                let aString: Int64 = row["a"]
                let bString: String? = row["b"]
                let cString: Double = row["c"]
                let dString: Int = row["d"]
                let eString: Data? = row["e"]
                
                XCTAssertEqual(lastId, aString)
                XCTAssertEqual("foo", bString)
                XCTAssertEqual(42.1, cString)
                XCTAssertEqual(42, dString)
                XCTAssertEqual(data, eString)
                
                let aInt: Int64 = row[0]
                let bInt: String? = row[1]
                let cInt: Double = row[2]
                let dInt: Int = row[3]
                let eInt: Data? = row[4]
                
                XCTAssertEqual(lastId, aInt)
                XCTAssertEqual("foo", bInt)
                XCTAssertEqual(42.1, cInt)
                XCTAssertEqual(42, dInt)
                XCTAssertEqual(data, eInt)
            }
        } catch let e {
            XCTFail("Failed testing insert statement: \(e)")
        }
    }
    
    func testInsertNull() {
        do {
            // Ensure we have no rows
            let initialCount = countFoo()
            XCTAssertEqual(0, initialCount)
            
            // Insert a row
            let insertStatement = try structure.prepare(query: "INSERT INTO foo (b, c, d, e) VALUES (:B, :C, :D, :E)")
            
            let nullString: String? = nil
            let nullDouble: Double? = nil
            let nullInt: Int? = nil
            let nullData: Data? = nil
            
            insertStatement.bind(value: nullString, for: "B")
            insertStatement.bind(value: nullDouble, for: "C")
            insertStatement.bind(value: nullInt, for: "D")
            insertStatement.bind(value: nullData, for: "E")
            
            try structure.perform(statement: insertStatement)
            
            // Ensure we have 1 row
            let updatedCount = countFoo()
            XCTAssertEqual(1, updatedCount)
            
            // Get the data that was inserted
            let lastId = structure.lastInsertedId
            let selectStatement = try structure.prepare(query: "SELECT a, b, c, d, e FROM foo")
            
            try structure.perform(statement: selectStatement) { row in
                let aString: Int64 = row["a"]
                let bString: String? = row["b"]
                let cString: Double = row["c"]
                let dString: Int = row["d"]
                let eString: Data? = row["e"]
                
                XCTAssertEqual(lastId, aString)
                XCTAssertNil(bString)
                XCTAssertEqual(0.0, cString)
                XCTAssertEqual(0, dString)
                XCTAssertNil(eString)
                
                let aInt: Int64 = row[0]
                let bInt: String? = row[1]
                let cInt: Double = row[2]
                let dInt: Int = row[3]
                let eInt: Data? = row[4]
                
                XCTAssertEqual(lastId, aInt)
                XCTAssertNil(bInt)
                XCTAssertEqual(0.0, cInt)
                XCTAssertEqual(0, dInt)
                XCTAssertNil(eInt)
            }
        } catch let e {
            XCTFail("Failed testing insert statement: \(e)")
        }
    }
    
    func testUpdateStatement() {
        do {
            // Insert a row
            let insertStatement = try structure.prepare(query: "INSERT INTO foo (b, c, d, e) VALUES (:B, :C, :D, :E)")
            
            insertStatement.bind(value: "foo", for: "B")
            insertStatement.bind(value: 42.1, for: "C")
            insertStatement.bind(value: 42, for: "D")
            
            let data = Data(bytes: UnsafePointer<UInt8>([ 0x41, 0x42, 0x43 ] as [UInt8]), count: 3)
            insertStatement.bind(value: data, for: "E")
            
            try structure.perform(statement: insertStatement)
        
            // Ensure we have 1 row
            let initialCount = countFoo()
            XCTAssertEqual(1, initialCount)
            
            // Get the data that was inserted
            let lastId = structure.lastInsertedId
            
            // Update the row
            let updateStatement = try structure.prepare(query: "UPDATE foo SET b = :B, c = :C, d = :D, e = :E where a = :A")
            
            updateStatement.bind(value: "bar", for: "B")
            updateStatement.bind(value: 1.1, for: "C")
            updateStatement.bind(value: 2, for: "D")
            updateStatement.bind(value: lastId, for: "A")
            
            let data2 = Data(bytes: UnsafePointer<UInt8>([ 0x44, 0x45, 0x46 ] as [UInt8]), count: 3)
            updateStatement.bind(value: data2, for: "E")
            
            try structure.perform(statement: updateStatement)
            
            // Ensure there is still one row
            let updatedCount = countFoo()
            XCTAssertEqual(1, updatedCount)
            
            // Ensure the updated values are set
            let selectStatement = try structure.prepare(query: "SELECT a, b, c, d, e FROM foo WHERE a = :A")
            
            selectStatement.bind(value: lastId, for: "A")
            
            try structure.perform(statement: selectStatement) { row in
                let aString: Int64 = row["a"]
                let bString: String? = row["b"]
                let cString: Double = row["c"]
                let dString: Int = row["d"]
                let eString: Data? = row["e"]
                
                XCTAssertEqual(lastId, aString)
                XCTAssertEqual("bar", bString)
                XCTAssertEqual(1.1, cString)
                XCTAssertEqual(2, dString)
                XCTAssertEqual(data2, eString)
                
                let aInt: Int64 = row[0]
                let bInt: String? = row[1]
                let cInt: Double = row[2]
                let dInt: Int = row[3]
                let eInt: Data? = row[4]
                
                XCTAssertEqual(lastId, aInt)
                XCTAssertEqual("bar", bInt)
                XCTAssertEqual(1.1, cInt)
                XCTAssertEqual(2, dInt)
                XCTAssertEqual(data2, eInt)
            }
        } catch let e {
            XCTFail("Failed testing update statement: \(e)")
        }
    }
    
    // MARK: - Transaction Tests
    
    func testSuccessfulTransaction() {
        do {
            // Ensure there are no rows
            let initialCount = countFoo()
            XCTAssertEqual(0, initialCount)
            
            // Insert a series of data in a transaction
            try structure.transaction { s in
                let insertStatement = try s.prepare(query: "INSERT INTO foo (b, c) VALUES (:B, :C)")
                
                insertStatement.bind(value: "foo", for: "B")
                insertStatement.bind(value: 42.1, for: "C")
                
                try s.perform(statement: insertStatement)
                
                insertStatement.reset()
                
                insertStatement.bind(value: "bar", for: "B")
                insertStatement.bind(value: 1.1, for: "C")
                
                try s.perform(statement: insertStatement)
            }
            
            // Ensure there are two rows
            let updatedCount = countFoo()
            XCTAssertEqual(2, updatedCount)
        } catch let e {
            XCTFail("Failed testing successful transaction: \(e)")
        }
    }
    
    func testFailedTransaction() {
        // Ensure there are no rows
        let initialCount = countFoo()
        XCTAssertEqual(0, initialCount)
        
        do {
            // Insert a some data, but fail
            try structure.transaction { s in
                let insertStatement = try s.prepare(query: "INSERT INTO foo (b, c) VALUES (:B, :C)")
                
                insertStatement.bind(value: "foo", for: "B")
                insertStatement.bind(value: 42.1, for: "C")
                
                try s.perform(statement: insertStatement)
                
                insertStatement.reset()
                
                insertStatement.bind(value: "bar", for: "B")
                insertStatement.bind(value: 1.1, for: "C")
                
                try s.perform(statement: insertStatement)
                
                throw StructureError.error("Forced Error")
            }
        } catch StructureError.error(let e) {
            XCTAssertEqual("Forced Error", e)
        } catch let e {
            XCTFail("Unknown error when forcing a bad transaction: \(e)")
        }
        
        // Ensure there are still no rows
        let finalCount = countFoo()
        XCTAssertEqual(0, finalCount)
    }
    
    // MARK: - Utilities
    
    private func countFoo() -> Int {
        let statement = try! structure.prepare(query: "SELECT COUNT(a) as count FROM foo")
        
        var count = -1
        try! structure.perform(statement: statement) { row in
            count = row["count"]
        }
        
        return count
    }
    
}
